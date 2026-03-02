"""
User behavior tracking models.
Captures all user interactions for classification and personalization.
"""
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, Text,
    ForeignKey, JSON, Enum as SQLEnum
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class BehaviorType(str, enum.Enum):
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


class UserBehavior(Base):
    """Master behavior tracking table - logs every user action."""
    __tablename__ = "user_behaviors"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    behavior_type = Column(SQLEnum(BehaviorType), nullable=False, index=True)

    # Context data
    product_id = Column(Integer, ForeignKey("products.id"), nullable=True, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    brand_id = Column(Integer, ForeignKey("brands.id"), nullable=True)

    # Behavior metadata
    metadata_json = Column(JSON, default=dict)  # Flexible extra data
    search_query = Column(String(500), nullable=True)
    filter_type = Column(String(100), nullable=True)  # e.g., "price", "brand", "category"
    filter_value = Column(String(500), nullable=True)

    # Time tracking
    time_spent_seconds = Column(Float, default=0.0)
    session_id = Column(String(100), nullable=True, index=True)

    # Device info
    device_type = Column(String(50), nullable=True)  # mobile, web, tablet
    platform = Column(String(50), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="behaviors")

    def __repr__(self):
        return f"<UserBehavior(user={self.user_id}, type={self.behavior_type})>"


class SearchHistory(Base):
    """Dedicated search history tracking."""
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    query = Column(String(500), nullable=False, index=True)
    results_count = Column(Integer, default=0)
    clicked_product_id = Column(Integer, ForeignKey("products.id"), nullable=True)
    filters_applied = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="search_history")

    def __repr__(self):
        return f"<SearchHistory(user={self.user_id}, query={self.query})>"


class ProductView(Base):
    """Detailed product view tracking with time spent."""
    __tablename__ = "product_views"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False, index=True)
    time_spent_seconds = Column(Float, default=0.0)
    scroll_depth_percentage = Column(Float, default=0.0)
    viewed_images = Column(Boolean, default=False)
    viewed_reviews = Column(Boolean, default=False)
    viewed_specifications = Column(Boolean, default=False)
    source = Column(String(100), nullable=True)  # search, recommendation, category, etc.
    session_id = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="product_views")
    product = relationship("Product", back_populates="product_views")

    def __repr__(self):
        return f"<ProductView(user={self.user_id}, product={self.product_id})>"
