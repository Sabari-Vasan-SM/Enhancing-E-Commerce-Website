# Enhancing E-Commerce Websites with Multi-UI Personalization

## Based on User Actions and Order Data

A dynamic e-commerce platform where the UI automatically changes based on user behavior and order history.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Web + Mobile) |
| Backend | FastAPI (Python) |
| Database | PostgreSQL |
| State Management | Riverpod |
| Future ML | Scikit-learn / TensorFlow |
| Auth | JWT (JSON Web Tokens) |
| Real-time | WebSockets |

---

## Project Structure

```
├── backend/                  # FastAPI Backend
│   ├── app/
│   │   ├── api/              # API route handlers
│   │   ├── core/             # Config, security, dependencies
│   │   ├── models/           # SQLAlchemy ORM models
│   │   ├── schemas/          # Pydantic validation schemas
│   │   ├── services/         # Business logic layer
│   │   ├── classification/   # User classification engine
│   │   ├── ml/               # Future ML models
│   │   └── websocket/        # WebSocket handlers
│   ├── migrations/           # Alembic DB migrations
│   ├── tests/                # Backend tests
│   └── requirements.txt
│
├── frontend/                 # Flutter App
│   └── ecommerce_app/
│       └── lib/
│           ├── core/         # Theme, constants, utils
│           ├── models/       # Data models
│           ├── providers/    # Riverpod providers
│           ├── services/     # API & WebSocket services
│           ├── ui/           # Personalized UI layouts
│           │   ├── exploration/
│           │   ├── brand/
│           │   ├── price/
│           │   ├── interaction/
│           │   ├── offer/
│           │   ├── premium/
│           │   └── shared/   # Shared widgets
│           └── router/       # Navigation
│
├── database/                 # SQL scripts & ER diagrams
├── docs/                     # Project documentation
└── ml_pipeline/              # Future ML pipeline
```

---

## Quick Start

### Backend
```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend/ecommerce_app
flutter pub get
flutter run -d chrome         # Web
flutter run                    # Mobile
```

### Database
```bash
# Create PostgreSQL database
psql -U postgres -c "CREATE DATABASE ecommerce_personalized;"
# Run migrations
cd backend
alembic upgrade head
```

---

## Architecture Overview

```
┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│   Flutter     │────▶│   FastAPI         │────▶│  PostgreSQL    │
│   Frontend    │◀────│   Backend         │◀────│  Database      │
│              │     │                  │     │                │
│  - Riverpod  │     │  - JWT Auth      │     │  - Users       │
│  - Dynamic UI│     │  - Classification │     │  - Products    │
│  - WebSocket │     │  - WebSocket     │     │  - Behavior    │
│  - Themes    │     │  - REST APIs     │     │  - Orders      │
└──────────────┘     └──────────────────┘     └────────────────┘
                              │
                     ┌────────┴────────┐
                     │   ML Pipeline   │
                     │  (Future)       │
                     │  - Clustering   │
                     │  - Training     │
                     │  - Inference    │
                     └─────────────────┘
```

---

## User Classification Types

| Type | Description | Key Behaviors |
|------|------------|---------------|
| Exploration | New/browsing users | Category browsing, no strong preference |
| Brand | Brand loyal users | Frequent brand views, brand filter usage |
| Price | Budget shoppers | Price filter usage, "cheap" searches |
| Interaction | Highly active users | Many views, frequent cart additions |
| Offer | Deal hunters | Sale searches, discount clicks |
| Premium | High spenders | Expensive product views, high-value purchases |

---

## License

This project is part of an academic final year project.
