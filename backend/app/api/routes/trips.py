"""
Yolculuk API Rotaları
"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.models import User
from app.schemas.trip_schemas import TripResponse, TripSummaryResponse, StartRentalRequest
from app.services.trip_service import TripService

router = APIRouter()


@router.post("/start", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
async def start_rental(
    payload: StartRentalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """QR kod okutulduğunda kiralama başlatır ve kilidi açar."""
    try:
        trip = await TripService(db).start_rental(
            user_id=current_user.id,
            bike_id=payload.bike_id,
        )
        return trip
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))


@router.patch("/{trip_id}/end", response_model=TripSummaryResponse)
async def end_trip(
    trip_id: UUID,
    end_station_id: UUID | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Yolculuğu sonlandırır, ödeme ve ödül hesaplamalarını tetikler."""
    service = TripService(db)
    try:
        trip = await service.end_trip(trip_id, end_station_id)
        cost = service.calculate_trip_cost(trip)
        return TripSummaryResponse(
            trip=trip,
            cost=cost,
            carbon_saving_kg=trip.carbon_saving_kg,
            calories_burned=trip.calories_burned,
            distance_km=trip.distance_km,
            transfer_suggestion=trip.transfer_suggestion,
        )
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(err))


@router.get("/active", response_model=TripResponse)
async def get_active_trip(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Kullanıcının aktif yolculuğunu döner."""
    from sqlalchemy import select
    from app.models.models import Trip, TripStatus
    result = await db.execute(
        select(Trip).where(
            Trip.user_id == current_user.id,
            Trip.status == TripStatus.ACTIVE,
        )
    )
    trip = result.scalar_one_or_none()
    if not trip:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Aktif yolculuk yok")
    return trip
