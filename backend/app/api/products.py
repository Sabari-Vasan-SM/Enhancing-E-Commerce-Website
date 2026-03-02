"""
Product API routes.
"""
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas import (
    ProductResponse, ProductListResponse, ProductCreate,
    CategoryResponse, BrandResponse, RecommendationResponse,
)
from app.services.product_service import (
    get_products, get_personalized_products,
    get_categories, get_brands, get_product_by_id,
)
from app.models.product import Product
from sqlalchemy import select

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("", response_model=ProductListResponse)
async def list_products(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    category_id: Optional[int] = None,
    brand_id: Optional[int] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    search: Optional[str] = None,
    is_on_sale: Optional[bool] = None,
    is_featured: Optional[bool] = None,
    is_premium: Optional[bool] = None,
    sort_by: str = Query("created_at", pattern="^(price|name|avg_rating|created_at|view_count|discount_percentage)$"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$"),
    db: AsyncSession = Depends(get_db),
):
    """Get paginated product listing with filters."""
    return await get_products(
        db, page, page_size, category_id, brand_id,
        min_price, max_price, search, is_on_sale,
        is_featured, is_premium, sort_by, sort_order,
    )


@router.get("/personalized", response_model=RecommendationResponse)
async def personalized_products(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get personalized product recommendations based on user type."""
    return await get_personalized_products(current_user.id, db, page, page_size)


@router.get("/categories", response_model=list[CategoryResponse])
async def list_categories(db: AsyncSession = Depends(get_db)):
    """Get all active categories."""
    categories = await get_categories(db)
    return [CategoryResponse.model_validate(c) for c in categories]


@router.get("/brands", response_model=list[BrandResponse])
async def list_brands(db: AsyncSession = Depends(get_db)):
    """Get all active brands."""
    brands = await get_brands(db)
    return [BrandResponse.model_validate(b) for b in brands]


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(product_id: int, db: AsyncSession = Depends(get_db)):
    """Get a single product by ID."""
    product = await get_product_by_id(product_id, db)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return ProductResponse.model_validate(product)


@router.post("", response_model=ProductResponse)
async def create_product(
    data: ProductCreate,
    db: AsyncSession = Depends(get_db),
):
    """Create a new product (admin endpoint)."""
    slug = data.name.lower().replace(" ", "-").replace("'", "")

    # Check slug uniqueness
    existing = await db.execute(select(Product).where(Product.slug == slug))
    if existing.scalar_one_or_none():
        slug = f"{slug}-{__import__('uuid').uuid4().hex[:6]}"

    product = Product(
        name=data.name,
        slug=slug,
        description=data.description,
        short_description=data.short_description,
        price=data.price,
        original_price=data.original_price,
        discount_percentage=data.discount_percentage,
        category_id=data.category_id,
        brand_id=data.brand_id,
        sku=data.sku,
        stock_quantity=data.stock_quantity,
        images=data.images,
        tags=data.tags,
        specifications=data.specifications,
        is_featured=data.is_featured,
        is_on_sale=data.is_on_sale,
        is_premium=data.is_premium,
        is_new_arrival=data.is_new_arrival,
    )
    db.add(product)
    await db.flush()
    return ProductResponse.model_validate(product)
