"""
BikeIstanbul – Ana FastAPI Uygulama Giriş Noktası
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api.routes import auth, bikes, stations, trips, payments, emergency, admin
from app.core.config import settings
from app.db.session import engine
from app.db import base  # noqa: F401 – tüm modelleri yükle


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Başlangıç: MQTT bağlantısını kur
    from app.services.mqtt_service import MqttClient
    mqtt = MqttClient.get_instance()
    mqtt.connect()
    yield
    # Kapatma: bağlantıları temizle
    mqtt.disconnect()


app = FastAPI(
    title="BikeIstanbul API",
    description="Akıllı Bisiklet Paylaşım ve Ulaşım Entegrasyon Platformu",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,      prefix="/api/v1/auth",       tags=["Auth"])
app.include_router(bikes.router,     prefix="/api/v1/bikes",      tags=["Bikes"])
app.include_router(stations.router,  prefix="/api/v1/stations",   tags=["Stations"])
app.include_router(trips.router,     prefix="/api/v1/trips",      tags=["Trips"])
app.include_router(payments.router,  prefix="/api/v1/payments",   tags=["Payments"])
app.include_router(emergency.router, prefix="/api/v1/emergency",  tags=["Emergency"])
app.include_router(admin.router,     prefix="/api/v1/admin",      tags=["Admin"])


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy", "service": "BikeIstanbul API"}
