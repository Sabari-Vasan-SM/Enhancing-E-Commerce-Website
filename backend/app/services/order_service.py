"""
Order service - handles cart, wishlist, and order operations.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import List
from datetime import datetime, timezone
import uuid

from app.models.order import CartItem, WishlistItem, Order, OrderItem, OrderStatus
from app.models.product import Product
from app.models.behavior import UserBehavior, BehaviorType
from app.schemas import (
    CartItemCreate, CartItemUpdate, OrderCreate, OrderFromCartCreate,
    CartItemResponse, OrderResponse, WishlistItemCreate,
)
from app.classification import classify_and_update_user
from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)


# ==================== CART ====================

async def get_cart(user_id: int, db: AsyncSession) -> List[CartItem]:
    """Get all cart items for a user."""
    result = await db.execute(
        select(CartItem)
        .options(selectinload(CartItem.product))
        .where(CartItem.user_id == user_id)
        .order_by(CartItem.added_at.desc())
    )
    return result.scalars().all()


async def add_to_cart(user_id: int, data: CartItemCreate, db: AsyncSession) -> CartItem:
    """Add a product to cart."""
    # Check product exists and is active
    product = await db.execute(select(Product).where(Product.id == data.product_id))
    product = product.scalar_one_or_none()
    if not product or not product.is_active:
        raise HTTPException(status_code=404, detail="Product not found")

    # Check if already in cart
    existing = await db.execute(
        select(CartItem).where(
            and_(CartItem.user_id == user_id, CartItem.product_id == data.product_id)
        )
    )
    existing_item = existing.scalar_one_or_none()

    if existing_item:
        existing_item.quantity += data.quantity
        existing_item.updated_at = datetime.now(timezone.utc)
        cart_item = existing_item
    else:
        cart_item = CartItem(
            user_id=user_id,
            product_id=data.product_id,
            quantity=data.quantity,
        )
        db.add(cart_item)

    # Track behavior
    behavior = UserBehavior(
        user_id=user_id,
        behavior_type=BehaviorType.ADD_TO_CART,
        product_id=data.product_id,
    )
    db.add(behavior)
    await db.flush()

    return cart_item


async def update_cart_item(
    user_id: int, item_id: int, data: CartItemUpdate, db: AsyncSession
) -> CartItem:
    """Update cart item quantity."""
    result = await db.execute(
        select(CartItem).where(
            and_(CartItem.id == item_id, CartItem.user_id == user_id)
        )
    )
    cart_item = result.scalar_one_or_none()
    if not cart_item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    cart_item.quantity = data.quantity
    await db.flush()
    return cart_item


async def remove_from_cart(user_id: int, item_id: int, db: AsyncSession) -> bool:
    """Remove an item from cart."""
    result = await db.execute(
        select(CartItem).where(
            and_(CartItem.id == item_id, CartItem.user_id == user_id)
        )
    )
    cart_item = result.scalar_one_or_none()
    if not cart_item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    # Track behavior
    behavior = UserBehavior(
        user_id=user_id,
        behavior_type=BehaviorType.REMOVE_FROM_CART,
        product_id=cart_item.product_id,
    )
    db.add(behavior)

    await db.delete(cart_item)
    await db.flush()
    return True


# ==================== WISHLIST ====================

async def get_wishlist(user_id: int, db: AsyncSession) -> List[WishlistItem]:
    """Get all wishlist items for a user."""
    result = await db.execute(
        select(WishlistItem)
        .options(selectinload(WishlistItem.product))
        .where(WishlistItem.user_id == user_id)
        .order_by(WishlistItem.added_at.desc())
    )
    return result.scalars().all()


async def add_to_wishlist(user_id: int, data: WishlistItemCreate, db: AsyncSession) -> WishlistItem:
    """Add a product to wishlist."""
    # Check if already in wishlist
    existing = await db.execute(
        select(WishlistItem).where(
            and_(WishlistItem.user_id == user_id, WishlistItem.product_id == data.product_id)
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Product already in wishlist")

    item = WishlistItem(user_id=user_id, product_id=data.product_id)
    db.add(item)

    # Track behavior
    behavior = UserBehavior(
        user_id=user_id,
        behavior_type=BehaviorType.ADD_TO_WISHLIST,
        product_id=data.product_id,
    )
    db.add(behavior)
    await db.flush()

    return item


async def remove_from_wishlist(user_id: int, item_id: int, db: AsyncSession) -> bool:
    """Remove an item from wishlist."""
    result = await db.execute(
        select(WishlistItem).where(
            and_(WishlistItem.id == item_id, WishlistItem.user_id == user_id)
        )
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Wishlist item not found")

    behavior = UserBehavior(
        user_id=user_id,
        behavior_type=BehaviorType.REMOVE_FROM_WISHLIST,
        product_id=item.product_id,
    )
    db.add(behavior)

    await db.delete(item)
    await db.flush()
    return True


# ==================== ORDERS ====================

async def create_order(user_id: int, data: OrderCreate, db: AsyncSession) -> Order:
    """Create a new order from order items."""
    total_amount = 0.0
    discount_amount = 0.0
    order_items = []
    has_sale_item = False

    for item_data in data.items:
        result = await db.execute(
            select(Product).where(Product.id == item_data.product_id)
        )
        product = result.scalar_one_or_none()
        if not product or not product.is_active:
            raise HTTPException(
                status_code=400,
                detail=f"Product {item_data.product_id} not found or unavailable"
            )

        if product.stock_quantity < item_data.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient stock for {product.name}"
            )

        item_price = product.price * item_data.quantity
        item_discount = 0.0
        if product.original_price and product.original_price > product.price:
            item_discount = (product.original_price - product.price) * item_data.quantity

        if product.is_on_sale or product.discount_percentage > 0:
            has_sale_item = True

        total_amount += item_price
        discount_amount += item_discount

        order_items.append({
            "product_id": product.id,
            "quantity": item_data.quantity,
            "price_at_purchase": product.price,
            "discount_at_purchase": item_discount / item_data.quantity if item_data.quantity > 0 else 0,
            "total_price": item_price,
        })

        # Update stock
        product.stock_quantity -= item_data.quantity
        product.order_count = (product.order_count or 0) + item_data.quantity

    # Calculate final amount
    tax_amount = total_amount * 0.18  # 18% GST
    shipping_amount = 0.0 if total_amount > 500 else 50.0
    final_amount = total_amount + tax_amount + shipping_amount - discount_amount

    # Create order
    order = Order(
        user_id=user_id,
        order_number=f"ORD-{uuid.uuid4().hex[:12].upper()}",
        status=OrderStatus.PENDING,
        total_amount=total_amount,
        discount_amount=discount_amount,
        tax_amount=round(tax_amount, 2),
        shipping_amount=shipping_amount,
        final_amount=round(final_amount, 2),
        payment_method=data.payment_method,
        shipping_address=data.shipping_address,
        coupon_code=data.coupon_code,
        is_sale_purchase=has_sale_item,
    )
    db.add(order)
    await db.flush()

    # Create order items
    for item in order_items:
        oi = OrderItem(order_id=order.id, **item)
        db.add(oi)

        # Track purchase behavior
        behavior = UserBehavior(
            user_id=user_id,
            behavior_type=BehaviorType.PURCHASE,
            product_id=item["product_id"],
            metadata_json={"quantity": item["quantity"], "price": item["price_at_purchase"]},
        )
        db.add(behavior)

    await db.flush()

    # Clear cart after order
    cart_items = await db.execute(
        select(CartItem).where(CartItem.user_id == user_id)
    )
    for ci in cart_items.scalars().all():
        await db.delete(ci)

    # Trigger classification update
    try:
        await classify_and_update_user(user_id, db, force=True)
    except Exception as e:
        logger.warning(f"Classification after order failed: {e}")

    return order


async def get_user_orders(user_id: int, db: AsyncSession) -> List[Order]:
    """Get all orders for a user."""
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product)
        )
        .where(Order.user_id == user_id)
        .order_by(Order.created_at.desc())
    )
    return result.scalars().all()


async def get_order_by_id(user_id: int, order_id: int, db: AsyncSession) -> Order:
    """Get a specific order by ID."""
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product)
        )
        .where(and_(Order.id == order_id, Order.user_id == user_id))
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


async def create_order_from_cart(user_id: int, data: OrderFromCartCreate, db: AsyncSession) -> Order:
    """Create an order using all items currently in the user's cart."""
    cart_items = await get_cart(user_id, db)
    if not cart_items:
        raise HTTPException(status_code=400, detail="Cart is empty")

    from app.schemas import OrderItemCreate, OrderCreate
    items = [OrderItemCreate(product_id=ci.product_id, quantity=ci.quantity) for ci in cart_items]
    order_data = OrderCreate(
        items=items,
        shipping_address=data.shipping_address,
        payment_method=data.payment_method,
        coupon_code=data.coupon_code,
    )
    return await create_order(user_id, order_data, db)
