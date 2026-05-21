"""
Yolculuk Servisi – Kiralama İş Mantığı (Clean Code Prensipleri ile)
"""
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
from app.models.models import Bike, BikeStatus, Trip, TripStatus
from app.services.mqtt_service import MqttClient
from app.services.reward_service import RewardService
from app.services.payment_service import PaymentService
from app.services.route_service import RouteService


class TripService:
    """Bisiklet kiralama yaşam döngüsünü yöneten servis sınıfı."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.mqtt = MqttClient.get_instance()
        self.reward_service = RewardService(db)
        self.payment_service = PaymentService(db)
        self.route_service = RouteService(db)

    # ── Kiralama Başlatma ──────────────────────────────────────────────────────

    async def start_rental(self, user_id: UUID, bike_id: UUID) -> Trip:
        bike = await self._get_bike_or_raise(bike_id)
        self._ensure_bike_is_available(bike)

        trip = Trip(user_id=user_id, bike_id=bike_id, start_time=datetime.now(timezone.utc))
        bike.status = BikeStatus.RENTED

        self.db.add(trip)
        await self.db.commit()
        await self.db.refresh(trip)

        self.mqtt.publish_command(str(bike_id), {
            "command": "UNLOCK",
            "tripId": str(trip.id),
            "userId": str(user_id),
        })
        return trip

    # ── Yolculuk Sonlandırma ───────────────────────────────────────────────────

    async def end_trip(self, trip_id: UUID, end_station_id: Optional[UUID] = None) -> Trip:
        trip = await self._get_active_trip_or_raise(trip_id)

        trip.end_time        = datetime.now(timezone.utc)
        trip.status          = TripStatus.COMPLETED
        trip.end_station_id  = end_station_id
        trip.distance_km     = await self._calculate_route_distance(trip)
        trip.carbon_saving_kg = self.calculate_carbon_saving(trip.distance_km)
        trip.calories_burned  = self.calculate_calories(trip.distance_km)
        trip.transfer_suggestion = await self.route_service.build_transfer_suggestion(end_station_id)

        trip.bike.status = BikeStatus.AVAILABLE

        await self.db.commit()
        await self.db.refresh(trip)

        await self.payment_service.create_or_update_payment(trip)
        await self.reward_service.grant_trip_rewards(trip)
        return trip

    # ── Hesaplamalar (Tek Sorumluluk) ──────────────────────────────────────────

    def calculate_trip_cost(self, trip: Trip) -> float:
        """Yolculuk süresine göre ücreti hesaplar."""
        duration_minutes = self._get_duration_in_minutes(trip)
        return round(duration_minutes * settings.PRICE_PER_MINUTE, 2)

    def calculate_carbon_saving(self, distance_km: float) -> float:
        """Kat edilen mesafeye göre CO₂ tasarrufunu hesaplar (kg)."""
        return round(distance_km * settings.CO2_SAVING_PER_KM, 3)

    def calculate_calories(self, distance_km: float) -> float:
        """Bisiklet ile yakılan kaloriyi hesaplar (kcal)."""
        return round(distance_km * settings.CALORIES_PER_KM, 1)

    # ── Yardımcı Metotlar ──────────────────────────────────────────────────────

    def _get_duration_in_minutes(self, trip: Trip) -> float:
        end = trip.end_time or datetime.now(timezone.utc)
        delta = end - trip.start_time
        return delta.total_seconds() / 60

    def _ensure_bike_is_available(self, bike: Bike) -> None:
        if bike.status != BikeStatus.AVAILABLE:
            raise ValueError(f"Bisiklet müsait değil. Mevcut durum: {bike.status.value}")

    async def _get_bike_or_raise(self, bike_id: UUID) -> Bike:
        result = await self.db.execute(select(Bike).where(Bike.id == bike_id))
        bike = result.scalar_one_or_none()
        if bike is None:
            raise ValueError(f"Bisiklet bulunamadı: {bike_id}")
        return bike

    async def _get_active_trip_or_raise(self, trip_id: UUID) -> Trip:
        result = await self.db.execute(
            select(Trip).where(Trip.id == trip_id, Trip.status == TripStatus.ACTIVE)
        )
        trip = result.scalar_one_or_none()
        if trip is None:
            raise ValueError(f"Aktif yolculuk bulunamadı: {trip_id}")
        return trip

    async def _calculate_route_distance(self, trip: Trip) -> float:
        """GPS verilerinden rota mesafesini hesaplar (km). Şimdilik tahmini değer döner."""
        # TODO: GPS log tablosundan gerçek rota hesaplaması
        return 3.5
