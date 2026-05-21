"""Ödeme servis katmanı."""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.models import Payment, PaymentStatus, Trip


class PaymentService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_or_update_payment(self, trip: Trip) -> Payment:
        result = await self.db.execute(select(Payment).where(Payment.trip_id == trip.id))
        payment = result.scalar_one_or_none()

        amount = round(max(self._duration_minutes(trip), 1) * settings.PRICE_PER_MINUTE, 2)
        if payment is None:
            payment = Payment(
                trip_id=trip.id,
                amount=amount,
                status=PaymentStatus.COMPLETED,
                payment_method="iyzico",
                iyzico_ref=f"IYZ-{trip.id}",
                paid_at=datetime.now(timezone.utc),
            )
            self.db.add(payment)
        else:
            payment.amount = amount
            payment.status = PaymentStatus.COMPLETED
            payment.payment_method = payment.payment_method or "iyzico"
            payment.iyzico_ref = payment.iyzico_ref or f"IYZ-{trip.id}"
            payment.paid_at = payment.paid_at or datetime.now(timezone.utc)

        await self.db.commit()
        await self.db.refresh(payment)
        return payment

    async def get_by_trip_id(self, trip_id):
        result = await self.db.execute(select(Payment).where(Payment.trip_id == trip_id))
        return result.scalar_one_or_none()

    def _duration_minutes(self, trip: Trip) -> float:
        end_time = trip.end_time or datetime.now(timezone.utc)
        return max((end_time - trip.start_time).total_seconds() / 60, 0.0)
