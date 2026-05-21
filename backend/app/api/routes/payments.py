# payments.py – Ödeme rotaları (Iyzico entegrasyonu)
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.models import Payment, User

router = APIRouter()

@router.get("/{trip_id}")
async def get_payment(
    trip_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Payment).where(Payment.trip_id == trip_id))
    payment = result.scalar_one_or_none()
    if not payment:
        raise HTTPException(status_code=404, detail="Ödeme kaydı bulunamadı")
    return payment
