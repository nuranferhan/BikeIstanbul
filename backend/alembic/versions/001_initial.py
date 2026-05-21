"""initial_tables

Revision ID: 001_initial
Revises:
Create Date: 2026-01-01 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
import uuid


revision = '001_initial'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # PostGIS uzantısını etkinleştir
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")
    op.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    # users
    op.create_table(
        "users",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("full_name", sa.String(120), nullable=False),
        sa.Column("email", sa.String(255), unique=True, nullable=False),
        sa.Column("phone", sa.String(20), unique=True, nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.String(20), server_default="standard"),
        sa.Column("points", sa.Integer, server_default="0"),
        sa.Column("kvkk_consent", sa.Boolean, server_default="false"),
        sa.Column("is_active", sa.Boolean, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_users_email", "users", ["email"])

    # stations
    op.create_table(
        "stations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("address", sa.Text),
        sa.Column("latitude", sa.Float, nullable=False),
        sa.Column("longitude", sa.Float, nullable=False),
        sa.Column("total_slots", sa.Integer, server_default="20"),
        sa.Column("available_slots", sa.Integer, server_default="0"),
        sa.Column("air_quality_index", sa.Integer, server_default="50"),
        sa.Column("is_active", sa.Boolean, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # bikes
    op.create_table(
        "bikes",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("serial_number", sa.String(50), unique=True, nullable=False),
        sa.Column("station_id", UUID(as_uuid=True), sa.ForeignKey("stations.id"), nullable=True),
        sa.Column("status", sa.String(20), server_default="available"),
        sa.Column("battery_level", sa.Integer, server_default="100"),
        sa.Column("last_maintenance", sa.DateTime(timezone=True)),
        sa.Column("latitude", sa.Float),
        sa.Column("longitude", sa.Float),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # trips
    op.create_table(
        "trips",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("bike_id", UUID(as_uuid=True), sa.ForeignKey("bikes.id"), nullable=False),
        sa.Column("start_station_id", UUID(as_uuid=True), sa.ForeignKey("stations.id")),
        sa.Column("end_station_id", UUID(as_uuid=True), sa.ForeignKey("stations.id")),
        sa.Column("status", sa.String(20), server_default="active"),
        sa.Column("start_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_time", sa.DateTime(timezone=True)),
        sa.Column("distance_km", sa.Float, server_default="0"),
        sa.Column("carbon_saving_kg", sa.Float, server_default="0"),
        sa.Column("calories_burned", sa.Float, server_default="0"),
        sa.Column("transfer_suggestion", sa.Text),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # payments
    op.create_table(
        "payments",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("trips.id"), unique=True, nullable=False),
        sa.Column("amount", sa.Float, nullable=False),
        sa.Column("status", sa.String(20), server_default="pending"),
        sa.Column("payment_method", sa.String(50)),
        sa.Column("iyzico_ref", sa.String(100)),
        sa.Column("paid_at", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # rewards
    op.create_table(
        "rewards",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("trips.id")),
        sa.Column("reward_type", sa.String(30)),
        sa.Column("amount", sa.Integer, server_default="0"),
        sa.Column("badge_name", sa.String(60)),
        sa.Column("earned_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # maintenance_records
    op.create_table(
        "maintenance_records",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("bike_id", UUID(as_uuid=True), sa.ForeignKey("bikes.id"), nullable=False),
        sa.Column("reported_by", UUID(as_uuid=True), sa.ForeignKey("users.id")),
        sa.Column("issue_type", sa.String(80)),
        sa.Column("description", sa.Text),
        sa.Column("status", sa.String(20), server_default="open"),
        sa.Column("reported_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("resolved_at", sa.DateTime(timezone=True)),
    )


def downgrade() -> None:
    op.drop_table("maintenance_records")
    op.drop_table("rewards")
    op.drop_table("payments")
    op.drop_table("trips")
    op.drop_table("bikes")
    op.drop_table("stations")
    op.drop_table("users")
