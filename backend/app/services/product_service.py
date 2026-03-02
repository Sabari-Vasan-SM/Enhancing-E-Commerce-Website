"""
Product service - handles product queries with personalization.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc, asc
from typing import Optional, List
from app.models.product import Product, Category, Brand
from app.models.user import User, UserTypeEnum
from app.models.behavior import ProductView, UserBehavior, BehaviorType
from app.models.order import OrderItem, Order
from app.models.analytics import UserAnalytics
from app.schemas import ProductListResponse, ProductResponse, RecommendationResponse


async def get_products(
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
    category_id: Optional[int] = None,
    brand_id: Optional[int] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    search: Optional[str] = None,
    is_on_sale: Optional[bool] = None,
    is_featured: Optional[bool] = None,
    is_premium: Optional[bool] = None,
    sort_by: str = "created_at",
    sort_order: str = "desc",
) -> ProductListResponse:
    """Get paginated products with filters."""
    query = select(Product).where(Product.is_active == True)

    # Apply filters
    if category_id:
        query = query.where(Product.category_id == category_id)
    if brand_id:
        query = query.where(Product.brand_id == brand_id)
    if min_price is not None:
        query = query.where(Product.price >= min_price)
    if max_price is not None:
        query = query.where(Product.price <= max_price)
    if search:
        query = query.where(
            or_(
                Product.name.ilike(f"%{search}%"),
                Product.description.ilike(f"%{search}%"),
                Product.tags.cast(str).ilike(f"%{search}%"),
            )
        )
    if is_on_sale is not None:
        query = query.where(Product.is_on_sale == is_on_sale)
    if is_featured is not None:
        query = query.where(Product.is_featured == is_featured)
    if is_premium is not None:
        query = query.where(Product.is_premium == is_premium)

    # Count total
    count_query = select(func.count()).select_from(query.subquery())
    total = await db.scalar(count_query) or 0

    # Sort
    sort_column = getattr(Product, sort_by, Product.created_at)
    if sort_order == "asc":
        query = query.order_by(asc(sort_column))
    else:
        query = query.order_by(desc(sort_column))

    # Paginate
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)

    result = await db.execute(query)
    products = result.scalars().all()

    return ProductListResponse(
        products=[ProductResponse.model_validate(p) for p in products],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(offset + page_size) < total,
    )


async def get_personalized_products(
    user_id: int, db: AsyncSession, page: int = 1, page_size: int = 20
) -> RecommendationResponse:
    """
    Get products personalized for the user based on their classification type.
    Each user type gets a different product selection strategy.
    """
    # Get user
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise ValueError("User not found")

    user_type = user.user_type
    query = select(Product).where(Product.is_active == True)
    reason = ""
    personalization = {}

    if user_type == UserTypeEnum.EXPLORATION:
        # Show diverse trending products across categories
        query = query.order_by(desc(Product.view_count), desc(Product.created_at))
        reason = "Trending and diverse products across categories for exploration"
        personalization = {"strategy": "trending_diverse", "layout": "category_grid"}

    elif user_type == UserTypeEnum.BRAND:
        # Get user's favorite brands
        analytics_result = await db.execute(
            select(UserAnalytics).where(UserAnalytics.user_id == user_id)
        )
        analytics = analytics_result.scalar_one_or_none()

        if analytics and analytics.most_viewed_brand_id:
            # Prioritize favorite brand
            query = query.order_by(
                desc(Product.brand_id == analytics.most_viewed_brand_id),
                desc(Product.avg_rating),
            )
            personalization = {
                "strategy": "brand_focused",
                "featured_brand_id": analytics.most_viewed_brand_id,
                "layout": "brand_showcase",
            }
        else:
            query = query.order_by(desc(Product.avg_rating))
            personalization = {"strategy": "top_rated", "layout": "brand_showcase"}
        reason = "Products from your favorite brands"

    elif user_type == UserTypeEnum.PRICE:
        # Show cheapest products first, highlight discounts
        query = query.order_by(asc(Product.price))
        reason = "Best value products sorted by price"
        personalization = {
            "strategy": "price_ascending",
            "highlight_discounts": True,
            "layout": "price_comparison",
        }

    elif user_type == UserTypeEnum.INTERACTION:
        # Show products similar to viewed, with high engagement metrics
        viewed_categories = await db.execute(
            select(func.distinct(Product.category_id))
            .join(ProductView, ProductView.product_id == Product.id)
            .where(ProductView.user_id == user_id)
            .limit(5)
        )
        cat_ids = [r[0] for r in viewed_categories.all()]

        if cat_ids:
            query = query.where(Product.category_id.in_(cat_ids))

        query = query.order_by(desc(Product.view_count), desc(Product.avg_rating))
        reason = "Products based on your browsing activity"
        personalization = {
            "strategy": "activity_based",
            "categories": cat_ids,
            "layout": "infinite_scroll",
        }

    elif user_type == UserTypeEnum.OFFER:
        # Show products on sale, with highest discounts first
        query = query.where(
            or_(Product.is_on_sale == True, Product.discount_percentage > 0)
        ).order_by(desc(Product.discount_percentage))
        reason = "Best deals and offers just for you"
        personalization = {
            "strategy": "deals_first",
            "show_flash_sales": True,
            "layout": "deal_banners",
        }

    elif user_type == UserTypeEnum.PREMIUM:
        # Show premium, high-quality products
        query = query.where(
            or_(Product.is_premium == True, Product.price > 3000)
        ).order_by(desc(Product.avg_rating), desc(Product.price))
        reason = "Premium curated collection for you"
        personalization = {
            "strategy": "premium_curated",
            "show_exclusive": True,
            "layout": "luxury_minimal",
        }

    # Paginate
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)

    result = await db.execute(query)
    products = result.scalars().all()

    return RecommendationResponse(
        user_type=user_type.value,
        recommended_products=[ProductResponse.model_validate(p) for p in products],
        reason=reason,
        personalization_applied=personalization,
    )


async def get_categories(db: AsyncSession) -> List[Category]:
    """Get all active categories."""
    result = await db.execute(
        select(Category)
        .where(Category.is_active == True)
        .order_by(Category.display_order, Category.name)
    )
    return result.scalars().all()


async def get_brands(db: AsyncSession) -> List[Brand]:
    """Get all active brands."""
    result = await db.execute(
        select(Brand)
        .where(Brand.is_active == True)
        .order_by(Brand.name)
    )
    return result.scalars().all()


async def get_product_by_id(product_id: int, db: AsyncSession) -> Optional[Product]:
    """Get a single product by ID."""
    result = await db.execute(select(Product).where(Product.id == product_id))
    return result.scalar_one_or_none()
