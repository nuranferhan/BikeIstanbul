"""Yönetici API rotaları."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.models import Bike, Trip, TripStatus, User, UserRole

router = APIRouter()


@router.get("/stats")
async def get_dashboard_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in (UserRole.ADMIN, UserRole.STAFF):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Yetkisiz erişim.")

    users_count = await db.scalar(select(func.count()).select_from(User))
    bikes_count = await db.scalar(select(func.count()).select_from(Bike))
    trips_count = await db.scalar(select(func.count()).select_from(Trip))
    active_trips = await db.scalar(select(func.count()).select_from(Trip).where(Trip.status == TripStatus.ACTIVE))

    return {
        "users": users_count or 0,
        "bikes": bikes_count or 0,
        "trips": trips_count or 0,
        "active_trips": active_trips or 0,
    }
