"""
Behavior tracking service - records and processes user interactions.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.models.behavior import UserBehavior, SearchHistory, ProductView, BehaviorType
from app.models.product import Product
from app.schemas import BehaviorCreate, ProductViewCreate, SearchCreate
from app.classification import classify_and_update_user
import logging

logger = logging.getLogger(__name__)


async def track_behavior(
    user_id: int, data: BehaviorCreate, db: AsyncSession
) -> UserBehavior:
    """Record a single user behavior event."""
    behavior = UserBehavior(
        user_id=user_id,
        behavior_type=BehaviorType(data.behavior_type.value),
        product_id=data.product_id,
        category_id=data.category_id,
        brand_id=data.brand_id,
        metadata_json=data.metadata_json,
        search_query=data.search_query,
        filter_type=data.filter_type,
        filter_value=data.filter_value,
        time_spent_seconds=data.time_spent_seconds,
        session_id=data.session_id,
        device_type=data.device_type,
        platform=data.platform,
    )
    db.add(behavior)
    await db.flush()

    # Increment product view count if applicable
    if data.behavior_type.value == "product_view" and data.product_id:
        result = await db.execute(
            select(Product).where(Product.id == data.product_id)
        )
        product = result.scalar_one_or_none()
        if product:
            product.view_count = (product.view_count or 0) + 1

    # Trigger reclassification (non-blocking, respects cooldown)
    try:
        await classify_and_update_user(user_id, db)
    except Exception as e:
        logger.warning(f"Reclassification failed for user {user_id}: {e}")

    return behavior


async def track_batch_behaviors(
    user_id: int, behaviors: list[BehaviorCreate], db: AsyncSession
) -> int:
    """Record multiple behavior events in batch."""
    count = 0
    for data in behaviors:
        behavior = UserBehavior(
            user_id=user_id,
            behavior_type=BehaviorType(data.behavior_type.value),
            product_id=data.product_id,
            category_id=data.category_id,
            brand_id=data.brand_id,
            metadata_json=data.metadata_json,
            search_query=data.search_query,
            filter_type=data.filter_type,
            filter_value=data.filter_value,
            time_spent_seconds=data.time_spent_seconds,
            session_id=data.session_id,
            device_type=data.device_type,
            platform=data.platform,
        )
        db.add(behavior)
        count += 1

    await db.flush()

    # Trigger reclassification after batch
    try:
        await classify_and_update_user(user_id, db)
    except Exception as e:
        logger.warning(f"Reclassification failed for user {user_id}: {e}")

    return count


async def track_product_view(
    user_id: int, data: ProductViewCreate, db: AsyncSession
) -> ProductView:
    """Record a detailed product view."""
    view = ProductView(
        user_id=user_id,
        product_id=data.product_id,
        time_spent_seconds=data.time_spent_seconds,
        scroll_depth_percentage=data.scroll_depth_percentage,
        viewed_images=data.viewed_images,
        viewed_reviews=data.viewed_reviews,
        viewed_specifications=data.viewed_specifications,
        source=data.source,
        session_id=data.session_id,
    )
    db.add(view)

    # Also record as general behavior
    general = UserBehavior(
        user_id=user_id,
        behavior_type=BehaviorType.PRODUCT_VIEW,
        product_id=data.product_id,
        time_spent_seconds=data.time_spent_seconds,
        session_id=data.session_id,
    )
    db.add(general)

    # Get product to track brand/category
    result = await db.execute(select(Product).where(Product.id == data.product_id))
    product = result.scalar_one_or_none()
    if product:
        product.view_count = (product.view_count or 0) + 1

        # Track brand view if product has a brand
        if product.brand_id:
            brand_behavior = UserBehavior(
                user_id=user_id,
                behavior_type=BehaviorType.BRAND_VIEW,
                product_id=data.product_id,
                brand_id=product.brand_id,
                session_id=data.session_id,
            )
            db.add(brand_behavior)

        # Track category view
        if product.category_id:
            cat_behavior = UserBehavior(
                user_id=user_id,
                behavior_type=BehaviorType.CATEGORY_VIEW,
                product_id=data.product_id,
                category_id=product.category_id,
                session_id=data.session_id,
            )
            db.add(cat_behavior)

        # Track offer click if product is on sale
        if product.is_on_sale or product.discount_percentage > 0:
            discount_behavior = UserBehavior(
                user_id=user_id,
                behavior_type=BehaviorType.DISCOUNT_CLICK,
                product_id=data.product_id,
                session_id=data.session_id,
            )
            db.add(discount_behavior)

    await db.flush()

    # Trigger reclassification
    try:
        await classify_and_update_user(user_id, db)
    except Exception as e:
        logger.warning(f"Reclassification failed for user {user_id}: {e}")

    return view


async def track_search(
    user_id: int, data: SearchCreate, db: AsyncSession
) -> SearchHistory:
    """Record a search query."""
    search = SearchHistory(
        user_id=user_id,
        query=data.query,
        results_count=data.results_count,
        clicked_product_id=data.clicked_product_id,
        filters_applied=data.filters_applied,
    )
    db.add(search)

    # Also record as general behavior
    general = UserBehavior(
        user_id=user_id,
        behavior_type=BehaviorType.SEARCH,
        search_query=data.query,
        metadata_json=data.filters_applied,
    )
    db.add(general)

    await db.flush()

    return search
