"""
Pydantic schemas for request/response validation.
"""
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


# ==================== ENUMS ====================

class UserTypeSchema(str, Enum):
    EXPLORATION = "exploration"
    BRAND = "brand"
    PRICE = "price"
    INTERACTION = "interaction"
    OFFER = "offer"
    PREMIUM = "premium"


class BehaviorTypeSchema(str, Enum):
    PRODUCT_VIEW = "product_view"
    PRODUCT_CLICK = "product_click"
    SEARCH = "search"
    FILTER_USE = "filter_use"
    ADD_TO_CART = "add_to_cart"
    REMOVE_FROM_CART = "remove_from_cart"
    ADD_TO_WISHLIST = "add_to_wishlist"
    REMOVE_FROM_WISHLIST = "remove_from_wishlist"
    PURCHASE = "purchase"
    BRAND_VIEW = "brand_view"
    CATEGORY_VIEW = "category_view"
    PRICE_FILTER = "price_filter"
    OFFER_CLICK = "offer_click"
    DISCOUNT_CLICK = "discount_click"
    REVIEW_READ = "review_read"
    PRICE_COMPARE = "price_compare"
    PAGE_SCROLL = "page_scroll"


# ==================== AUTH ====================

class UserRegister(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=100)
    password: str = Field(..., min_length=6, max_length=100)
    full_name: Optional[str] = None
    phone: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_type: str
    user_id: int


class TokenData(BaseModel):
    user_id: Optional[int] = None


# ==================== USER ====================

class UserProfile(BaseModel):
    id: int
    email: str
    username: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    user_type: UserTypeSchema
    user_type_confidence: float
    is_active: bool
    created_at: datetime
    last_login_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None


class UserTypeResponse(BaseModel):
    user_type: UserTypeSchema
    confidence: float
    scores: Dict[str, float] = {}
    last_classified_at: Optional[datetime] = None


# ==================== PRODUCT ====================

class CategoryResponse(BaseModel):
    id: int
    name: str
    slug: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    parent_id: Optional[int] = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class BrandResponse(BaseModel):
    id: int
    name: str
    slug: str
    description: Optional[str] = None
    logo_url: Optional[str] = None
    is_premium: bool

    model_config = ConfigDict(from_attributes=True)


class ProductResponse(BaseModel):
    id: int
    name: str
    slug: str
    description: Optional[str] = None
    short_description: Optional[str] = None
    price: float
    original_price: Optional[float] = None
    discount_percentage: float = 0.0
    category_id: int
    brand_id: Optional[int] = None
    images: List[str] = []
    tags: List[str] = []
    avg_rating: float = 0.0
    review_count: int = 0
    is_featured: bool = False
    is_on_sale: bool = False
    is_premium: bool = False
    is_new_arrival: bool = False
    stock_quantity: int = 0

    model_config = ConfigDict(from_attributes=True)


class ProductListResponse(BaseModel):
    products: List[ProductResponse]
    total: int
    page: int
    page_size: int
    has_next: bool


class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=300)
    description: Optional[str] = None
    short_description: Optional[str] = None
    price: float = Field(..., gt=0)
    original_price: Optional[float] = None
    discount_percentage: float = 0.0
    category_id: int
    brand_id: Optional[int] = None
    sku: Optional[str] = None
    stock_quantity: int = 0
    images: List[str] = []
    tags: List[str] = []
    specifications: Dict[str, Any] = {}
    is_featured: bool = False
    is_on_sale: bool = False
    is_premium: bool = False
    is_new_arrival: bool = False


# ==================== BEHAVIOR ====================

class BehaviorCreate(BaseModel):
    behavior_type: BehaviorTypeSchema
    product_id: Optional[int] = None
    category_id: Optional[int] = None
    brand_id: Optional[int] = None
    metadata_json: Dict[str, Any] = {}
    search_query: Optional[str] = None
    filter_type: Optional[str] = None
    filter_value: Optional[str] = None
    time_spent_seconds: float = 0.0
    session_id: Optional[str] = None
    device_type: Optional[str] = None
    platform: Optional[str] = None


class BehaviorBatchCreate(BaseModel):
    behaviors: List[BehaviorCreate]


class ProductViewCreate(BaseModel):
    product_id: int
    time_spent_seconds: float = 0.0
    scroll_depth_percentage: float = 0.0
    viewed_images: bool = False
    viewed_reviews: bool = False
    viewed_specifications: bool = False
    source: Optional[str] = None
    session_id: Optional[str] = None


class SearchCreate(BaseModel):
    query: str = Field(..., min_length=1)
    results_count: int = 0
    clicked_product_id: Optional[int] = None
    filters_applied: Dict[str, Any] = {}


# ==================== CART ====================

class CartItemCreate(BaseModel):
    product_id: int
    quantity: int = Field(default=1, ge=1)


class CartItemUpdate(BaseModel):
    quantity: int = Field(..., ge=1)


class CartItemResponse(BaseModel):
    id: int
    product_id: int
    quantity: int
    product: ProductResponse
    added_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==================== WISHLIST ====================

class WishlistItemCreate(BaseModel):
    product_id: int


class WishlistItemResponse(BaseModel):
    id: int
    product_id: int
    product: ProductResponse
    added_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==================== ORDER ====================

class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int = Field(..., ge=1)


class OrderCreate(BaseModel):
    items: List[OrderItemCreate]
    shipping_address: Dict[str, Any] = {}
    payment_method: Optional[str] = "cod"
    coupon_code: Optional[str] = None


class OrderFromCartCreate(BaseModel):
    shipping_address: Dict[str, Any] = {}
    payment_method: Optional[str] = "cod"
    coupon_code: Optional[str] = None


class OrderItemProductInfo(BaseModel):
    id: int
    name: str
    slug: str
    price: float
    images: List[str] = []
    brand_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class OrderItemResponse(BaseModel):
    id: int
    product_id: int
    quantity: int
    price_at_purchase: float
    discount_at_purchase: float
    total_price: float
    product: Optional[OrderItemProductInfo] = None

    model_config = ConfigDict(from_attributes=True)


class OrderResponse(BaseModel):
    id: int
    order_number: str
    status: str
    total_amount: float
    discount_amount: float
    tax_amount: float
    shipping_amount: float
    final_amount: float
    payment_method: Optional[str] = None
    payment_status: str
    shipping_address: Dict[str, Any] = {}
    items: List[OrderItemResponse] = []
    created_at: datetime
    delivered_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# ==================== RECOMMENDATIONS ====================

class RecommendationResponse(BaseModel):
    user_type: UserTypeSchema
    recommended_products: List[ProductResponse]
    reason: str
    personalization_applied: Dict[str, Any] = {}


# ==================== ANALYTICS ====================

class UserAnalyticsResponse(BaseModel):
    total_product_views: int = 0
    total_searches: int = 0
    total_orders: int = 0
    total_order_value: float = 0.0
    avg_order_value: float = 0.0
    total_cart_additions: int = 0
    total_wishlist_additions: int = 0
    exploration_score: float = 0.0
    brand_score: float = 0.0
    price_score: float = 0.0
    interaction_score: float = 0.0
    offer_score: float = 0.0
    premium_score: float = 0.0

    model_config = ConfigDict(from_attributes=True)
