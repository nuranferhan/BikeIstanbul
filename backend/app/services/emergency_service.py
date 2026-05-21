"""
Acil Durum Servisi – Deprem Modu
Observer Deseni: Deprem uyarısı geldiğinde birden fazla servis bağımsız tepki verir.
"""
import logging
from abc import ABC, abstractmethod
from typing import List

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import update

from app.models.models import Bike, BikeStatus, Trip, TripStatus
from app.services.mqtt_service import MqttClient

logger = logging.getLogger(__name__)


# ── Observer Arayüzü ──────────────────────────────────────────────────────────

class EmergencyHandler(ABC):
    """Acil durum olaylarına tepki verecek tüm servisler bu arayüzü uygular."""

    @abstractmethod
    async def on_emergency(self, magnitude: float, db: AsyncSession) -> None: ...


# ── Somut Handler'lar ──────────────────────────────────────────────────────────

class LockReleaseHandler(EmergencyHandler):
    """Depremde tüm bisiklet kilitlerini açar."""

    async def on_emergency(self, magnitude: float, db: AsyncSession) -> None:
        mqtt = MqttClient.get_instance()
        result = await db.execute(
            update(Bike)
            .where(Bike.status == BikeStatus.RENTED)
            .values(status=BikeStatus.AVAILABLE)
            .returning(Bike.id)
        )
        bike_ids = result.scalars().all()

        for bike_id in bike_ids:
            mqtt.publish_command(str(bike_id), {
                "command": "UNLOCK",
                "reason": "EMERGENCY",
                "magnitude": magnitude,
            })
        logger.warning("[ACİL DURUM] %d bisiklet kilidi deprem nedeniyle açıldı (M%.1f)", len(bike_ids), magnitude)


class RentalStopHandler(EmergencyHandler):
    """Depremde tüm aktif kiralamalar iptal edilir ve ücret alınmaz."""

    async def on_emergency(self, magnitude: float, db: AsyncSession) -> None:
        await db.execute(
            update(Trip)
            .where(Trip.status == TripStatus.ACTIVE)
            .values(status=TripStatus.CANCELLED)
        )
        await db.commit()
        logger.warning("[ACİL DURUM] Tüm aktif kiralamalar iptal edildi.")


class NotificationHandler(EmergencyHandler):
    """Kullanıcılara push bildirimi gönderir (FCM entegrasyonu)."""

    async def on_emergency(self, magnitude: float, db: AsyncSession) -> None:
        # TODO: Firebase Cloud Messaging entegrasyonu
        logger.warning("[ACİL DURUM] Push bildirimleri gönderiliyor – M%.1f deprem uyarısı.", magnitude)


# ── Publisher (Observable) ────────────────────────────────────────────────────

class EmergencyEventPublisher:
    """
    AFAD'dan gelen sinyali alır ve tüm kayıtlı handler'ları bilgilendirir.
    Observer Deseni: Publisher, abonelerin kim olduğunu bilmez.
    """

    def __init__(self):
        self._handlers: List[EmergencyHandler] = []

    def subscribe(self, handler: EmergencyHandler) -> None:
        self._handlers.append(handler)

    async def notify_earthquake(self, magnitude: float, db: AsyncSession) -> None:
        logger.critical("[DEPREM UYARISI] Büyüklük: M%.1f – Acil durum protokolü başlatıldı.", magnitude)
        for handler in self._handlers:
            await handler.on_emergency(magnitude, db)


# ── Fabrika: Varsayılan Publisher ─────────────────────────────────────────────

def create_default_emergency_publisher() -> EmergencyEventPublisher:
    publisher = EmergencyEventPublisher()
    publisher.subscribe(LockReleaseHandler())
    publisher.subscribe(RentalStopHandler())
    publisher.subscribe(NotificationHandler())
    return publisher
