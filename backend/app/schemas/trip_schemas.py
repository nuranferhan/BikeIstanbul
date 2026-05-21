"""Yolculuk Pydantic Şemaları"""
from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel


class StartRentalRequest(BaseModel):
    bike_id: UUID


class TripResponse(BaseModel):
    id: UUID
    user_id: UUID
    bike_id: UUID
    status: str
    start_time: datetime
    end_time: Optional[datetime] = None
    distance_km: float = 0.0

    class Config:
        from_attributes = True


class TripSummaryResponse(BaseModel):
    trip: TripResponse
    cost: float
    carbon_saving_kg: float
    calories_burned: float
    distance_km: float
    transfer_suggestion: Optional[str] = None
