"""
Analytics and User Type History models.
"""
from sqlalchemy import (
    Column, Integer, String, Float, DateTime, JSON,
    ForeignKey, Enum as SQLEnum
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
from app.models.user import UserTypeEnum


class UserTypeHistory(Base):
    """Tracks changes in user classification over time."""
    __tablename__ = "user_type_history"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    previous_type = Column(SQLEnum(UserTypeEnum), nullable=True)
    new_type = Column(SQLEnum(UserTypeEnum), nullable=False)
    confidence_score = Column(Float, default=0.0)

    # Classification details
    classification_method = Column(String(50), default="rule_based")  # rule_based or ml
    classification_scores = Column(JSON, default=dict)  # Detailed scores for each type
    trigger_reason = Column(String(500), nullable=True)  # What triggered reclassification

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="user_type_history")

    def __repr__(self):
        return f"<UserTypeHistory(user={self.user_id}, {self.previous_type}->{self.new_type})>"


class UserAnalytics(Base):
    """Aggregated analytics per user - updated periodically for fast access."""
    __tablename__ = "user_analytics"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True)

    # View metrics
    total_product_views = Column(Integer, default=0)
    total_category_views = Column(Integer, default=0)
    total_brand_views = Column(Integer, default=0)
    unique_products_viewed = Column(Integer, default=0)
    unique_categories_viewed = Column(Integer, default=0)
    unique_brands_viewed = Column(Integer, default=0)
    avg_time_per_product = Column(Float, default=0.0)
    total_time_spent = Column(Float, default=0.0)  # Total seconds on platform

    # Search metrics
    total_searches = Column(Integer, default=0)
    price_related_searches = Column(Integer, default=0)  # "cheap", "under X"
    offer_related_searches = Column(Integer, default=0)  # "sale", "offer", "discount"
    brand_related_searches = Column(Integer, default=0)

    # Filter metrics
    price_filter_usage = Column(Integer, default=0)
    brand_filter_usage = Column(Integer, default=0)
    category_filter_usage = Column(Integer, default=0)

    # Cart metrics
    total_cart_additions = Column(Integer, default=0)
    total_cart_removals = Column(Integer, default=0)
    cart_conversion_rate = Column(Float, default=0.0)

    # Wishlist metrics
    total_wishlist_additions = Column(Integer, default=0)

    # Order metrics
    total_orders = Column(Integer, default=0)
    total_order_value = Column(Float, default=0.0)
    avg_order_value = Column(Float, default=0.0)
    max_order_value = Column(Float, default=0.0)
    total_items_purchased = Column(Integer, default=0)
    sale_purchases_count = Column(Integer, default=0)

    # Offer/discount metrics
    offer_clicks = Column(Integer, default=0)
    discount_product_views = Column(Integer, default=0)
    coupon_usage_count = Column(Integer, default=0)

    # Brand loyalty metrics
    most_viewed_brand_id = Column(Integer, ForeignKey("brands.id"), nullable=True)
    most_viewed_brand_count = Column(Integer, default=0)
    brand_diversity_score = Column(Float, default=0.0)  # 0-1, low = loyal to few brands

    # Price sensitivity metrics
    avg_viewed_price = Column(Float, default=0.0)
    avg_purchased_price = Column(Float, default=0.0)
    price_range_min = Column(Float, default=0.0)
    price_range_max = Column(Float, default=0.0)
    price_comparison_count = Column(Integer, default=0)

    # Engagement metrics
    sessions_count = Column(Integer, default=0)
    avg_session_duration = Column(Float, default=0.0)
    pages_per_session = Column(Float, default=0.0)
    scroll_depth_avg = Column(Float, default=0.0)

    # Classification scores (0.0 - 1.0 for each type)
    exploration_score = Column(Float, default=0.5)
    brand_score = Column(Float, default=0.0)
    price_score = Column(Float, default=0.0)
    interaction_score = Column(Float, default=0.0)
    offer_score = Column(Float, default=0.0)
    premium_score = Column(Float, default=0.0)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="analytics")

    def __repr__(self):
        return f"<UserAnalytics(user={self.user_id})>"
