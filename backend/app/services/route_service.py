"""Rota ve aktarma önerisi servis katmanı."""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import Station
from app.services.transit_service import TransitService


class RouteService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.transit_service = TransitService()

    async def build_transfer_suggestion(self, station_id) -> str | None:
        if station_id is None:
            return None

        result = await self.db.execute(select(Station).where(Station.id == station_id))
        station = result.scalar_one_or_none()
        if station is None:
            return None

        departures = await self.transit_service.get_next_departures(
            station.latitude,
            station.longitude,
            radius_meters=300,
        )
        suggestion = self.transit_service.format_transfer_suggestion(departures)
        if suggestion:
            return suggestion
        return f"Yakın aktarma seçenekleri: {station.name} çevresinde transit verisi bulunamadı."
