"""
Core configuration for the application.
Loads environment variables and defines app-wide settings.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional
import os


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "E-Commerce Personalization API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    API_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/ecommerce_personalized"
    DATABASE_URL_SYNC: str = "postgresql://postgres:postgres@localhost:5432/ecommerce_personalized"

    # JWT Authentication
    SECRET_KEY: str = "your-super-secret-key-change-in-production-min-32-chars"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    # CORS
    ALLOWED_ORIGINS: list = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
    ]

    # Classification Thresholds
    BRAND_VIEW_THRESHOLD: int = 5
    PRICE_FILTER_THRESHOLD: int = 3
    INTERACTION_VIEW_THRESHOLD: int = 20
    OFFER_CLICK_THRESHOLD: int = 5
    PREMIUM_AVG_ORDER_THRESHOLD: float = 5000.0
    RECLASSIFICATION_INTERVAL_MINUTES: int = 30

    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    # Redis (optional)
    REDIS_URL: Optional[str] = None

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)


settings = Settings()
