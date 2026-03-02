"""
Rule-Based User Classification Engine.

Classifies users into one of 6 types based on their behavior data.
Designed with a clean interface so it can be swapped with ML models later.
"""
from typing import Dict, Tuple, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from datetime import datetime, timedelta, timezone
from app.models.user import User, UserTypeEnum
from app.models.behavior import UserBehavior, BehaviorType, SearchHistory, ProductView
from app.models.order import Order, OrderItem, CartItem, WishlistItem
from app.models.product import Product
from app.models.analytics import UserAnalytics, UserTypeHistory
from app.core.config import settings
import re
import logging

logger = logging.getLogger(__name__)


class BaseClassifier:
    """
    Abstract base class for user classification.
    Both rule-based and ML classifiers implement this interface.
    """

    async def classify(self, user_id: int, db: AsyncSession) -> Tuple[UserTypeEnum, float, Dict[str, float]]:
        """
        Classify a user and return (user_type, confidence, scores_dict).
        Must be implemented by subclasses.
        """
        raise NotImplementedError


class RuleBasedClassifier(BaseClassifier):
    """
    Rule-based classifier using weighted scoring across behavior dimensions.

    Each user type has a score computed from behavior metrics.
    The type with the highest normalized score wins.

    Scoring dimensions:
    - Exploration: category diversity, no strong preference signals
    - Brand: brand view concentration, brand filter usage
    - Price: price filter usage, budget-related searches
    - Interaction: total engagement, views, cart activity, time spent
    - Offer: offer/discount clicks, sale-related searches
    - Premium: high avg purchase price, expensive product views
    """

    # Budget-related search keywords
    PRICE_KEYWORDS = re.compile(
        r'\b(cheap|budget|affordable|under\s*\d+|below\s*\d+|low\s*price|discount|'
        r'economy|value|inexpensive|bargain|deal)\b',
        re.IGNORECASE
    )

    # Offer/sale search keywords
    OFFER_KEYWORDS = re.compile(
        r'\b(sale|offer|deal|coupon|flash|clearance|limited\s*time|'
        r'promo|promotion|cashback|reward|free\s*shipping)\b',
        re.IGNORECASE
    )

    async def _get_or_create_analytics(self, user_id: int, db: AsyncSession) -> UserAnalytics:
        """Get existing analytics or create new record."""
        result = await db.execute(
            select(UserAnalytics).where(UserAnalytics.user_id == user_id)
        )
        analytics = result.scalar_one_or_none()
        if not analytics:
            analytics = UserAnalytics(user_id=user_id)
            db.add(analytics)
            await db.flush()
        return analytics

    async def _compute_behavior_metrics(self, user_id: int, db: AsyncSession) -> Dict[str, float]:
        """Compute all behavior metrics from raw data."""
        metrics = {}

        # --- Product view metrics ---
        total_views = await db.scalar(
            select(func.count(ProductView.id)).where(ProductView.user_id == user_id)
        ) or 0
        metrics["total_product_views"] = total_views

        unique_products = await db.scalar(
            select(func.count(func.distinct(ProductView.product_id)))
            .where(ProductView.user_id == user_id)
        ) or 0
        metrics["unique_products_viewed"] = unique_products

        avg_time = await db.scalar(
            select(func.avg(ProductView.time_spent_seconds))
            .where(ProductView.user_id == user_id)
        ) or 0.0
        metrics["avg_time_per_product"] = float(avg_time)

        total_time = await db.scalar(
            select(func.sum(ProductView.time_spent_seconds))
            .where(ProductView.user_id == user_id)
        ) or 0.0
        metrics["total_time_spent"] = float(total_time)

        # --- Brand metrics ---
        brand_views_result = await db.execute(
            select(
                UserBehavior.brand_id,
                func.count(UserBehavior.id).label("count")
            )
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.behavior_type == BehaviorType.BRAND_VIEW,
                    UserBehavior.brand_id.isnot(None)
                )
            )
            .group_by(UserBehavior.brand_id)
            .order_by(func.count(UserBehavior.id).desc())
        )
        brand_views = brand_views_result.all()

        metrics["total_brand_views"] = sum(bv.count for bv in brand_views) if brand_views else 0
        metrics["unique_brands_viewed"] = len(brand_views)
        metrics["most_viewed_brand_count"] = brand_views[0].count if brand_views else 0

        # Brand concentration (how focused on top brand)
        if metrics["total_brand_views"] > 0 and brand_views:
            metrics["brand_concentration"] = metrics["most_viewed_brand_count"] / metrics["total_brand_views"]
        else:
            metrics["brand_concentration"] = 0.0

        # Brand filter usage
        brand_filter_count = await db.scalar(
            select(func.count(UserBehavior.id))
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.behavior_type == BehaviorType.FILTER_USE,
                    UserBehavior.filter_type == "brand"
                )
            )
        ) or 0
        metrics["brand_filter_usage"] = brand_filter_count

        # --- Category metrics ---
        unique_categories = await db.scalar(
            select(func.count(func.distinct(UserBehavior.category_id)))
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.category_id.isnot(None)
                )
            )
        ) or 0
        metrics["unique_categories_viewed"] = unique_categories

        # --- Price metrics ---
        price_filter_count = await db.scalar(
            select(func.count(UserBehavior.id))
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.behavior_type == BehaviorType.PRICE_FILTER,
                )
            )
        ) or 0
        metrics["price_filter_usage"] = price_filter_count

        price_compare_count = await db.scalar(
            select(func.count(UserBehavior.id))
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.behavior_type == BehaviorType.PRICE_COMPARE,
                )
            )
        ) or 0
        metrics["price_comparison_count"] = price_compare_count

        # --- Search metrics ---
        searches = await db.execute(
            select(SearchHistory.query).where(SearchHistory.user_id == user_id)
        )
        search_queries = [s[0] for s in searches.all()]
        metrics["total_searches"] = len(search_queries)

        price_searches = sum(1 for q in search_queries if self.PRICE_KEYWORDS.search(q))
        offer_searches = sum(1 for q in search_queries if self.OFFER_KEYWORDS.search(q))
        metrics["price_related_searches"] = price_searches
        metrics["offer_related_searches"] = offer_searches

        # --- Cart metrics ---
        cart_additions = await db.scalar(
            select(func.count(UserBehavior.id))
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.behavior_type == BehaviorType.ADD_TO_CART,
                )
            )
        ) or 0
        metrics["total_cart_additions"] = cart_additions

        # --- Wishlist metrics ---
        wishlist_additions = await db.scalar(
            select(func.count(UserBehavior.id))
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.behavior_type == BehaviorType.ADD_TO_WISHLIST,
                )
            )
        ) or 0
        metrics["total_wishlist_additions"] = wishlist_additions

        # --- Order metrics ---
        order_stats = await db.execute(
            select(
                func.count(Order.id),
                func.coalesce(func.sum(Order.final_amount), 0),
                func.coalesce(func.avg(Order.final_amount), 0),
                func.coalesce(func.max(Order.final_amount), 0),
            ).where(Order.user_id == user_id)
        )
        order_row = order_stats.one()
        metrics["total_orders"] = order_row[0]
        metrics["total_order_value"] = float(order_row[1])
        metrics["avg_order_value"] = float(order_row[2])
        metrics["max_order_value"] = float(order_row[3])

        # Sale purchases
        sale_purchases = await db.scalar(
            select(func.count(Order.id))
            .where(and_(Order.user_id == user_id, Order.is_sale_purchase == True))
        ) or 0
        metrics["sale_purchases_count"] = sale_purchases

        # --- Offer/discount metrics ---
        offer_clicks = await db.scalar(
            select(func.count(UserBehavior.id))
            .where(
                and_(
                    UserBehavior.user_id == user_id,
                    UserBehavior.behavior_type.in_([
                        BehaviorType.OFFER_CLICK,
                        BehaviorType.DISCOUNT_CLICK,
                    ])
                )
            )
        ) or 0
        metrics["offer_clicks"] = offer_clicks

        # --- Average viewed product price ---
        avg_viewed_price = await db.execute(
            select(func.avg(Product.price))
            .join(ProductView, ProductView.product_id == Product.id)
            .where(ProductView.user_id == user_id)
        )
        metrics["avg_viewed_price"] = float(avg_viewed_price.scalar_one_or_none() or 0.0)

        # Average purchased price
        avg_purchased = await db.execute(
            select(func.avg(OrderItem.price_at_purchase))
            .join(Order, Order.id == OrderItem.order_id)
            .where(Order.user_id == user_id)
        )
        metrics["avg_purchased_price"] = float(avg_purchased.scalar_one_or_none() or 0.0)

        return metrics

    def _compute_scores(self, metrics: Dict[str, float]) -> Dict[str, float]:
        """
        Compute classification scores for each user type (0.0 - 1.0).
        Uses weighted scoring with normalization.
        """
        scores = {}

        # ===== EXPLORATION SCORE =====
        # High category diversity, no strong single-type signal
        category_diversity = min(metrics.get("unique_categories_viewed", 0) / 10.0, 1.0)
        low_brand_focus = 1.0 - metrics.get("brand_concentration", 0.0)
        is_new = 1.0 if metrics.get("total_product_views", 0) < 10 else 0.3
        scores["exploration"] = (category_diversity * 0.4 + low_brand_focus * 0.3 + is_new * 0.3)

        # ===== BRAND SCORE =====
        brand_views_signal = min(metrics.get("total_brand_views", 0) / 15.0, 1.0)
        brand_concentration = metrics.get("brand_concentration", 0.0)
        brand_filter_signal = min(metrics.get("brand_filter_usage", 0) / 5.0, 1.0)
        brand_search_signal = min(metrics.get("brand_related_searches", 0) / 5.0, 1.0) if metrics.get("brand_related_searches") else 0.0
        scores["brand"] = (
            brand_views_signal * 0.3 +
            brand_concentration * 0.3 +
            brand_filter_signal * 0.25 +
            brand_search_signal * 0.15
        )

        # ===== PRICE SCORE =====
        price_filter_signal = min(metrics.get("price_filter_usage", 0) / 5.0, 1.0)
        price_search_signal = min(metrics.get("price_related_searches", 0) / 3.0, 1.0)
        price_compare_signal = min(metrics.get("price_comparison_count", 0) / 5.0, 1.0)
        # Prefer lower-priced products
        avg_viewed = metrics.get("avg_viewed_price", 0)
        low_price_preference = 1.0 if avg_viewed > 0 and avg_viewed < 1000 else (0.5 if avg_viewed < 3000 else 0.1)
        scores["price"] = (
            price_filter_signal * 0.3 +
            price_search_signal * 0.3 +
            price_compare_signal * 0.2 +
            low_price_preference * 0.2
        )

        # ===== INTERACTION SCORE =====
        view_intensity = min(metrics.get("total_product_views", 0) / 50.0, 1.0)
        cart_activity = min(metrics.get("total_cart_additions", 0) / 15.0, 1.0)
        time_engagement = min(metrics.get("total_time_spent", 0) / 3600.0, 1.0)  # 1 hour max
        wishlist_activity = min(metrics.get("total_wishlist_additions", 0) / 10.0, 1.0)
        scores["interaction"] = (
            view_intensity * 0.3 +
            cart_activity * 0.25 +
            time_engagement * 0.25 +
            wishlist_activity * 0.2
        )

        # ===== OFFER SCORE =====
        offer_click_signal = min(metrics.get("offer_clicks", 0) / 10.0, 1.0)
        offer_search_signal = min(metrics.get("offer_related_searches", 0) / 3.0, 1.0)
        sale_purchase_signal = min(metrics.get("sale_purchases_count", 0) / 3.0, 1.0)
        discount_view_signal = 0.0  # Can be computed from product discount percentages
        scores["offer"] = (
            offer_click_signal * 0.35 +
            offer_search_signal * 0.3 +
            sale_purchase_signal * 0.25 +
            discount_view_signal * 0.1
        )

        # ===== PREMIUM SCORE =====
        avg_order = metrics.get("avg_order_value", 0)
        high_order_signal = min(avg_order / settings.PREMIUM_AVG_ORDER_THRESHOLD, 1.0) if avg_order > 0 else 0.0
        high_price_view = 1.0 if metrics.get("avg_viewed_price", 0) > 3000 else (
            0.5 if metrics.get("avg_viewed_price", 0) > 1500 else 0.1
        )
        max_order_signal = min(metrics.get("max_order_value", 0) / 10000.0, 1.0)
        low_discount_preference = 1.0 - min(metrics.get("offer_clicks", 0) / 10.0, 0.8)
        scores["premium"] = (
            high_order_signal * 0.35 +
            high_price_view * 0.25 +
            max_order_signal * 0.2 +
            low_discount_preference * 0.2
        )

        return scores

    async def classify(
        self, user_id: int, db: AsyncSession
    ) -> Tuple[UserTypeEnum, float, Dict[str, float]]:
        """
        Classify a user based on their behavior metrics.

        Returns:
            Tuple of (UserTypeEnum, confidence_score, all_scores)
        """
        # Compute raw behavior metrics
        metrics = await self._compute_behavior_metrics(user_id, db)

        # Compute scores for each type
        scores = self._compute_scores(metrics)

        # Find the winning type
        max_type = max(scores, key=scores.get)
        max_score = scores[max_type]

        # Compute confidence: difference between top and runner-up
        sorted_scores = sorted(scores.values(), reverse=True)
        if len(sorted_scores) > 1:
            confidence = sorted_scores[0] - sorted_scores[1]
        else:
            confidence = max_score

        # If no significant signal, default to exploration
        if max_score < 0.15:
            user_type = UserTypeEnum.EXPLORATION
            confidence = 0.5
        else:
            user_type = UserTypeEnum(max_type)

        # Clamp confidence to [0, 1]
        confidence = min(max(confidence, 0.0), 1.0)

        # Update analytics record
        analytics = await self._get_or_create_analytics(user_id, db)
        analytics.total_product_views = int(metrics.get("total_product_views", 0))
        analytics.total_searches = int(metrics.get("total_searches", 0))
        analytics.total_orders = int(metrics.get("total_orders", 0))
        analytics.total_order_value = metrics.get("total_order_value", 0.0)
        analytics.avg_order_value = metrics.get("avg_order_value", 0.0)
        analytics.total_cart_additions = int(metrics.get("total_cart_additions", 0))
        analytics.total_wishlist_additions = int(metrics.get("total_wishlist_additions", 0))
        analytics.avg_viewed_price = metrics.get("avg_viewed_price", 0.0)
        analytics.avg_purchased_price = metrics.get("avg_purchased_price", 0.0)
        analytics.price_filter_usage = int(metrics.get("price_filter_usage", 0))
        analytics.brand_filter_usage = int(metrics.get("brand_filter_usage", 0))
        analytics.offer_clicks = int(metrics.get("offer_clicks", 0))
        analytics.total_brand_views = int(metrics.get("total_brand_views", 0))
        analytics.price_related_searches = int(metrics.get("price_related_searches", 0))
        analytics.offer_related_searches = int(metrics.get("offer_related_searches", 0))
        analytics.total_time_spent = metrics.get("total_time_spent", 0.0)
        analytics.avg_time_per_product = metrics.get("avg_time_per_product", 0.0)
        analytics.unique_brands_viewed = int(metrics.get("unique_brands_viewed", 0))
        analytics.unique_products_viewed = int(metrics.get("unique_products_viewed", 0))
        analytics.unique_categories_viewed = int(metrics.get("unique_categories_viewed", 0))
        analytics.price_comparison_count = int(metrics.get("price_comparison_count", 0))

        # Store classification scores
        analytics.exploration_score = scores.get("exploration", 0.0)
        analytics.brand_score = scores.get("brand", 0.0)
        analytics.price_score = scores.get("price", 0.0)
        analytics.interaction_score = scores.get("interaction", 0.0)
        analytics.offer_score = scores.get("offer", 0.0)
        analytics.premium_score = scores.get("premium", 0.0)

        await db.flush()

        logger.info(
            f"User {user_id} classified as {user_type.value} "
            f"(confidence={confidence:.2f}, scores={scores})"
        )

        return user_type, confidence, scores


class MLClassifier(BaseClassifier):
    """
    ML-based classifier placeholder.
    Will use a trained model for classification.
    Implements the same interface as RuleBasedClassifier.
    """

    def __init__(self, model_path: Optional[str] = None):
        self.model = None
        self.model_path = model_path
        # Future: load model from path
        # self.model = joblib.load(model_path)

    async def classify(
        self, user_id: int, db: AsyncSession
    ) -> Tuple[UserTypeEnum, float, Dict[str, float]]:
        """
        ML classification - placeholder for future implementation.
        Falls back to rule-based for now.
        """
        logger.warning("ML classifier not yet implemented, falling back to rule-based")
        fallback = RuleBasedClassifier()
        return await fallback.classify(user_id, db)


# Factory function - allows easy switching between classifiers
def get_classifier(method: str = "rule_based") -> BaseClassifier:
    """
    Factory function to get the appropriate classifier.
    Supports 'rule_based' and 'ml' methods.
    """
    if method == "ml":
        return MLClassifier()
    return RuleBasedClassifier()


async def classify_and_update_user(
    user_id: int,
    db: AsyncSession,
    method: str = "rule_based",
    force: bool = False,
) -> Tuple[UserTypeEnum, float, Dict[str, float]]:
    """
    Classify a user and update their user_type in the database.
    Optionally checks if enough time has passed since last classification.

    Args:
        user_id: The user ID to classify
        db: Database session
        method: Classification method ('rule_based' or 'ml')
        force: Skip time check and force reclassification

    Returns:
        Tuple of (user_type, confidence, scores)
    """
    # Get current user
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise ValueError(f"User {user_id} not found")

    # Check if reclassification is needed (unless forced)
    if not force and user.last_classified_at:
        time_since = datetime.now(timezone.utc) - user.last_classified_at.replace(tzinfo=timezone.utc)
        if time_since < timedelta(minutes=settings.RECLASSIFICATION_INTERVAL_MINUTES):
            return user.user_type, user.user_type_confidence, {}

    # Classify
    classifier = get_classifier(method)
    new_type, confidence, scores = await classifier.classify(user_id, db)

    # Track type change
    previous_type = user.user_type
    if previous_type != new_type:
        history = UserTypeHistory(
            user_id=user_id,
            previous_type=previous_type,
            new_type=new_type,
            confidence_score=confidence,
            classification_method=method,
            classification_scores=scores,
            trigger_reason=f"Reclassification: {previous_type.value} -> {new_type.value}",
        )
        db.add(history)

    # Update user
    user.user_type = new_type
    user.user_type_confidence = confidence
    user.last_classified_at = datetime.now(timezone.utc)

    await db.flush()

    return new_type, confidence, scores
