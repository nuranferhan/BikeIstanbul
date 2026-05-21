"""
MQTT Servisi – IoT Bisiklet Kilidi İletişimi
Singleton Deseni: Tüm uygulama boyunca tek bir broker bağlantısı kullanılır.
"""
import json
import logging
from typing import Callable, Dict

import paho.mqtt.client as mqtt_client

from app.core.config import settings

logger = logging.getLogger(__name__)


class MqttClient:
    """
    Eclipse Mosquitto broker'ına bağlanan Singleton MQTT istemcisi.
    Singleton Deseni sayesinde tek bir TCP bağlantısı açık tutulur;
    farklı servisler ortak referans üzerinden erişir.
    """
    _instance: "MqttClient | None" = None

    def __init__(self):
        self._client = mqtt_client.Client(client_id="bikeistanbul-backend")
        self._client.on_connect    = self._on_connect
        self._client.on_disconnect = self._on_disconnect
        self._client.on_message    = self._on_message
        self._handlers: Dict[str, Callable] = {}

        if settings.MQTT_USERNAME:
            self._client.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)

    @classmethod
    def get_instance(cls) -> "MqttClient":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    # ── Bağlantı Yönetimi ─────────────────────────────────────────────────────

    def connect(self) -> None:
        self._client.connect(settings.MQTT_BROKER_HOST, settings.MQTT_BROKER_PORT, keepalive=60)
        self._client.loop_start()
        logger.info("MQTT broker'a bağlanıldı: %s:%s", settings.MQTT_BROKER_HOST, settings.MQTT_BROKER_PORT)

    def disconnect(self) -> None:
        self._client.loop_stop()
        self._client.disconnect()
        logger.info("MQTT bağlantısı kapatıldı.")

    # ── DRY: Tüm Komutlar Tek Metot Üzerinden Gönderilir ─────────────────────

    def publish_command(self, bike_id: str, command: dict) -> None:
        """
        Bir bisiklete komut gönderir.
        Kilit açma, kilit kapama ve durum sorgulama aynı metot üzerinden çalışır;
        mesaj içeriği parametreden sağlanır (DRY Prensibi).
        """
        topic = f"bikes/{bike_id}/command"
        payload = json.dumps(command)
        result = self._client.publish(topic, payload, qos=1)
        if result.rc != mqtt_client.MQTT_ERR_SUCCESS:
            logger.error("MQTT publish hatası – bike: %s, kod: %s", bike_id, result.rc)

    def publish_emergency(self, station_id: str, magnitude: float) -> None:
        """Deprem acil durum yayınını tüm istasyonlara iletir."""
        topic = f"stations/{station_id}/alert"
        payload = json.dumps({"type": "EARTHQUAKE", "magnitude": magnitude})
        self._client.publish(topic, payload, qos=2)

    def subscribe_bike_status(self, bike_id: str, handler: Callable) -> None:
        topic = f"bikes/{bike_id}/status"
        self._handlers[topic] = handler
        self._client.subscribe(topic, qos=1)

    # ── Geri Çağrılar ─────────────────────────────────────────────────────────

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            logger.info("MQTT bağlantısı başarılı.")
        else:
            logger.error("MQTT bağlantı hatası, kod: %s", rc)

    def _on_disconnect(self, client, userdata, rc):
        logger.warning("MQTT bağlantısı kesildi, kod: %s. Yeniden bağlanılıyor...", rc)

    def _on_message(self, client, userdata, msg):
        handler = self._handlers.get(msg.topic)
        if handler:
            payload = json.loads(msg.payload.decode())
            handler(payload)
        else:
            logger.debug("İşlenmeyen MQTT mesajı – konu: %s", msg.topic)
