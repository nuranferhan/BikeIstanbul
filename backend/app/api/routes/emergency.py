"""
Acil Durum API Rotaları – AFAD Entegrasyonu
"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.models import User, UserRole
from app.services.emergency_service import create_default_emergency_publisher

router = APIRouter()
_publisher = create_default_emergency_publisher()


class EarthquakeAlert(BaseModel):
    magnitude: float = Field(..., ge=0.0, le=10.0, description="Deprem büyüklüğü (Richter)")
    source: str = Field(default="AFAD", description="Uyarı kaynağı")


@router.post("/earthquake", status_code=status.HTTP_200_OK)
async def trigger_earthquake_mode(
    alert: EarthquakeAlert,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    AFAD veya sistem yöneticisi tarafından deprem acil durum modunu başlatır.
    Tüm bisiklet kilitleri açılır, aktif kiralamalar iptal edilir.
    """
    if current_user.role not in (UserRole.ADMIN, UserRole.STAFF):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu işlem için yetkiniz bulunmamaktadır.",
        )
    await _publisher.notify_earthquake(magnitude=alert.magnitude, db=db)
    return {
        "message": f"Acil durum protokolü aktif edildi (M{alert.magnitude})",
        "source": alert.source,
    }
