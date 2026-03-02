# Enhancing E-Commerce Websites with Multi-UI Personalization Based on User Actions and Order Data

## Project Documentation

---

## 1. Problem Statement

In today's competitive e-commerce market, over 70% of online shoppers abandon their carts, and generic user interfaces fail to engage diverse customer segments. Current e-commerce platforms present the same interface to all users, regardless of their browsing behavior, purchase history, or shopping preferences.

This project addresses the challenge of **dynamic UI personalization** in e-commerce applications. By analyzing user actions (browsing patterns, search queries, product views, wishlist additions) and order data (purchase frequency, average order value, product categories), the system classifies users into distinct behavioral types and renders a completely personalized UI layout for each type - in real-time.

---

## 2. Motivation

- **Amazon** uses recommendation engines but does NOT change the entire UI layout per user type
- **Netflix** adapts content ordering but maintains a static interface structure
- **Existing research** focuses on product recommendations, not complete UI transformation
- Most e-commerce personalization is limited to "Recommended Products" sections
- No existing system dynamically switches the entire home screen layout based on behavioral classification

**Gap Identified:** There is no widely adopted system that dynamically transforms the entire UI (layout, sections, color accents, feature emphasis) based on real-time user behavior classification.

---

## 3. Objectives

### Primary Objectives
1. Design and implement a user behavior tracking system that captures browsing patterns, search history, product interactions, cart activity, and order data
2. Develop a rule-based classification engine that categorizes users into 6 behavioral types
3. Build 6 distinct, personalized UI layouts that automatically switch based on user classification
4. Implement real-time UI updates via WebSocket when user type changes

### Secondary Objectives
5. Create a scalable backend architecture using FastAPI with async support
6. Design the classification system with a pluggable architecture for future ML integration
7. Implement comprehensive analytics tracking for user behavior patterns
8. Build a responsive Flutter mobile application with smooth UI transitions

---

## 4. Innovation & Novelty

### What Makes This Project Unique

| Aspect | Traditional E-Commerce | Our Approach |
|--------|----------------------|--------------|
| UI Layout | Static, same for all users | 6 distinct layouts that auto-switch |
| Personalization | Product recommendations only | Entire UI transformation |
| Classification | None or simple segmentation | Multi-dimensional behavioral scoring |
| Real-time Updates | None | WebSocket-based instant UI changes |
| Theme Adaptation | Single theme | Per-user-type color themes and accents |
| Upgrade Path | Fixed algorithms | Pluggable classifier (rule-based → ML) |

### The 6 User Types and Their UI Layouts

1. **Exploration Type** - Category browsers who explore before buying
   - UI: Category grid, trending products, discovery-focused layout
   
2. **Brand Type** - Brand-loyal shoppers who prefer specific brands
   - UI: Brand slider, brand banners, brand-focused product display
   
3. **Price Type** - Budget-conscious shoppers seeking deals
   - UI: Price comparison layout, savings calculator, cheapest-first sorting
   
4. **Interaction Type** - Highly engaged users with frequent interactions
   - UI: Quick actions, rapid add-to-cart, activity-driven recommendations
   
5. **Offer Type** - Deal hunters who respond to discounts
   - UI: Flash sale countdown, deal banners, urgency indicators, coupon highlights
   
6. **Premium Type** - High-value luxury shoppers
   - UI: Dark luxury theme, gold accents, exclusive collection, elegant minimal design

---

## 5. System Architecture

### High-Level Architecture

```
┌──────────────────────────────────────────────────────┐
│                  Flutter Mobile App                   │
│  ┌─────────────────────────────────────────────────┐ │
│  │            Dynamic UI Loader                     │ │
│  │  ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌────┐│ │
│  │  │Explor││Brand ││Price ││Inter ││Offer ││Prem││ │
│  │  │ation ││ Home ││ Home ││action││ Home ││ium ││ │
│  │  └──────┘└──────┘└──────┘└──────┘└──────┘└────┘│ │
│  └─────────────────────────────────────────────────┘ │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Riverpod │  │  HTTP     │  │   WebSocket      │   │
│  │ State    │  │  Client   │  │   Client         │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
└──────────────────────────────────────────────────────┘
                        │                    │
                        ▼                    ▼
┌──────────────────────────────────────────────────────┐
│                  FastAPI Backend                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Auth API │  │ Products │  │  Behavior API    │   │
│  │          │  │ API      │  │                  │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Order    │  │WebSocket │  │  Classification  │   │
│  │ API      │  │ Manager  │  │  Engine          │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│                       │                              │
│              ┌────────▼─────────┐                    │
│              │  Service Layer   │                    │
│              └────────┬─────────┘                    │
│              ┌────────▼─────────┐                    │
│              │  SQLAlchemy ORM  │                    │
│              └────────┬─────────┘                    │
└───────────────────────┼──────────────────────────────┘
                        │
               ┌────────▼─────────┐
               │   PostgreSQL     │
               │   Database       │
               └──────────────────┘
```

### Classification Flow

```
User Action → Track Behavior API → Database Storage
                                         │
                                    ┌────▼────┐
                                    │ Check    │
                                    │ Cooldown │
                                    └────┬────┘
                                         │ (if eligible)
                                    ┌────▼────────────┐
                                    │ Compute Metrics  │
                                    │ (from raw data)  │
                                    └────┬────────────┘
                                         │
                                    ┌────▼────────────┐
                                    │ Score 6 Types    │
                                    │ (weighted)       │
                                    └────┬────────────┘
                                         │
                                    ┌────▼────────────┐
                                    │ Assign Top Type  │
                                    │ with Confidence  │
                                    └────┬────────────┘
                                         │
                             ┌───────────▼───────────┐
                             │ WebSocket Notification │
                             │ → Flutter UI Rebuild   │
                             └───────────────────────┘
```

---

## 6. Technology Stack

### Backend
| Technology | Purpose |
|-----------|---------|
| Python 3.10+ | Programming Language |
| FastAPI | Web Framework (async) |
| SQLAlchemy 2.0 | ORM (async with asyncpg) |
| PostgreSQL | Database |
| python-jose | JWT Token Authentication |
| bcrypt/passlib | Password Hashing |
| WebSocket (native) | Real-time Communication |
| Pydantic v2 | Data Validation |
| Alembic | Database Migrations |

### Frontend
| Technology | Purpose |
|-----------|---------|
| Flutter 3.x | Cross-platform Mobile Framework |
| Dart | Programming Language |
| Riverpod | State Management |
| GoRouter | Navigation/Routing |
| web_socket_channel | WebSocket Client |
| http | HTTP Client |
| shared_preferences | Local Storage |
| cached_network_image | Image Caching |

---

## 7. Database Design

### Tables (13 total)

1. **users** - User accounts with current_user_type
2. **categories** - Product categories with icons
3. **brands** - Brand information with logos
4. **products** - Product catalog with pricing, images, tags
5. **user_behaviors** - Tracked user actions (17 behavior types)
6. **search_history** - User search queries with click tracking
7. **product_views** - Product page visits with time spent
8. **cart_items** - Shopping cart contents
9. **wishlist_items** - Saved/wishlist products
10. **orders** - Purchase orders with payment info
11. **order_items** - Individual items within orders
12. **user_type_history** - Classification change history
13. **user_analytics** - Aggregated analytics with 60+ metrics

### Key Relationships
- User → Behaviors (1:N)
- User → Orders (1:N)
- User → CartItems (1:N)
- User → WishlistItems (1:N)
- User → ProductViews (1:N)
- Order → OrderItems (1:N)
- Product → Category (N:1)
- Product → Brand (N:1)

---

## 8. Classification Algorithm

### Weighted Scoring System

The rule-based classifier computes scores for each of the 6 user types:

```
Score_exploration = w1 * category_diversity + w2 * browse_to_buy_ratio + w3 * unique_products_viewed
Score_brand      = w1 * brand_concentration + w2 * brand_repeat_rate + w3 * brand_filter_usage
Score_price      = w1 * price_filter_usage + w2 * discount_preference + w3 * budget_avg_order
Score_interaction = w1 * session_frequency + w2 * actions_per_session + w3 * feature_usage_depth
Score_offer      = w1 * coupon_usage_rate + w2 * sale_purchase_ratio + w3 * deal_page_visits
Score_premium    = w1 * avg_order_value + w2 * premium_product_ratio + w3 * review_engagement
```

The type with the highest score is assigned. Confidence = max_score / sum_of_all_scores.

### Behavior Types Tracked (17 total)
- product_view, search, add_to_cart, remove_from_cart
- wishlist_add, wishlist_remove, purchase, review
- share, compare, filter_use, sort_use
- category_browse, brand_browse, deal_view, coupon_apply
- price_alert_set

---

## 9. API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/auth/register | Register new user |
| POST | /api/v1/auth/login | Login and get JWT |
| GET | /api/v1/auth/me | Get current user profile |
| GET | /api/v1/auth/user-type | Get user classification |
| POST | /api/v1/auth/reclassify | Force reclassification |

### Products
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/products/ | List with filters/pagination |
| GET | /api/v1/products/personalized | User-type-specific products |
| GET | /api/v1/products/categories | List categories |
| GET | /api/v1/products/brands | List brands |
| GET | /api/v1/products/{id} | Product details |

### Behavior Tracking
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/behavior/track | Track single behavior |
| POST | /api/v1/behavior/track/batch | Track multiple behaviors |
| POST | /api/v1/behavior/product-view | Record product view |
| POST | /api/v1/behavior/search | Record search query |
| GET | /api/v1/behavior/analytics | Get user analytics |

### Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/orders/cart | Get cart |
| POST | /api/v1/orders/cart | Add to cart |
| DELETE | /api/v1/orders/cart/{id} | Remove from cart |
| GET | /api/v1/orders/wishlist | Get wishlist |
| POST | /api/v1/orders/ | Create order |
| GET | /api/v1/orders/ | List orders |

### WebSocket
| Endpoint | Description |
|----------|-------------|
| /ws/{user_id}?token=JWT | Real-time connection |

---

## 10. Key Features Implemented

1. **Dynamic UI Personalization** - 6 distinct layouts that auto-switch
2. **Real-time Classification** - WebSocket-based instant updates
3. **Behavior Tracking** - 17 different action types tracked
4. **Weighted Scoring** - Multi-dimensional classification algorithm
5. **Animated Transitions** - Smooth fade+slide when UI changes
6. **JWT Authentication** - Secure token-based auth
7. **Theme Adaptation** - Colors change per user type
8. **Product Personalization** - Different query strategies per type
9. **Session Persistence** - Login state saved locally
10. **Async Architecture** - Non-blocking I/O throughout

---

## 11. Comparison with Existing Systems

| Feature | Amazon | Netflix | Flipkart | **Our System** |
|---------|--------|---------|----------|----------------|
| Product Recommendations | ✅ | - | ✅ | ✅ |
| Content-based Filtering | ✅ | ✅ | ✅ | ✅ |
| UI Layout Personalization | ❌ | ❌ | ❌ | **✅** |
| Real-time UI Switching | ❌ | ❌ | ❌ | **✅** |
| Behavioral Classification | Partial | ✅ | Partial | **✅ (6 types)** |
| Complete Theme Adaptation | ❌ | ❌ | ❌ | **✅** |
| Open Source | ❌ | ❌ | ❌ | **✅** |

---

## 12. Advantages

1. **Improved User Experience** - Each user sees an interface optimized for their behavior
2. **Higher Engagement** - Relevant features are prominently displayed
3. **Increased Conversions** - Price-sensitive users see deals; premium users see luxury
4. **Real-time Adaptation** - UI changes as user behavior evolves
5. **Scalable Architecture** - ML-ready with pluggable classifier design
6. **Cross-platform** - Flutter enables iOS, Android, and web from single codebase
7. **Async Performance** - Non-blocking architecture handles concurrent users

---

## 13. Challenges & Limitations

1. **Cold Start Problem** - New users default to Exploration type until enough data
2. **Classification Accuracy** - Rule-based scoring may not capture complex patterns
3. **Data Privacy** - Extensive behavior tracking requires transparent consent
4. **Performance at Scale** - Real-time reclassification adds database load
5. **UI Consistency** - Users may notice layout changes during sessions

### Mitigations
- Configurable reclassification cooldown prevents excessive recalculation
- ML classifier placeholder ready for upgrade with real training data
- Classification history tracked for audit and rollback capability

---

## 14. Future Scope

1. **ML-Based Classification** - Replace rule-based engine with trained ML models
2. **A/B Testing Framework** - Compare personalized vs. generic UI effectiveness
3. **Collaborative Filtering** - "Users like you also..." recommendations
4. **NLP Search Enhancement** - Natural language product search
5. **Voice-Based Shopping** - Voice commands for frequent buyers
6. **AR Product Preview** - Augmented reality for premium users
7. **Multi-language Support** - Internationalization based on user region
8. **Admin Dashboard** - Real-time analytics and user segment management
9. **Push Notifications** - Personalized notifications per user type
10. **Social Commerce** - Social sharing and community features

---

## 15. How to Run

### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
pip install -r requirements.txt
# Create .env from .env.example and set database URL
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
# Seed database: python -m app.seed
```

### Frontend Setup
```bash
cd frontend/ecommerce_app
flutter pub get
flutter run
```

### Environment Variables
```
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/ecommerce
SECRET_KEY=your-secret-key
```

---

## 16. Viva Preparation - Key Points

### Q: What is the main contribution of this project?
**A:** We introduce Multi-UI Personalization - dynamically transforming the entire e-commerce interface based on user behavioral classification, going beyond traditional product recommendations by changing the complete layout, sections, themes, and feature emphasis.

### Q: How does classification work?
**A:** We track 17 types of user behaviors and compute weighted scores across 6 dimensions (exploration, brand, price, interaction, offer, premium). The dimension with the highest score determines the user type, and a confidence metric (max_score / total_scores) indicates classification certainty.

### Q: Why 6 user types?
**A:** Based on e-commerce research, shoppers primarily exhibit 6 distinct behavioral patterns: category explorers, brand loyalists, price-sensitive buyers, highly engaged interactors, deal seekers, and premium purchasers. Each has fundamentally different UI needs.

### Q: How is this different from Amazon's recommendations?
**A:** Amazon recommends products but keeps the same UI layout for everyone. Our system changes the ENTIRE home page structure - a premium user sees an elegant dark theme with exclusive collection cards, while a price user sees comparison layouts with savings calculators.

### Q: Why not use ML from the start?
**A:** The rule-based approach provides explainable, immediate results without training data. The architecture uses an abstract `BaseClassifier` interface with a factory pattern, so swapping to ML requires only implementing the interface - no other code changes.

### Q: How do real-time updates work?
**A:** WebSocket connections maintain persistent links between the Flutter app and FastAPI server. When a user's type changes (e.g., after a purchase), the server broadcasts the update through WebSocket, Riverpod detects the state change, and `AnimatedSwitcher` smoothly transitions to the new UI layout.

---

## 17. Resume Description

> **Enhancing E-Commerce Websites with Multi-UI Personalization Based on User Actions and Order Data**
> 
> Designed and built a full-stack e-commerce platform (FastAPI + Flutter) that dynamically personalizes the entire UI based on real-time user behavior analysis. Implemented a weighted scoring classification engine that categorizes users into 6 behavioral types (Exploration, Brand, Price, Interaction, Offer, Premium) and renders distinct personalized layouts via WebSocket-driven updates. Tracked 17 behavior types across 60+ analytics metrics, achieving real-time UI adaptation with smooth animated transitions. Built with pluggable ML-ready architecture using abstract classifier interfaces and factory patterns.
> 
> **Tech:** Python, FastAPI, PostgreSQL, SQLAlchemy (async), JWT, WebSocket, Flutter, Riverpod, GoRouter

---

*Project by: [Your Name]*
*Institution: [Your Institution]*
*Year: 2024-2025*
