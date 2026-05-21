import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/models/bike_model.dart';
import '../viewmodels/bike_map_viewmodel.dart';
import '../widgets/active_trip_banner.dart';
import '../widgets/bike_detail_sheet.dart';
import 'trip_summary_screen.dart';

class BikeMapScreen extends StatefulWidget {
  const BikeMapScreen({super.key});

  @override
  State<BikeMapScreen> createState() => _BikeMapScreenState();
}

class _BikeMapScreenState extends State<BikeMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _userLocation = const LatLng(41.0082, 28.9784);
  int _tabIndex = 0;
  String _destination = 'Kadıköy Rıhtım';

  static const _tabs = [
    _TabEntry('Harita', Icons.map_outlined),
    _TabEntry('QR Kiralama', Icons.qr_code_2_rounded),
    _TabEntry('Transit', Icons.directions_transit_rounded),
    _TabEntry('Sürdürülebilirlik', Icons.eco_outlined),
    _TabEntry('Acil Durum', Icons.warning_amber_rounded),
  ];

  static const Map<String, _RouteOption> _routeOptions = {
    'Kadıköy Rıhtım': _RouteOption(
      title: 'Kadıköy Rıhtım',
      duration: '35 dk',
      steps: [
        _RouteStep(icon: '🚲', title: 'BikeIstanbul', description: 'Sultanahmet → Eminönü', time: '10 dk', color: Color(0xFFDCFCE7)),
        _RouteStep(icon: '⛴', title: 'Şehir Hatları', description: 'Eminönü → Kadıköy', time: '15 dk', color: Color(0xFFDBEAFE)),
        _RouteStep(icon: '🚇', title: 'Marmaray', description: 'Kadıköy → Üsküdar', time: '5 dk', color: Color(0xFFFCE7F3)),
      ],
    ),
    'Eminönü': _RouteOption(
      title: 'Eminönü',
      duration: '10 dk',
      steps: [
        _RouteStep(icon: '🚲', title: 'BikeIstanbul', description: 'Sultanahmet → Eminönü', time: '10 dk', color: Color(0xFFDCFCE7)),
      ],
    ),
    'Bağcılar Metro': _RouteOption(
      title: 'Bağcılar Metro',
      duration: '55 dk',
      steps: [
        _RouteStep(icon: '🚲', title: 'BikeIstanbul', description: 'Sultanahmet → Aksaray', time: '15 dk', color: Color(0xFFDCFCE7)),
        _RouteStep(icon: '🚌', title: 'Metrobüs', description: 'Aksaray → Bağcılar', time: '25 dk', color: Color(0xFFFEF3C7)),
        _RouteStep(icon: '🚇', title: 'Metro M1', description: 'Bağcılar → Atatürk Havalimanı', time: '15 dk', color: Color(0xFFE0E7FF)),
      ],
    ),
    'Üsküdar İskelesi': _RouteOption(
      title: 'Üsküdar İskelesi',
      duration: '25 dk',
      steps: [
        _RouteStep(icon: '🚲', title: 'BikeIstanbul', description: 'Sultanahmet → Eminönü', time: '10 dk', color: Color(0xFFDCFCE7)),
        _RouteStep(icon: '⛴', title: 'Vapur', description: 'Eminönü → Üsküdar', time: '15 dk', color: Color(0xFFDBEAFE)),
      ],
    ),
  };

  static const _transitCards = [
    _TransitCard(
      name: 'Marmaray',
      location: 'Kadıköy İstasyonu',
      departures: ['14:35', '14:50', '15:05'],
      color: Color(0xFFFCE7F3),
      icon: Icons.train_rounded,
    ),
    _TransitCard(
      name: 'Metrobüs',
      location: 'Aksaray Durağı',
      departures: ['14:28', '14:41', '14:57'],
      color: Color(0xFFFEF3C7),
      icon: Icons.directions_bus_rounded,
    ),
    _TransitCard(
      name: 'Vapur',
      location: 'Eminönü İskelesi',
      departures: ['14:40', '15:00', '15:20'],
      color: Color(0xFFDBEAFE),
      icon: Icons.directions_boat_filled_rounded,
    ),
    _TransitCard(
      name: 'Metro',
      location: 'Bağcılar',
      departures: ['14:32', '14:47', '15:02'],
      color: Color(0xFFE0E7FF),
      icon: Icons.subway_rounded,
    ),
  ];

  static const _emergencyLog = [
    _LogEntry('14:35', 'Devam eden kiralamalar ücretsiz iptal edildi', true),
    _LogEntry('14:35', 'Açılan kilitler tüm istasyonlara yayınlandı', true),
    _LogEntry('14:30', 'Kadıköy hattı için yedek güvenli mod aktarıldı', false),
    _LogEntry('14:20', 'AFAD sinyali doğrulandı', true),
    _LogEntry('14:10', 'BROADCAST_UNLOCK komutu tetiklendi', false),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBikes());
  }

  Future<void> _loadBikes() async {
    await context.read<BikeMapViewModel>().loadNearbyBikes(_userLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            return Row(
              children: [
                if (wide) _Sidebar(
                  activeIndex: _tabIndex,
                  onSelected: (index) => setState(() => _tabIndex = index),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        isWide: wide,
                        onRefresh: _loadBikes,
                        onGoEmergency: () => setState(() => _tabIndex = 4),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _tabIndex,
                          children: [
                            _MapPage(
                              mapController: _mapController,
                              userLocation: _userLocation,
                              onTapBike: _handleBikeTap,
                              onRent: _handleRentBike,
                              onEndTrip: _handleEndTrip,
                            ),
                            _QrPage(onGenerate: _loadBikes),
                            _TransitPage(
                              destination: _destination,
                              routeOptions: _routeOptions,
                              transitCards: _transitCards,
                              onDestinationChanged: (value) => setState(() => _destination = value),
                            ),
                            const _SustainabilityPage(),
                            const _EmergencyPage(logs: _emergencyLog),
                          ],
                        ),
                      ),
                      if (!wide)
                        NavigationBar(
                          selectedIndex: _tabIndex,
                          onDestinationSelected: (index) => setState(() => _tabIndex = index),
                          destinations: _tabs
                              .map(
                                (tab) => NavigationDestination(
                                  icon: Icon(tab.icon),
                                  label: tab.label,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBikeTap(BikeModel bike) async {
    final vm = context.read<BikeMapViewModel>();
    vm.selectBike(bike);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BikeDetailSheet(
        bike: bike,
        onRent: () async {
          Navigator.pop(context);
          final success = await vm.startRental(bike.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Kilit açıldı, sürüş başladı.' : 'Kiralama başlatılamadı.'),
              backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            ),
          );
        },
      ),
    );
    vm.clearSelection();
  }

  Future<void> _handleRentBike(BikeModel bike) async {
    final vm = context.read<BikeMapViewModel>();
    final success = await vm.startRental(bike.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${bike.serialNumber} kilidi açıldı.' : 'Kiralama başlatılamadı.'),
        backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
      ),
    );
  }

  Future<void> _handleEndTrip() async {
    final vm = context.read<BikeMapViewModel>();
    final summary = await vm.endTrip();
    if (!mounted || summary == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripSummaryScreen(summary: summary)),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isWide;
  final VoidCallback onRefresh;
  final VoidCallback onGoEmergency;

  const _TopBar({
    required this.isWide,
    required this.onRefresh,
    required this.onGoEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bike, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BikeIstanbul',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Akıllı bisiklet paylaşım ve ulaşım entegrasyon platformu',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          _Pill(
            label: 'Acil durum',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            onTap: onGoEmergency,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF16A34A),
            child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelected;

  const _Sidebar({
    required this.activeIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Pill(
              label: 'Online',
              icon: Icons.circle,
              color: const Color(0xFF22C55E),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _BikeMapScreenState._tabs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tab = _BikeMapScreenState._tabs[index];
                final selected = index == activeIndex;
                return InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(tab.icon, color: selected ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: selected ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPage extends StatelessWidget {
  final MapController mapController;
  final LatLng userLocation;
  final Future<void> Function(BikeModel bike) onTapBike;
  final Future<void> Function(BikeModel bike) onRent;
  final Future<void> Function() onEndTrip;

  const _MapPage({
    required this.mapController,
    required this.userLocation,
    required this.onTapBike,
    required this.onRent,
    required this.onEndTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeMapViewModel>(
      builder: (context, vm, _) {
        final isLoading = vm.state == MapState.loading;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Müsait bisiklet',
                        value: '${vm.nearbyBikes.length}',
                        icon: Icons.directions_bike_rounded,
                        accent: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _MetricCard(
                        title: 'Aktif rota',
                        value: '5',
                        icon: Icons.route_rounded,
                        accent: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _MetricCard(
                        title: 'AFAD durumu',
                        value: 'Hazır',
                        icon: Icons.shield_outlined,
                        accent: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: userLocation,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.bikeistanbul.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: userLocation,
                              width: 44,
                              height: 44,
                              child: const _MarkerDot(
                                icon: Icons.person_pin_circle_rounded,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            ...vm.nearbyBikes.map(
                              (bike) => Marker(
                                point: LatLng(bike.latitude, bike.longitude),
                                width: 56,
                                height: 56,
                                child: GestureDetector(
                                  onTap: () => onTapBike(bike),
                                  child: _BikeMarker(bike: bike),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (vm.hasActiveTrip) ...[
                  ActiveTripBanner(onEndTrip: onEndTrip),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Yakın bisikletler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.nearbyBikes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 174,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final bike = vm.nearbyBikes[index];
                    return _BikeCard(
                      bike: bike,
                      onTap: () => onTapBike(bike),
                      onRent: () => onRent(bike),
                    );
                  },
                ),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.white.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}

class _BikeCard extends StatelessWidget {
  final BikeModel bike;
  final VoidCallback onTap;
  final VoidCallback onRent;

  const _BikeCard({
    required this.bike,
    required this.onTap,
    required this.onRent,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = bike.batteryLevel <= 20;
    final statusColor = bike.status == 'available' ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bike.serialNumber,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bike.stationName ?? 'İstasyon dışı',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      bike.status == 'available' ? 'Müsait' : bike.status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.battery_5_bar_rounded, color: isLow ? const Color(0xFFEF4444) : const Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    '%${bike.batteryLevel}',
                    style: TextStyle(
                      color: isLow ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₺0.50/dk',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: bike.batteryLevel / 100,
                backgroundColor: const Color(0xFFE2E8F0),
                color: isLow ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                minHeight: 5,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 10),
              if ((bike.label ?? '').isNotEmpty)
                Text(
                  bike.label!,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: bike.status == 'available' ? onRent : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kilidi Aç'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrPage extends StatelessWidget {
  final VoidCallback onGenerate;
  const _QrPage({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeMapViewModel>(
      builder: (context, vm, _) {
        final bike = vm.nearbyBikes.isNotEmpty ? vm.nearbyBikes.first : null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader(
              title: 'QR kiralama',
              subtitle: 'Kodu okut, kilidi aç ve sürüşe başla.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('BikeIstanbul', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const _QrMock(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    bike != null ? bike.serialNumber : 'BK-1234',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kilit açma için QR kodu tarat veya aşağıdan bisiklet seç',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Yeni QR Oluştur'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Hızlı erişim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (vm.nearbyBikes.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.nearbyBikes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 150,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final bike = vm.nearbyBikes[index];
                  return _QuickBikeCard(
                    bike: bike,
                    onRent: () async {
                      final ok = await vm.startRental(bike.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? '${bike.serialNumber} kilidi açıldı.' : 'Kiralama başlatılamadı.'),
                        ),
                      );
                    },
                  );
                },
              )
            else
              const _EmptyState(
                icon: Icons.qr_code_2_rounded,
                title: 'Henüz bisiklet yok',
                subtitle: 'Harita sekmesinden yakın bisikletleri yükleyebilirsin.',
              ),
          ],
        );
      },
    );
  }
}

class _TransitPage extends StatelessWidget {
  final String destination;
  final Map<String, _RouteOption> routeOptions;
  final List<_TransitCard> transitCards;
  final ValueChanged<String> onDestinationChanged;

  const _TransitPage({
    required this.destination,
    required this.routeOptions,
    required this.transitCards,
    required this.onDestinationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final route = routeOptions[destination] ?? routeOptions.values.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          title: 'Transit entegrasyon',
          subtitle: 'Bisiklet + toplu taşıma kombinasyonlarıyla son kilometreyi tamamla.',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rota seçimi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: destination,
                      items: routeOptions.keys
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) onDestinationChanged(value);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RouteSummary(route: route),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transit kartları',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transitCards.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 154,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) => _TransitCardView(card: transitCards[index]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SustainabilityPage extends StatelessWidget {
  const _SustainabilityPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionHeader(
          title: 'Sürdürülebilirlik',
          subtitle: 'CO₂ tasarrufu, kalori ve puan sistemi tek yerde.',
        ),
        SizedBox(height: 16),
        _SustainabilityHero(),
        SizedBox(height: 16),
        _StatsGrid(),
        SizedBox(height: 16),
        _BadgesPanel(),
      ],
    );
  }
}

class _EmergencyPage extends StatelessWidget {
  final List<_LogEntry> logs;
  const _EmergencyPage({required this.logs});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          title: 'Acil durum modu',
          subtitle: 'AFAD sinyali geldiğinde tüm kilitler yayınlanır ve kiralamalar durdurulur.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EMERGENCY MODE ACTIVE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _InfoChip(label: 'AFAD', value: '6.5'),
                  _InfoChip(label: 'Kilitler', value: 'Açık'),
                  _InfoChip(label: 'Kiralamalar', value: 'İptal'),
                  _InfoChip(label: 'Bildirim', value: 'QoS 2'),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7F1D1D),
                  disabledBackgroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF7F1D1D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Acil mod simülasyonu'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(child: _EmergencyProtocolCard()),
            SizedBox(width: 16),
            Expanded(child: _EmergencyFlowCard()),
          ],
        ),
        const SizedBox(height: 16),
        _EmergencyLogPanel(logs: logs),
      ],
    );
  }
}

class _EmergencyProtocolCard extends StatelessWidget {
  const _EmergencyProtocolCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Observer protokolü', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          _ProtocolRow(label: 'Kilit açma', ok: true),
          _ProtocolRow(label: 'Kiralama iptali', ok: true),
          _ProtocolRow(label: 'Ücret iadesi', ok: true),
          _ProtocolRow(label: 'Kullanıcı bildirimi', ok: true),
        ],
      ),
    );
  }
}

class _EmergencyFlowCard extends StatelessWidget {
  const _EmergencyFlowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('AFAD yayın akışı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          _FlowNode(title: 'AFAD Server', subtitle: 'Sinyal alındı', active: true),
          SizedBox(height: 10),
          _FlowNode(title: 'BikeIstanbul', subtitle: 'Backend', active: true),
          SizedBox(height: 10),
          _FlowNode(title: 'Tüm istasyonlar', subtitle: 'Broadcast yayıldı', active: true),
        ],
      ),
    );
  }
}

class _EmergencyLogPanel extends StatelessWidget {
  final List<_LogEntry> logs;
  const _EmergencyLogPanel({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Olay kaydı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...logs.map(
            (log) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: log.critical ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(log.time, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(log.message)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BikeMarker extends StatelessWidget {
  final BikeModel bike;
  const _BikeMarker({required this.bike});

  @override
  Widget build(BuildContext context) {
    final color = bike.batteryLevel > 20 ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Text('%${bike.batteryLevel}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _MarkerDot extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MarkerDot({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _QuickBikeCard extends StatelessWidget {
  final BikeModel bike;
  final VoidCallback onRent;

  const _QuickBikeCard({
    required this.bike,
    required this.onRent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bike.serialNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(bike.stationName ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.battery_full_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 6),
              Text('%${bike.batteryLevel}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRent,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Aç'),
          ),
        ],
      ),
    );
  }
}

class _QrMock extends StatelessWidget {
  const _QrMock();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 2, crossAxisSpacing: 2),
          itemCount: 64,
          itemBuilder: (_, index) {
            final isDark = [0, 1, 2, 8, 9, 16, 17, 18, 24, 26, 33, 40, 41, 47, 48, 55, 63].contains(index) || index % 7 == 0;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final _RouteOption route;
  const _RouteSummary({required this.route});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('İETT / Marmaray / Vapur entegrasyonu', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              Text(route.duration, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 26, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: route.steps
              .map(
                (step) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: step.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(step.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(step.description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Text(step.time, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TransitCardView extends StatelessWidget {
  final _TransitCard card;
  const _TransitCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: card.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, size: 16, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(card.location, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...card.departures.map(
            (time) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sefer', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text(time, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SustainabilityHero extends StatelessWidget {
  const _SustainabilityHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CO₂ tasarrufu', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text('2,543 kg', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('Şehir genelinde bisiklet kullanımıyla sağlanan toplam çevresel katkı.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(width: 16),
          Icon(Icons.eco_outlined, color: Color(0xFF22C55E), size: 64),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('345,120', 'yakılan kalori', Icons.local_fire_department_rounded, const Color(0xFFF59E0B)),
      ('8,224', 'aktif puan', Icons.stars_rounded, const Color(0xFF22C55E)),
      ('1,432', 'iptal edilen sürüş', Icons.event_available_rounded, const Color(0xFF3B82F6)),
      ('82', 'açılan kilit', Icons.lock_open_rounded, const Color(0xFFEF4444)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 120,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) {
        final (value, label, icon, color) = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(label, style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BadgesPanel extends StatelessWidget {
  const _BadgesPanel();

  @override
  Widget build(BuildContext context) {
    final badges = [
      ('İlk Sürüş', '1 sürüş tamamla', Icons.emoji_events_rounded, const Color(0xFFF59E0B)),
      ('Yeşil Kahraman', '10 km üzerinde sür', Icons.park_rounded, const Color(0xFF22C55E)),
      ('Bisiklet Ustası', '50 km sür', Icons.directions_bike_rounded, const Color(0xFF3B82F6)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rozet sistemi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...badges.map(
            (badge) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(badge.$3, color: badge.$4),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(badge.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(badge.$2, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  final String label;
  final bool ok;
  const _ProtocolRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 16, color: Color(0xFF16A34A)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(ok ? 'Başarıyla tamamlandı' : 'Bekliyor', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11)),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  const _FlowNode({required this.title, required this.subtitle, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEF4444).withOpacity(0.12) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_right_alt_rounded, color: Color(0xFFEF4444)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF64748B)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _TabEntry {
  final String label;
  final IconData icon;
  const _TabEntry(this.label, this.icon);
}

class _RouteOption {
  final String title;
  final String duration;
  final List<_RouteStep> steps;
  const _RouteOption({
    required this.title,
    required this.duration,
    required this.steps,
  });
}

class _RouteStep {
  final String icon;
  final String title;
  final String description;
  final String time;
  final Color color;
  const _RouteStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
  });
}

class _TransitCard {
  final String name;
  final String location;
  final List<String> departures;
  final Color color;
  final IconData icon;
  const _TransitCard({
    required this.name,
    required this.location,
    required this.departures,
    required this.color,
    required this.icon,
  });
}

class _LogEntry {
  final String time;
  final String message;
  final bool critical;
  const _LogEntry(this.time, this.message, this.critical);
}
