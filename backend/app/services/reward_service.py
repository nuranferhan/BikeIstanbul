"""Puan ve Rozet Servisi"""
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.models import Reward, Trip, User
from sqlalchemy import select

logger = logging.getLogger(__name__)

POINTS_PER_KM = 2
BADGE_THRESHOLDS = {
    "İlk Sürüş": 1,
    "Yeşil Kahraman": 10,
    "Bisiklet Ustası": 50,
}


class RewardService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def grant_trip_rewards(self, trip: Trip) -> None:
        points = int(trip.distance_km * POINTS_PER_KM)
        if points > 0:
            reward = Reward(
                user_id=trip.user_id,
                trip_id=trip.id,
                reward_type="points",
                amount=points,
            )
            self.db.add(reward)

            # Kullanıcı puanını güncelle
            result = await self.db.execute(select(User).where(User.id == trip.user_id))
            user = result.scalar_one_or_none()
            if user:
                user.points += points

            await self.db.commit()
            logger.info("Kullanıcı %s için %d puan verildi.", trip.user_id, points)
