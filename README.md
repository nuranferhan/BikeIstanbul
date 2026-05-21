<div align="center">



### Akıllı Bisiklet Paylaşım ve Ulaşım Entegrasyon Platformu

[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL_15-PostGIS-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgis.net)
[![MQTT](https://img.shields.io/badge/MQTT-Eclipse_Mosquitto-660066?style=for-the-badge&logo=eclipse-mosquitto&logoColor=white)](https://mosquitto.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose)
[![License](https://img.shields.io/badge/Lisans-MIT-22c55e?style=for-the-badge)](LICENSE)

<br/>

> *BikeIstanbul, İstanbul'un akıllı şehir vizyonunun bir parçası olarak tasarlanmış,*  
> *IoT entegrasyonlu, deprem güvenlik protokollü mikromobilite platformudur.*

<br/>

[Özellikler](#-özellikler) · [Mimari](#-sistem-mimarisi) · [Kurulum](#-kurulum) · [API Dokümantasyonu](#-api-dokümantasyonu) · [Test](#-test) 

</div>


##  Özellikler

### Gerçek Zamanlı Harita
- 500m yarıçapta müsait bisikletleri **1 saniye** içinde listeleme (FR-1)
- PostGIS `ST_DWithin` ile hızlı coğrafi sorgulama
- Batarya durumuna göre renk kodlu harita işaretçileri

### QR Kod ile Kiralama
- Anlık QR kod okutma → MQTT üzerinden kilit açma komutu
- HMAC-SHA256 imzalı güvenli IoT mesajlaşma
- TLS 1.3 şifreli broker iletişimi

### Toplu Taşıma Entegrasyonu
- İETT, Marmaray, Metrobüs ve Vapur sefer saatleri (İBB Açık Veri)
- Varış noktasına göre otomatik aktarma önerisi (FR-3)

### Sürdürülebilirlik Sistemi
- Anlık CO₂ tasarrufu hesaplama (0.21 kg/km)
- Yakılan kalori takibi
- Puan ve rozet gamification sistemi

### Deprem Acil Durum Modu
- AFAD entegrasyonu ile otomatik tetikleme
- **Observer Deseni**: Tüm kilitler açılır, kiralamalar ücretsiz iptal edilir
- İstasyon broadcast bildirimleri (QoS 2)

### Ödeme
- İstanbulkart entegrasyonu
- Iyzico API ile güvenli online ödeme
- PCI-DSS uyumlu kart bilgisi saklama

---

## Sistem Mimarisi

BikeIstanbul, **Katmanlı Mimari** (Layered Architecture) üzerine inşa edilmiştir.

```
┌────────────────────────────────────────────────────────────────┐
│                     SUNUM KATMANI                              │
│  ┌─────────────────────────┐  ┌────────────────────────────┐   │
│  │  Flutter Mobil (iOS/Android) │  │  React Web Yönetim Paneli │  
│  │  MVVM + Provider/Riverpod │  │  TypeScript + Harita/Grafik  │
│  └─────────────────────────┘  └────────────────────────────┘   │
├────────────────────────────────────────────────────────────────┤
│                   İŞ MANTIĞI KATMANI                           │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────┐ ┌──────────┐ │
│  │  TripService │ │PaymentService│ │RouteService│ │Emergency │ │
│  │  (Kiralama)  │ │  (Iyzico)    │ │ (PostGIS)  │ │ Service  │ │
│  └──────────────┘ └──────────────┘ └────────────┘ └──────────┘ │
│         FastAPI · Python 3.11 · SQLAlchemy · JWT               │
├────────────────────────────────────────────────────────────────┤
│                      VERİ KATMANI                              │
│  ┌──────────────────────┐  ┌───────────────────────────────┐   │
│  │  PostgreSQL 15       │  │  Eclipse Mosquitto            │   │
│  │  + PostGIS 3.4       │  │  MQTT Broker (IoT)            │   │
│  │  Coğrafi Sorgular    │  │  TLS 1.3 · QoS 1-2            │   │
│  └──────────────────────┘  └───────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

### Kullanılan Tasarım Desenleri

| Desen | Nerede? | Açıklama |
|-------|---------|----------|
| **Singleton** | `MqttClient` | Tek bir broker bağlantısı tüm servisler tarafından paylaşılır |
| **Observer** | `EmergencyEventPublisher` | Deprem uyarısı birden fazla servise bağımsız iletilir |
| **Adapter** | `TransitDataAdapter` | İBB API formatı sistem içi `Departure` modeline dönüştürülür |
| **MVVM** | Flutter katmanı | `BikeMapViewModel` ile View ve iş mantığı ayrıştırılır |

---

## Proje Yapısı

```
bikeistanbul/
│
├── backend/                        # Python FastAPI Servisi
│   ├── app/
│   │   ├── main.py                    # Uygulama giriş noktası
│   │   ├── api/routes/
│   │   │   ├── auth.py                # Kayıt / Giriş (JWT)
│   │   │   ├── bikes.py               # Bisiklet sorgulama, arıza bildirimi
│   │   │   ├── stations.py            # İstasyon verileri
│   │   │   ├── trips.py               # Kiralama başlatma / sonlandırma
│   │   │   ├── payments.py            # Ödeme işlemleri
│   │   │   └── emergency.py           # Deprem acil durum endpoint'i
│   │   ├── core/
│   │   │   ├── config.py              # Ortam değişkenleri (Pydantic Settings)
│   │   │   └── security.py            # JWT, Argon2 şifreleme
│   │   ├── models/
│   │   │   └── models.py              # SQLAlchemy ORM modelleri
│   │   ├── services/
│   │   │   ├── trip_service.py        # Kiralama iş mantığı (Clean Code)
│   │   │   ├── mqtt_service.py        # IoT iletişimi (Singleton)
│   │   │   ├── emergency_service.py   # Deprem protokolü (Observer)
│   │   │   ├── transit_service.py     # İBB entegrasyonu (Adapter)
│   │   │   └── reward_service.py      # Puan / rozet sistemi
│   │   └── db/
│   │       └── session.py             # AsyncSession yönetimi
│   ├── alembic/versions/
│   │   └── 001_initial.py             # Veritabanı migration
│   ├── tests/
│   │   └── test_trip_service.py       # pytest birim testleri
│   ├── Dockerfile
│   └── requirements.txt
│
├── flutter_app/                    # Flutter Mobil Uygulama
│   ├── lib/
│   │   ├── data/
│   │   │   ├── models/                # Veri transfer nesneleri
│   │   │   ├── repositories/          # API çağrıları
│   │   │   └── datasources/           # HTTP / yerel depolama
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── bike_map_screen.dart       # Ana harita ekranı
│   │   │   │   └── trip_summary_screen.dart   # Yolculuk özeti
│   │   │   ├── viewmodels/
│   │   │   │   └── bike_map_viewmodel.dart    # MVVM iş mantığı
│   │   │   └── widgets/
│   │   │       ├── bike_detail_sheet.dart     # Bisiklet detay modal
│   │   │       └── active_trip_banner.dart    # Aktif sürüş bandı
│   │   └── utils/
│   └── pubspec.yaml
│
├── docs/                           # Dokümanlar ve diyagramlar
├── docker-compose.yml                 # Tüm servisleri ayağa kaldırır
├── .env.example                       # Ortam değişkeni şablonu
└── README.md
```

---

## Kurulum

### Gereksinimler

- **Docker** 24+ ve **Docker Compose** v2+
- **Flutter SDK** 3.4+ *(mobil geliştirme için)*
- **Python** 3.11+ *(yerel backend geliştirme için)*

### 1. Depoyu Klonlayın

```bash
git clone https://github.com/bikeistanbul/platform.git
cd platform
```

### 2. Ortam Değişkenlerini Yapılandırın

```bash
cp .env.example .env
```

`.env` dosyasını açıp aşağıdaki değerleri girin:

```env
SECRET_KEY=guclu-bir-anahtar-girin
GOOGLE_MAPS_API_KEY=...
IYZICO_API_KEY=...
IYZICO_SECRET_KEY=...
```

### 3. Tüm Servisleri Başlatın

```bash
docker compose up --build
```

> İlk build birkaç dakika sürebilir. PostgreSQL ve Mosquitto hazır olduğunda backend otomatik başlar.

### 4. Veritabanı Migration'larını Çalıştırın

```bash
docker compose exec backend alembic upgrade head
```

### 5. Erişim

| Servis | URL |
|--------|-----|
| REST API | http://localhost:8000 |
| API Dokümantasyonu (Swagger) | http://localhost:8000/docs |
| Web Yönetim Paneli | http://localhost:3000 |
| PostgreSQL | localhost:5432 |
| MQTT Broker | localhost:1883 |

---

## API Dokümantasyonu

Swagger UI otomatik olarak oluşturulur: **http://localhost:8000/docs**

### Temel Endpoint'ler

```
POST   /api/v1/auth/register          Yeni kullanıcı kaydı (KVKK onayı zorunlu)
POST   /api/v1/auth/login             JWT token al

GET    /api/v1/bikes/nearby?lat=&lng= Yakın bisikletleri listele (PostGIS)
GET    /api/v1/bikes/{id}             Bisiklet detayı
POST   /api/v1/bikes/{id}/report      Arıza bildir

GET    /api/v1/stations               İstasyon listesi
GET    /api/v1/stations/{id}          İstasyon detayı

POST   /api/v1/trips/start            Kiralama başlat → MQTT UNLOCK komutu
PATCH  /api/v1/trips/{id}/end         Yolculuğu sonlandır → özet + ödül
GET    /api/v1/trips/active           Aktif yolculuk bilgisi

POST   /api/v1/emergency/earthquake   Deprem acil durum modu [ADMIN]
```

### Örnek İstek: Kiralama Başlatma

```bash
curl -X POST http://localhost:8000/api/v1/trips/start \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"bike_id": "550e8400-e29b-41d4-a716-446655440000"}'
```

```json
{
  "id": "trip-uuid",
  "status": "active",
  "start_time": "2026-03-29T15:30:00+03:00",
  "bike_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## IoT MQTT Protokolü

Bisiklet kilitleri ile backend arasındaki iletişim MQTT protokolü üzerinden yürür.

### Topic Yapısı

```
bikes/{bikeId}/command    ← Backend → IoT (UNLOCK, LOCK, STATUS_REQUEST)
bikes/{bikeId}/status     → IoT → Backend (UNLOCK_SUCCESS, BATTERY_LOW, ERROR)
stations/{stationId}/alert ← Deprem ve bakım yayınları
```

### Mesaj Örnekleri

**Kilit Açma Komutu:**
```json
{
  "command": "UNLOCK",
  "tripId": "TRP-987654",
  "userId": "USR-12345",
  "timestamp": "2026-03-29T15:30:00+03:00",
  "signature": "HMAC-SHA256-hash"
}
```

**Başarılı Yanıt:**
```json
{
  "status": "UNLOCK_SUCCESS",
  "bikeId": "BIKE-45678",
  "batteryLevel": 87,
  "unlockTime": "2026-03-29T15:30:05+03:00"
}
```

---

## Test

### Birim Testleri (pytest)

```bash
cd backend
pip install -r requirements.txt
pytest tests/ -v --tb=short
```

```
tests/test_trip_service.py::test_start_rental_with_available_bike  PASSED
tests/test_trip_service.py::test_start_rental_with_unavailable_bike PASSED
tests/test_trip_service.py::test_calculate_trip_cost_25_minutes    PASSED
tests/test_trip_service.py::test_calculate_carbon_saving           PASSED
tests/test_trip_service.py::test_emergency_handler_marks_bikes_available PASSED
```

### Kod Kalitesi (Pylint)

```bash
pylint app/ --disable=C0114,C0115 --max-line-length=100
```

> Hedef skor: **9.0 / 10** ↑

### Flutter Testleri

```bash
cd flutter_app
flutter test
flutter test integration_test/  # Uçtan uca testler
```

---

## Ortam Değişkenleri

| Değişken | Açıklama | Varsayılan |
|----------|----------|-----------|
| `SECRET_KEY` | JWT imzalama anahtarı | *(zorunlu)* |
| `DATABASE_URL` | PostgreSQL bağlantı URI | `postgresql+asyncpg://...` |
| `MQTT_BROKER_HOST` | MQTT broker adresi | `localhost` |
| `GOOGLE_MAPS_API_KEY` | Harita servisi anahtarı | *(zorunlu)* |
| `IYZICO_API_KEY` | Ödeme geçidi anahtarı | *(zorunlu)* |
| `PRICE_PER_MINUTE` | Dakika başı ücret (TL) | `0.50` |
| `CO2_SAVING_PER_KM` | CO₂ tasarruf katsayısı (kg/km) | `0.21` |
| `STEEP_SLOPE_THRESHOLD` | Yokuş uyarı eşiği (%) | `15.0` |

---

## Lisans

Bu proje **MIT Lisansı** kapsamında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

---

<div align="center">

<br/>


</div>
