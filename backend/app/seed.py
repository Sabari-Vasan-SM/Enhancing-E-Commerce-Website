"""
Database seed script - populates the database with sample data for testing.
Run: python -m app.seed
"""
import asyncio
from app.core.database import AsyncSessionLocal, init_db
from app.models.product import Category, Brand, Product
from app.models.user import User
from app.core.security import get_password_hash


async def seed():
    await init_db()

    async with AsyncSessionLocal() as db:
        # ===== CATEGORIES =====
        categories = [
            Category(name="Electronics", slug="electronics", description="Phones, Laptops, Gadgets", display_order=1),
            Category(name="Fashion", slug="fashion", description="Clothing, Shoes, Accessories", display_order=2),
            Category(name="Home & Kitchen", slug="home-kitchen", description="Furniture, Appliances, Decor", display_order=3),
            Category(name="Books", slug="books", description="Fiction, Non-fiction, Textbooks", display_order=4),
            Category(name="Sports & Fitness", slug="sports-fitness", description="Equipment, Clothing, Supplements", display_order=5),
            Category(name="Beauty & Personal Care", slug="beauty-personal-care", description="Skincare, Makeup, Fragrance", display_order=6),
            Category(name="Toys & Games", slug="toys-games", description="Kids Toys, Board Games, Puzzles", display_order=7),
            Category(name="Groceries", slug="groceries", description="Food, Beverages, Household", display_order=8),
        ]
        db.add_all(categories)
        await db.flush()

        # ===== BRANDS =====
        brands = [
            Brand(name="Apple", slug="apple", is_premium=True, logo_url="https://placeholder.com/apple.png"),
            Brand(name="Samsung", slug="samsung", is_premium=False, logo_url="https://placeholder.com/samsung.png"),
            Brand(name="Nike", slug="nike", is_premium=True, logo_url="https://placeholder.com/nike.png"),
            Brand(name="Adidas", slug="adidas", is_premium=False, logo_url="https://placeholder.com/adidas.png"),
            Brand(name="Sony", slug="sony", is_premium=True, logo_url="https://placeholder.com/sony.png"),
            Brand(name="LG", slug="lg", is_premium=False, logo_url="https://placeholder.com/lg.png"),
            Brand(name="Puma", slug="puma", is_premium=False, logo_url="https://placeholder.com/puma.png"),
            Brand(name="Boat", slug="boat", is_premium=False, logo_url="https://placeholder.com/boat.png"),
            Brand(name="OnePlus", slug="oneplus", is_premium=False, logo_url="https://placeholder.com/oneplus.png"),
            Brand(name="Gucci", slug="gucci", is_premium=True, logo_url="https://placeholder.com/gucci.png"),
        ]
        db.add_all(brands)
        await db.flush()

        # ===== PRODUCTS =====
        products = [
            # Electronics - Premium
            Product(name="iPhone 15 Pro Max", slug="iphone-15-pro-max", price=134900, original_price=139900, discount_percentage=3.6, category_id=1, brand_id=1, stock_quantity=50, images=["https://placeholder.com/iphone15.jpg"], tags=["phone", "premium", "apple"], is_premium=True, is_featured=True, avg_rating=4.8, review_count=1200),
            Product(name="MacBook Pro M3", slug="macbook-pro-m3", price=199900, original_price=199900, category_id=1, brand_id=1, stock_quantity=30, images=["https://placeholder.com/macbook.jpg"], tags=["laptop", "premium", "apple"], is_premium=True, avg_rating=4.9, review_count=800),
            Product(name="Samsung Galaxy S24 Ultra", slug="samsung-s24-ultra", price=129999, original_price=134999, discount_percentage=3.7, category_id=1, brand_id=2, stock_quantity=60, images=["https://placeholder.com/s24.jpg"], tags=["phone", "premium", "samsung"], is_premium=True, is_featured=True, avg_rating=4.7, review_count=950),
            Product(name="Sony WH-1000XM5", slug="sony-wh-1000xm5", price=29990, original_price=34990, discount_percentage=14.3, category_id=1, brand_id=5, stock_quantity=100, images=["https://placeholder.com/sonyxm5.jpg"], tags=["headphones", "premium", "noise-cancelling"], is_premium=True, is_on_sale=True, avg_rating=4.6, review_count=2100),

            # Electronics - Budget
            Product(name="Boat Rockerz 450", slug="boat-rockerz-450", price=1499, original_price=2990, discount_percentage=49.9, category_id=1, brand_id=8, stock_quantity=500, images=["https://placeholder.com/boat450.jpg"], tags=["headphones", "budget", "wireless"], is_on_sale=True, avg_rating=4.1, review_count=15000),
            Product(name="OnePlus Nord CE 3", slug="oneplus-nord-ce3", price=24999, original_price=27999, discount_percentage=10.7, category_id=1, brand_id=9, stock_quantity=200, images=["https://placeholder.com/nord.jpg"], tags=["phone", "mid-range"], is_on_sale=True, avg_rating=4.3, review_count=3500),
            Product(name="Samsung Galaxy A15", slug="samsung-galaxy-a15", price=13999, original_price=16999, discount_percentage=17.6, category_id=1, brand_id=2, stock_quantity=300, images=["https://placeholder.com/a15.jpg"], tags=["phone", "budget", "samsung"], is_on_sale=True, avg_rating=4.0, review_count=5000),

            # Fashion - Premium
            Product(name="Gucci GG Marmont Bag", slug="gucci-gg-marmont", price=125000, category_id=2, brand_id=10, stock_quantity=10, images=["https://placeholder.com/gucci-bag.jpg"], tags=["bag", "luxury", "premium"], is_premium=True, avg_rating=4.9, review_count=50),
            Product(name="Nike Air Jordan 1 Retro", slug="nike-air-jordan-1", price=16995, original_price=16995, category_id=2, brand_id=3, stock_quantity=80, images=["https://placeholder.com/jordan1.jpg"], tags=["shoes", "sneakers", "premium"], is_premium=True, is_featured=True, avg_rating=4.7, review_count=3200),

            # Fashion - Budget
            Product(name="Puma Running Shoes", slug="puma-running-shoes", price=2499, original_price=4999, discount_percentage=50.0, category_id=2, brand_id=7, stock_quantity=400, images=["https://placeholder.com/puma-run.jpg"], tags=["shoes", "running", "sale"], is_on_sale=True, avg_rating=4.2, review_count=8000),
            Product(name="Adidas Essentials T-Shirt", slug="adidas-essential-tshirt", price=999, original_price=1999, discount_percentage=50.0, category_id=2, brand_id=4, stock_quantity=600, images=["https://placeholder.com/adidas-tshirt.jpg"], tags=["clothing", "casual", "sale"], is_on_sale=True, avg_rating=4.1, review_count=12000),
            Product(name="Nike Dri-FIT Shorts", slug="nike-dri-fit-shorts", price=1495, original_price=2495, discount_percentage=40.1, category_id=2, brand_id=3, stock_quantity=350, images=["https://placeholder.com/nike-shorts.jpg"], tags=["clothing", "sports", "sale"], is_on_sale=True, avg_rating=4.3, review_count=6000),

            # Home & Kitchen
            Product(name="LG 55 inch OLED TV", slug="lg-55-oled-tv", price=129990, original_price=149990, discount_percentage=13.3, category_id=3, brand_id=6, stock_quantity=25, images=["https://placeholder.com/lg-tv.jpg"], tags=["tv", "premium", "oled"], is_premium=True, is_on_sale=True, avg_rating=4.8, review_count=450),
            Product(name="Samsung Refrigerator 253L", slug="samsung-fridge-253l", price=22990, original_price=26990, discount_percentage=14.8, category_id=3, brand_id=2, stock_quantity=40, images=["https://placeholder.com/samsung-fridge.jpg"], tags=["appliance", "kitchen"], is_on_sale=True, avg_rating=4.4, review_count=2200),

            # Sports
            Product(name="Nike Pro Training Mat", slug="nike-pro-training-mat", price=2995, category_id=5, brand_id=3, stock_quantity=200, images=["https://placeholder.com/nike-mat.jpg"], tags=["fitness", "yoga", "training"], avg_rating=4.5, review_count=1800),
            Product(name="Adidas Predator Football", slug="adidas-predator-football", price=3999, category_id=5, brand_id=4, stock_quantity=150, images=["https://placeholder.com/adidas-football.jpg"], tags=["football", "sports"], avg_rating=4.6, review_count=900),

            # New Arrivals
            Product(name="Apple Watch Ultra 2", slug="apple-watch-ultra-2", price=89900, category_id=1, brand_id=1, stock_quantity=45, images=["https://placeholder.com/watch-ultra.jpg"], tags=["watch", "premium", "apple"], is_premium=True, is_new_arrival=True, avg_rating=4.8, review_count=320),
            Product(name="Samsung Galaxy Buds FE", slug="samsung-buds-fe", price=6999, original_price=9999, discount_percentage=30.0, category_id=1, brand_id=2, stock_quantity=250, images=["https://placeholder.com/buds-fe.jpg"], tags=["earbuds", "wireless", "sale"], is_on_sale=True, is_new_arrival=True, avg_rating=4.2, review_count=1500),

            # More budget items
            Product(name="Boat Airdopes 141", slug="boat-airdopes-141", price=999, original_price=2490, discount_percentage=59.9, category_id=1, brand_id=8, stock_quantity=1000, images=["https://placeholder.com/airdopes.jpg"], tags=["earbuds", "budget", "sale"], is_on_sale=True, avg_rating=3.9, review_count=25000),
            Product(name="Puma Backpack 25L", slug="puma-backpack-25l", price=1299, original_price=2199, discount_percentage=40.9, category_id=2, brand_id=7, stock_quantity=300, images=["https://placeholder.com/puma-bag.jpg"], tags=["bag", "casual", "sale"], is_on_sale=True, avg_rating=4.0, review_count=5500),
        ]
        db.add_all(products)

        # ===== DEMO USER =====
        demo_user = User(
            email="demo@example.com",
            username="demo_user",
            hashed_password=get_password_hash("demo123"),
            full_name="Demo User",
        )
        db.add(demo_user)

        await db.commit()
        print("Database seeded successfully!")
        print(f"   - {len(categories)} categories")
        print(f"   - {len(brands)} brands")
        print(f"   - {len(products)} products")
        print(f"   - 1 demo user (demo@example.com / demo123)")


if __name__ == "__main__":
    asyncio.run(seed())
