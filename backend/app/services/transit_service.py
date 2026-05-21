"""
İBB Toplu Taşıma Adaptörü – Adapter Tasarım Deseni
Harici İBB API verisi sistemin iç veri yapısına dönüştürülür.
"""
import httpx
import logging
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional

from app.core.config import settings

logger = logging.getLogger(__name__)


@dataclass
class Departure:
    """Sistem içi toplu taşıma sefer modeli."""
    line: str
    direction: str
    departure_time: str
    vehicle_type: str  # "iett" | "marmaray" | "metrobus" | "vapur"


class TransitDataAdapter:
    """
    İBB Açık Veri Portalı'nın farklı JSON formatını
    sistemin standart Departure modeline dönüştürür.
    """

    def __init__(self, ibb_response: dict):
        self.raw = ibb_response

    def to_departure_list(self) -> List[Departure]:
        departures = []
        for item in self.raw.get("seferler", []):
            try:
                departure = Departure(
                    line=item.get("hat", ""),
                    direction=item.get("yon", ""),
                    departure_time=item.get("saat", ""),
                    vehicle_type=self._detect_vehicle_type(item.get("hat", "")),
                )
                departures.append(departure)
            except (KeyError, ValueError) as err:
                logger.warning("Sefer verisi ayrıştırılamadı: %s – hata: %s", item, err)
        return departures

    def _detect_vehicle_type(self, line_code: str) -> str:
        line_upper = line_code.upper()
        if "MR" in line_upper:
            return "marmaray"
        if "MB" in line_upper or "M" in line_upper[:2]:
            return "metrobus"
        if "V" in line_upper[:1]:
            return "vapur"
        return "iett"


class TransitService:
    """İBB API'sinden yakın istasyon sefer saatlerini çeken servis."""

    async def get_next_departures(
        self, latitude: float, longitude: float, radius_meters: int = 300
    ) -> List[Departure]:
        url = f"{settings.IBB_API_BASE_URL}/transportation/nearby"
        params = {"lat": latitude, "lon": longitude, "radius": radius_meters}

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(url, params=params)
                response.raise_for_status()
                adapter = TransitDataAdapter(response.json())
                return adapter.to_departure_list()
        except httpx.HTTPError as err:
            logger.error("İBB API hatası: %s", err)
            return []

    def format_transfer_suggestion(self, departures: List[Departure]) -> Optional[str]:
        """Varış noktası yakınındaki ilk 3 seferi kullanıcı dostu metne çevirir."""
        if not departures:
            return None
        lines = [f"{d.vehicle_type.upper()} {d.line} → {d.departure_time}" for d in departures[:3]]
        return "Yakın aktarma seçenekleri: " + " | ".join(lines)
