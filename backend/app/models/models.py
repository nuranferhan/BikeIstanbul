"""
SQLAlchemy ORM Modelleri – BikeIstanbul Veri Katmanı
"""
import uuid
from datetime import datetime, timezone
from enum import Enum as PyEnum

from sqlalchemy import (
    Boolean, Column, DateTime, Enum, Float, ForeignKey,
    Integer, String, Text
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base_class import Base


def utcnow():
    return datetime.now(timezone.utc)


# ─── Enum Türleri ─────────────────────────────────────────────────────────────

class UserRole(str, PyEnum):
    STANDARD = "standard"
    STUDENT  = "student"
    ADMIN    = "admin"
    STAFF    = "staff"


class BikeStatus(str, PyEnum):
    AVAILABLE  = "available"
    RENTED     = "rented"
    BROKEN     = "broken"
    CHARGING   = "charging"
    RESERVED   = "reserved"


class TripStatus(str, PyEnum):
    ACTIVE    = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PaymentStatus(str, PyEnum):
    PENDING   = "pending"
    COMPLETED = "completed"
    FAILED    = "failed"
    REFUNDED  = "refunded"


class MaintenanceStatus(str, PyEnum):
    OPEN       = "open"
    IN_PROGRESS = "in_progress"
    RESOLVED   = "resolved"


# ─── Modeller ─────────────────────────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name    = Column(String(120), nullable=False)
    email        = Column(String(255), unique=True, nullable=False, index=True)
    phone        = Column(String(20), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role         = Column(Enum(UserRole), default=UserRole.STANDARD, nullable=False)
    points       = Column(Integer, default=0)
    kvkk_consent = Column(Boolean, default=False, nullable=False)
    is_active    = Column(Boolean, default=True)
    created_at   = Column(DateTime(timezone=True), default=utcnow)

    trips    = relationship("Trip", back_populates="user")
    rewards  = relationship("Reward", back_populates="user")


class Station(Base):
    __tablename__ = "stations"

    id                 = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name               = Column(String(120), nullable=False)
    address            = Column(Text)
    latitude           = Column(Float, nullable=False)
    longitude          = Column(Float, nullable=False)
    total_slots        = Column(Integer, default=20)
    available_slots    = Column(Integer, default=0)
    air_quality_index  = Column(Integer, default=50)  # AQI
    is_active          = Column(Boolean, default=True)
    created_at         = Column(DateTime(timezone=True), default=utcnow)

    bikes = relationship("Bike", back_populates="station")


class Bike(Base):
    __tablename__ = "bikes"

    id               = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    serial_number    = Column(String(50), unique=True, nullable=False)
    station_id       = Column(UUID(as_uuid=True), ForeignKey("stations.id"), nullable=True)
    status           = Column(Enum(BikeStatus), default=BikeStatus.AVAILABLE, nullable=False)
    battery_level    = Column(Integer, default=100)   # 0-100 %
    last_maintenance = Column(DateTime(timezone=True))
    latitude         = Column(Float)   # gerçek zamanlı konum
    longitude        = Column(Float)
    created_at       = Column(DateTime(timezone=True), default=utcnow)

    station = relationship("Station", back_populates="bikes")
    trips   = relationship("Trip", back_populates="bike")
    maintenance_records = relationship("MaintenanceRecord", back_populates="bike")


class Trip(Base):
    __tablename__ = "trips"

    id                    = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id               = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    bike_id               = Column(UUID(as_uuid=True), ForeignKey("bikes.id"), nullable=False)
    start_station_id      = Column(UUID(as_uuid=True), ForeignKey("stations.id"))
    end_station_id        = Column(UUID(as_uuid=True), ForeignKey("stations.id"))
    status                = Column(Enum(TripStatus), default=TripStatus.ACTIVE)
    start_time            = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    end_time              = Column(DateTime(timezone=True))
    distance_km           = Column(Float, default=0.0)
    carbon_saving_kg      = Column(Float, default=0.0)
    calories_burned       = Column(Float, default=0.0)
    transfer_suggestion   = Column(Text)   # İETT/Marmaray aktarma önerisi
    created_at            = Column(DateTime(timezone=True), default=utcnow)

    user    = relationship("User", back_populates="trips")
    bike    = relationship("Bike", back_populates="trips")
    payment = relationship("Payment", back_populates="trip", uselist=False)
    rewards = relationship("Reward", back_populates="trip")


class Payment(Base):
    __tablename__ = "payments"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id        = Column(UUID(as_uuid=True), ForeignKey("trips.id"), unique=True, nullable=False)
    amount         = Column(Float, nullable=False)
    status         = Column(Enum(PaymentStatus), default=PaymentStatus.PENDING)
    payment_method = Column(String(50))   # istanbulkart, kredi_karti, vb.
    iyzico_ref     = Column(String(100))  # Iyzico ödeme referansı
    paid_at        = Column(DateTime(timezone=True))
    created_at     = Column(DateTime(timezone=True), default=utcnow)

    trip = relationship("Trip", back_populates="payment")


class Reward(Base):
    __tablename__ = "rewards"

    id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id      = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    trip_id      = Column(UUID(as_uuid=True), ForeignKey("trips.id"))
    reward_type  = Column(String(30))   # "points" | "badge"
    amount       = Column(Integer, default=0)
    badge_name   = Column(String(60))
    earned_at    = Column(DateTime(timezone=True), default=utcnow)

    user = relationship("User", back_populates="rewards")
    trip = relationship("Trip", back_populates="rewards")


class MaintenanceRecord(Base):
    __tablename__ = "maintenance_records"

    id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    bike_id      = Column(UUID(as_uuid=True), ForeignKey("bikes.id"), nullable=False)
    reported_by  = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    issue_type   = Column(String(80))
    description  = Column(Text)
    status       = Column(Enum(MaintenanceStatus), default=MaintenanceStatus.OPEN)
    reported_at  = Column(DateTime(timezone=True), default=utcnow)
    resolved_at  = Column(DateTime(timezone=True))

    bike = relationship("Bike", back_populates="maintenance_records")
