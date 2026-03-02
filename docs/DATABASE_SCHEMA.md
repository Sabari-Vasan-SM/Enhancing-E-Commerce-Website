# Database Schema - SQL Scripts & ER Documentation

## Entity Relationship Overview

```
┌──────────┐       ┌────────────┐       ┌──────────┐
│  users   │───1:N─│  orders    │───1:N─│order_items│
└────┬─────┘       └────────────┘       └─────┬────┘
     │                                        │
     │1:N    ┌──────────────┐                 │N:1
     ├──────▸│user_behaviors│           ┌─────▼────┐
     │       └──────────────┘     ┌─────│ products │──N:1──┐
     │1:N    ┌──────────────┐     │     └─────┬────┘      │
     ├──────▸│search_history│     │           │            │
     │       └──────────────┘     │           │N:1    ┌────▼─────┐
     │1:N    ┌──────────────┐     │     ┌─────▼────┐  │  brands  │
     ├──────▸│product_views │─N:1─┘     │categories│  └──────────┘
     │       └──────────────┘           └──────────┘
     │1:N    ┌──────────────┐
     ├──────▸│ cart_items   │───N:1──▸ products
     │       └──────────────┘
     │1:N    ┌──────────────┐
     ├──────▸│wishlist_items│───N:1──▸ products
     │       └──────────────┘
     │1:N    ┌───────────────────┐
     ├──────▸│user_type_history  │
     │       └───────────────────┘
     │1:1    ┌───────────────────┐
     └──────▸│ user_analytics    │
             └───────────────────┘
```

---

## SQL CREATE TABLE Scripts

### 1. users
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    current_user_type VARCHAR(20) DEFAULT 'exploration',
    user_type_confidence FLOAT DEFAULT 0.0,
    last_classification_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Enum constraint
ALTER TABLE users ADD CONSTRAINT chk_user_type 
    CHECK (current_user_type IN ('exploration', 'brand', 'price', 'interaction', 'offer', 'premium'));

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_type ON users(current_user_type);
```

### 2. categories
```sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 3. brands
```sql
CREATE TABLE brands (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    logo_url VARCHAR(500),
    is_premium BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 4. products
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    discount_percentage FLOAT DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0,
    category_id INTEGER REFERENCES categories(id),
    brand_id INTEGER REFERENCES brands(id),
    images JSON DEFAULT '[]',
    tags JSON DEFAULT '[]',
    specifications JSON DEFAULT '{}',
    rating FLOAT DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    is_premium BOOLEAN DEFAULT FALSE,
    is_on_sale BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_featured ON products(is_featured);
CREATE INDEX idx_products_premium ON products(is_premium);
CREATE INDEX idx_products_sale ON products(is_on_sale);
```

### 5. user_behaviors
```sql
CREATE TABLE user_behaviors (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    behavior_type VARCHAR(30) NOT NULL,
    product_id INTEGER REFERENCES products(id),
    category_id INTEGER REFERENCES categories(id),
    brand_id INTEGER REFERENCES brands(id),
    metadata JSON DEFAULT '{}',
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Enum constraint for behavior types
ALTER TABLE user_behaviors ADD CONSTRAINT chk_behavior_type
    CHECK (behavior_type IN (
        'product_view', 'search', 'add_to_cart', 'remove_from_cart',
        'wishlist_add', 'wishlist_remove', 'purchase', 'review',
        'share', 'compare', 'filter_use', 'sort_use',
        'category_browse', 'brand_browse', 'deal_view',
        'coupon_apply', 'price_alert_set'
    ));

CREATE INDEX idx_behaviors_user ON user_behaviors(user_id);
CREATE INDEX idx_behaviors_type ON user_behaviors(behavior_type);
CREATE INDEX idx_behaviors_created ON user_behaviors(created_at);
CREATE INDEX idx_behaviors_user_type ON user_behaviors(user_id, behavior_type);
```

### 6. search_history
```sql
CREATE TABLE search_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    query VARCHAR(500) NOT NULL,
    results_count INTEGER DEFAULT 0,
    clicked_product_id INTEGER REFERENCES products(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_search_user ON search_history(user_id);
CREATE INDEX idx_search_created ON search_history(created_at);
```

### 7. product_views
```sql
CREATE TABLE product_views (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    duration_seconds INTEGER DEFAULT 0,
    source VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_views_user ON product_views(user_id);
CREATE INDEX idx_views_product ON product_views(product_id);
CREATE INDEX idx_views_user_product ON product_views(user_id, product_id);
```

### 8. cart_items
```sql
CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

CREATE INDEX idx_cart_user ON cart_items(user_id);
```

### 9. wishlist_items
```sql
CREATE TABLE wishlist_items (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

CREATE INDEX idx_wishlist_user ON wishlist_items(user_id);
```

### 10. orders
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_amount DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    shipping_amount DECIMAL(10,2) DEFAULT 0,
    final_amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payment_method VARCHAR(20) DEFAULT 'cod',
    shipping_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE orders ADD CONSTRAINT chk_order_status
    CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned'));

ALTER TABLE orders ADD CONSTRAINT chk_payment_method
    CHECK (payment_method IN ('cod', 'upi', 'card', 'net_banking', 'wallet'));

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at);
```

### 11. order_items
```sql
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
```

### 12. user_type_history
```sql
CREATE TABLE user_type_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    previous_type VARCHAR(20),
    new_type VARCHAR(20) NOT NULL,
    confidence FLOAT DEFAULT 0.0,
    scores JSON DEFAULT '{}',
    trigger VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_type_history_user ON user_type_history(user_id);
CREATE INDEX idx_type_history_created ON user_type_history(created_at);
```

### 13. user_analytics
```sql
CREATE TABLE user_analytics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Browsing Metrics
    total_product_views INTEGER DEFAULT 0,
    unique_products_viewed INTEGER DEFAULT 0,
    avg_view_duration FLOAT DEFAULT 0,
    total_searches INTEGER DEFAULT 0,
    total_categories_browsed INTEGER DEFAULT 0,
    total_brands_browsed INTEGER DEFAULT 0,
    
    -- Cart & Wishlist
    total_cart_additions INTEGER DEFAULT 0,
    total_cart_removals INTEGER DEFAULT 0,
    total_wishlist_additions INTEGER DEFAULT 0,
    cart_to_purchase_rate FLOAT DEFAULT 0,
    
    -- Purchase Metrics
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    avg_order_value DECIMAL(10,2) DEFAULT 0,
    max_order_value DECIMAL(10,2) DEFAULT 0,
    
    -- Engagement Metrics
    total_reviews INTEGER DEFAULT 0,
    total_shares INTEGER DEFAULT 0,
    total_comparisons INTEGER DEFAULT 0,
    total_filter_uses INTEGER DEFAULT 0,
    total_sort_uses INTEGER DEFAULT 0,
    
    -- Discount Metrics
    total_coupon_applies INTEGER DEFAULT 0,
    total_deal_views INTEGER DEFAULT 0,
    discount_purchase_ratio FLOAT DEFAULT 0,
    
    -- Premium Metrics
    premium_product_ratio FLOAT DEFAULT 0,
    avg_product_price_viewed DECIMAL(10,2) DEFAULT 0,
    
    -- Classification Scores
    exploration_score FLOAT DEFAULT 0,
    brand_score FLOAT DEFAULT 0,
    price_score FLOAT DEFAULT 0,
    interaction_score FLOAT DEFAULT 0,
    offer_score FLOAT DEFAULT 0,
    premium_score FLOAT DEFAULT 0,
    
    -- Session Data
    total_sessions INTEGER DEFAULT 0,
    avg_session_duration FLOAT DEFAULT 0,
    last_active_at TIMESTAMP,
    
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_user ON user_analytics(user_id);
```

---

## Performance Optimization Queries

### Fast user type lookup
```sql
-- Indexed lookup for classification
SELECT current_user_type, user_type_confidence 
FROM users WHERE id = $1;
```

### Recent behaviors for classification
```sql
-- Get behavior counts by type (last 30 days)
SELECT behavior_type, COUNT(*) as count
FROM user_behaviors
WHERE user_id = $1 AND created_at > NOW() - INTERVAL '30 days'
GROUP BY behavior_type;
```

### Top brands for brand-type users
```sql
-- Brand concentration metric
SELECT b.name, COUNT(*) as views
FROM user_behaviors ub
JOIN products p ON ub.product_id = p.id
JOIN brands b ON p.brand_id = b.id
WHERE ub.user_id = $1 AND ub.behavior_type = 'product_view'
GROUP BY b.name
ORDER BY views DESC
LIMIT 5;
```

### Price sensitivity metric
```sql
-- Average viewed price vs purchased price
SELECT 
    AVG(p.price) as avg_viewed_price,
    (SELECT AVG(oi.unit_price) FROM order_items oi 
     JOIN orders o ON oi.order_id = o.id WHERE o.user_id = $1) as avg_purchase_price
FROM product_views pv
JOIN products p ON pv.product_id = p.id
WHERE pv.user_id = $1;
```

### Classification distribution
```sql
-- Admin: user type distribution
SELECT current_user_type, COUNT(*) as user_count,
       ROUND(AVG(user_type_confidence)::numeric, 2) as avg_confidence
FROM users
WHERE is_active = TRUE
GROUP BY current_user_type
ORDER BY user_count DESC;
```

---

## Indexes Summary

| Table | Index | Purpose |
|-------|-------|---------|
| users | email | Login lookup |
| users | current_user_type | Type distribution queries |
| products | category_id, brand_id | Filtered listings |
| products | price | Price range queries |
| products | is_featured, is_premium, is_on_sale | Product type filters |
| user_behaviors | (user_id, behavior_type) | Classification queries |
| user_behaviors | created_at | Time-range analysis |
| product_views | (user_id, product_id) | View dedup/counts |
| orders | user_id, status | Order history |
| order_items | product_id | Sales analytics |
