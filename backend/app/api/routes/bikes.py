"""
Bisiklet API Rotaları
"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import get_current_user
from app.db.session import get_db
from app.models.models import Bike, BikeStatus, MaintenanceRecord, User

router = APIRouter()


@router.get("/nearby")
async def get_nearby_bikes(
    lat: float = Query(..., description="Kullanıcı enlemi"),
    lng: float = Query(..., description="Kullanıcı boylamı"),
    radius: int = Query(default=500, le=2000, description="Yarıçap (metre)"),
    db: AsyncSession = Depends(get_db),
):
    """
    FR-1: Kullanıcının çevresindeki müsait bisikletleri 1 saniye içinde listeler.
    PostGIS ST_DWithin fonksiyonu ile coğrafi sorgu yapılır.
    """
    # PostGIS coğrafi sorgu (raw SQL ile yüksek performans)
    from sqlalchemy import text
    query = text("""
        SELECT b.id, b.serial_number, b.battery_level, b.latitude, b.longitude,
               s.name AS station_name,
               ST_Distance(
                   ST_SetSRID(ST_MakePoint(b.longitude, b.latitude), 4326)::geography,
                   ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography
               ) AS distance_meters
        FROM bikes b
        LEFT JOIN stations s ON b.station_id = s.id
        WHERE b.status = 'available'
          AND ST_DWithin(
              ST_SetSRID(ST_MakePoint(b.longitude, b.latitude), 4326)::geography,
              ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
              :radius
          )
        ORDER BY distance_meters
        LIMIT 50
    """)
    result = await db.execute(query, {"lat": lat, "lng": lng, "radius": radius})
    bikes = result.mappings().all()
    return {"bikes": [dict(b) for b in bikes], "count": len(bikes)}


@router.get("/{bike_id}")
async def get_bike(bike_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Bike).where(Bike.id == bike_id))
    bike = result.scalar_one_or_none()
    if not bike:
        raise HTTPException(status_code=404, detail="Bisiklet bulunamadı")
    return bike


@router.post("/{bike_id}/report")
async def report_maintenance(
    bike_id: UUID,
    issue_type: str,
    description: str = "",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Kullanıcı arıza bildirimi yapar; bisiklet durumu 'broken' olarak işaretlenir."""
    result = await db.execute(select(Bike).where(Bike.id == bike_id))
    bike = result.scalar_one_or_none()
    if not bike:
        raise HTTPException(status_code=404, detail="Bisiklet bulunamadı")

    bike.status = BikeStatus.BROKEN
    record = MaintenanceRecord(
        bike_id=bike_id,
        reported_by=current_user.id,
        issue_type=issue_type,
        description=description,
    )
    db.add(record)
    await db.commit()
    return {"message": "Arıza bildirimi alındı.", "record_id": str(record.id)}
