"""
Models package - exports all models for easy access.
"""
from app.models.user import User, UserTypeEnum
from app.models.product import Product, Category, Brand
from app.models.behavior import UserBehavior, SearchHistory, ProductView, BehaviorType
from app.models.order import CartItem, WishlistItem, Order, OrderItem, OrderStatus, PaymentMethod
from app.models.analytics import UserTypeHistory, UserAnalytics

__all__ = [
    "User", "UserTypeEnum",
    "Product", "Category", "Brand",
    "UserBehavior", "SearchHistory", "ProductView", "BehaviorType",
    "CartItem", "WishlistItem", "Order", "OrderItem", "OrderStatus", "PaymentMethod",
    "UserTypeHistory", "UserAnalytics",
]
