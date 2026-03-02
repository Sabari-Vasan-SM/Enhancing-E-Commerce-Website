"""
Cart, Wishlist, and Order API routes.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas import (
    CartItemCreate, CartItemUpdate, CartItemResponse,
    WishlistItemCreate, WishlistItemResponse,
    OrderCreate, OrderFromCartCreate, OrderResponse,
    ProductResponse,
)
from app.services.order_service import (
    get_cart, add_to_cart, update_cart_item, remove_from_cart,
    get_wishlist, add_to_wishlist, remove_from_wishlist,
    create_order, get_user_orders, get_order_by_id, create_order_from_cart,
)

router = APIRouter(tags=["Orders & Cart"])


# ==================== CART ====================

@router.get("/cart", response_model=list[CartItemResponse])
async def list_cart(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user's cart."""
    items = await get_cart(current_user.id, db)
    return [CartItemResponse(
        id=i.id,
        product_id=i.product_id,
        quantity=i.quantity,
        product=ProductResponse.model_validate(i.product),
        added_at=i.added_at,
    ) for i in items]


@router.post("/cart", response_model=dict)
async def cart_add(
    data: CartItemCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add item to cart."""
    item = await add_to_cart(current_user.id, data, db)
    return {"status": "added", "cart_item_id": item.id}


@router.put("/cart/{item_id}", response_model=dict)
async def cart_update(
    item_id: int,
    data: CartItemUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update cart item quantity."""
    await update_cart_item(current_user.id, item_id, data, db)
    return {"status": "updated"}


@router.delete("/cart/{item_id}", response_model=dict)
async def cart_remove(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove item from cart."""
    await remove_from_cart(current_user.id, item_id, db)
    return {"status": "removed"}


# ==================== WISHLIST ====================

@router.get("/wishlist", response_model=list[WishlistItemResponse])
async def list_wishlist(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user's wishlist."""
    items = await get_wishlist(current_user.id, db)
    return [WishlistItemResponse(
        id=i.id,
        product_id=i.product_id,
        product=ProductResponse.model_validate(i.product),
        added_at=i.added_at,
    ) for i in items]


@router.post("/wishlist", response_model=dict)
async def wishlist_add(
    data: WishlistItemCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add item to wishlist."""
    item = await add_to_wishlist(current_user.id, data, db)
    return {"status": "added", "wishlist_item_id": item.id}


@router.delete("/wishlist/{item_id}", response_model=dict)
async def wishlist_remove(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove item from wishlist."""
    await remove_from_wishlist(current_user.id, item_id, db)
    return {"status": "removed"}


# ==================== ORDERS ====================

@router.post("/orders", response_model=OrderResponse)
async def place_order(
    data: OrderCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Place a new order."""
    order = await create_order(current_user.id, data, db)
    return OrderResponse.model_validate(order)


@router.post("/orders/from-cart", response_model=OrderResponse)
async def place_order_from_cart(
    data: OrderFromCartCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Place an order using all items in the user's cart."""
    order = await create_order_from_cart(current_user.id, data, db)
    return OrderResponse.model_validate(order)


@router.get("/orders", response_model=list[OrderResponse])
async def list_orders(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user's orders."""
    orders = await get_user_orders(current_user.id, db)
    return [OrderResponse.model_validate(o) for o in orders]


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a specific order."""
    order = await get_order_by_id(current_user.id, order_id, db)
    return OrderResponse.model_validate(order)
