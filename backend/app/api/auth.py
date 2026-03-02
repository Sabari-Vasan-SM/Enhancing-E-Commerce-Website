"""
Authentication API routes.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas import (
    UserRegister, UserLogin, Token, UserProfile,
    UserProfileUpdate, UserTypeResponse,
)
from app.services.auth_service import register_user, authenticate_user
from app.classification import classify_and_update_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserProfile)
async def register(data: UserRegister, db: AsyncSession = Depends(get_db)):
    """Register a new user account."""
    user = await register_user(data, db)
    return UserProfile.model_validate(user)


@router.post("/login", response_model=Token)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    """Login and get access token."""
    return await authenticate_user(data, db)


@router.get("/me", response_model=UserProfile)
async def get_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile."""
    return UserProfile.model_validate(current_user)


@router.put("/me", response_model=UserProfile)
async def update_profile(
    data: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update current user profile."""
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.phone is not None:
        current_user.phone = data.phone
    if data.avatar_url is not None:
        current_user.avatar_url = data.avatar_url
    await db.flush()
    return UserProfile.model_validate(current_user)


@router.get("/user-type", response_model=UserTypeResponse)
async def get_user_type(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user classification type with scores."""
    user_type, confidence, scores = await classify_and_update_user(
        current_user.id, db
    )
    return UserTypeResponse(
        user_type=user_type.value,
        confidence=confidence,
        scores=scores,
        last_classified_at=current_user.last_classified_at,
    )


@router.post("/reclassify", response_model=UserTypeResponse)
async def force_reclassify(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Force reclassification of user type."""
    user_type, confidence, scores = await classify_and_update_user(
        current_user.id, db, force=True
    )
    return UserTypeResponse(
        user_type=user_type.value,
        confidence=confidence,
        scores=scores,
        last_classified_at=current_user.last_classified_at,
    )
