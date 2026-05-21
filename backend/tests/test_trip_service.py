"""
Birim Testleri – TripService (pytest)
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from app.models.models import Bike, BikeStatus, Trip, TripStatus
from app.services.trip_service import TripService


# ── Fikstürler ────────────────────────────────────────────────────────────────

@pytest.fixture
def mock_db():
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.add = MagicMock()
    return db


@pytest.fixture
def available_bike():
    bike = Bike()
    bike.id = uuid4()
    bike.serial_number = "BIKE-001"
    bike.status = BikeStatus.AVAILABLE
    bike.battery_level = 85
    return bike


@pytest.fixture
def rented_bike():
    bike = Bike()
    bike.id = uuid4()
    bike.serial_number = "BIKE-002"
    bike.status = BikeStatus.RENTED
    return bike


@pytest.fixture
def completed_trip():
    trip = Trip()
    trip.id = uuid4()
    trip.start_time = datetime.now(timezone.utc) - timedelta(minutes=25)
    trip.end_time = datetime.now(timezone.utc)
    trip.distance_km = 5.0
    return trip


# ── Kiralama Başlatma Testleri ─────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_start_rental_with_available_bike(mock_db, available_bike):
    """Müsait bisikletle kiralama başarıyla başlamalı."""
    with patch.object(TripService, "_get_bike_or_raise", return_value=available_bike), \
         patch("app.services.trip_service.MqttClient") as mock_mqtt:
        mock_mqtt.get_instance.return_value.publish_command = MagicMock()

        service = TripService(mock_db)
        trip = await service.start_rental(user_id=uuid4(), bike_id=available_bike.id)

        assert trip is not None
        assert available_bike.status == BikeStatus.RENTED
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()


@pytest.mark.asyncio
async def test_start_rental_with_unavailable_bike(mock_db, rented_bike):
    """Kiralanmış bisikletle kiralama ValueError fırlatmalı."""
    with patch.object(TripService, "_get_bike_or_raise", return_value=rented_bike):
        service = TripService(mock_db)
        with pytest.raises(ValueError, match="Bisiklet müsait değil"):
            await service.start_rental(user_id=uuid4(), bike_id=rented_bike.id)


# ── Maliyet Hesaplama Testleri ─────────────────────────────────────────────────

def test_calculate_trip_cost_25_minutes(completed_trip):
    """25 dakikalık yolculuk 12.50 TL olmalı (0.50 TL/dk)."""
    service = TripService(MagicMock())
    cost = service.calculate_trip_cost(completed_trip)
    assert cost == pytest.approx(12.50, abs=0.5)


def test_calculate_trip_cost_zero_duration():
    """Sıfır süreli yolculuk sıfır maliyet döndürmeli."""
    now = datetime.now(timezone.utc)
    trip = Trip()
    trip.start_time = now
    trip.end_time = now
    service = TripService(MagicMock())
    assert service.calculate_trip_cost(trip) == 0.0


# ── Karbon Tasarrufu Testleri ──────────────────────────────────────────────────

def test_calculate_carbon_saving():
    """10 km için 2.1 kg CO₂ tasarrufu hesaplanmalı."""
    service = TripService(MagicMock())
    saving = service.calculate_carbon_saving(10.0)
    assert saving == pytest.approx(2.1, abs=0.01)


def test_calculate_calories():
    """5 km için 150 kcal hesaplanmalı."""
    service = TripService(MagicMock())
    calories = service.calculate_calories(5.0)
    assert calories == pytest.approx(150.0, abs=0.1)


# ── Acil Durum Testleri ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_emergency_handler_marks_bikes_available(mock_db):
    """Deprem handler'ı kiralanmış bisikletleri müsait yapmalı."""
    from app.services.emergency_service import LockReleaseHandler

    mock_db.execute = AsyncMock(return_value=MagicMock(scalars=MagicMock(return_value=MagicMock(all=lambda: [uuid4(), uuid4()]))))

    with patch("app.services.emergency_service.MqttClient") as mock_mqtt:
        mock_mqtt.get_instance.return_value.publish_command = MagicMock()
        handler = LockReleaseHandler()
        await handler.on_emergency(magnitude=5.5, db=mock_db)
        assert mock_mqtt.get_instance.return_value.publish_command.call_count == 2
