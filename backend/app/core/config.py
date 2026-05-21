"""
Uygulama Konfigürasyonu – Ortam Değişkenleri
"""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # Uygulama
    APP_NAME: str = "BikeIstanbul"
    DEBUG: bool = False
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 saat

    # Veritabanı
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost:5432/bikeistanbul"

    # MQTT
    MQTT_BROKER_HOST: str = "localhost"
    MQTT_BROKER_PORT: int = 1883
    MQTT_USERNAME: str = ""
    MQTT_PASSWORD: str = ""

    # Dış Servisler
    GOOGLE_MAPS_API_KEY: str = ""
    IYZICO_API_KEY: str = ""
    IYZICO_SECRET_KEY: str = ""
    IBB_API_BASE_URL: str = "https://api.ibb.gov.tr"

    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]

    # İş Mantığı Sabitleri
    PRICE_PER_MINUTE: float = 0.50       # TL
    CO2_SAVING_PER_KM: float = 0.21      # kg CO2
    CALORIES_PER_KM: float = 30.0        # kcal
    NEARBY_RADIUS_METERS: int = 500
    STEEP_SLOPE_THRESHOLD: float = 15.0  # %15 eğim uyarısı

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
