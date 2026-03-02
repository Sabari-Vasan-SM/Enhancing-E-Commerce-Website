"""
Behavior tracking API routes.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas import (
    BehaviorCreate, BehaviorBatchCreate,
    ProductViewCreate, SearchCreate,
    UserAnalyticsResponse,
)
from app.services.behavior_service import (
    track_behavior, track_batch_behaviors,
    track_product_view, track_search,
)
from app.models.analytics import UserAnalytics
from sqlalchemy import select

router = APIRouter(prefix="/behavior", tags=["Behavior Tracking"])


@router.post("/track")
async def record_behavior(
    data: BehaviorCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Record a single user behavior event."""
    behavior = await track_behavior(current_user.id, data, db)
    return {"status": "recorded", "behavior_id": behavior.id}


@router.post("/track/batch")
async def record_batch_behaviors(
    data: BehaviorBatchCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Record multiple behavior events in batch."""
    count = await track_batch_behaviors(current_user.id, data.behaviors, db)
    return {"status": "recorded", "count": count}


@router.post("/product-view")
async def record_product_view(
    data: ProductViewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Record a detailed product view with time spent and engagement."""
    view = await track_product_view(current_user.id, data, db)
    return {"status": "recorded", "view_id": view.id}


@router.post("/search")
async def record_search(
    data: SearchCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Record a search query."""
    search = await track_search(current_user.id, data, db)
    return {"status": "recorded", "search_id": search.id}


@router.get("/analytics", response_model=UserAnalyticsResponse)
async def get_analytics(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user analytics summary."""
    result = await db.execute(
        select(UserAnalytics).where(UserAnalytics.user_id == current_user.id)
    )
    analytics = result.scalar_one_or_none()
    if not analytics:
        return UserAnalyticsResponse()
    return UserAnalyticsResponse.model_validate(analytics)
