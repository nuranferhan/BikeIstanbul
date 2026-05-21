# stations.py – İstasyon rotaları
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.models.models import Station

router = APIRouter()

@router.get("/")
async def list_stations(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Station).where(Station.is_active == True))
    return result.scalars().all()

@router.get("/{station_id}")
async def get_station(station_id: str, db: AsyncSession = Depends(get_db)):
    from uuid import UUID
    from fastapi import HTTPException
    result = await db.execute(select(Station).where(Station.id == UUID(station_id)))
    station = result.scalar_one_or_none()
    if not station:
        raise HTTPException(status_code=404, detail="İstasyon bulunamadı")
    return station
