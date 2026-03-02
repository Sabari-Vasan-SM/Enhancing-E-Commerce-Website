from app.services.auth_service import register_user, authenticate_user
from app.services.behavior_service import (
    track_behavior, track_batch_behaviors,
    track_product_view, track_search,
)
from app.services.product_service import (
    get_products, get_personalized_products,
    get_categories, get_brands, get_product_by_id,
)
from app.services.order_service import (
    get_cart, add_to_cart, update_cart_item, remove_from_cart,
    get_wishlist, add_to_wishlist, remove_from_wishlist,
    create_order, get_user_orders, get_order_by_id,
)
