import 'package:flutter/material.dart';

class ActiveTripBanner extends StatefulWidget {
  final VoidCallback onEndTrip;

  const ActiveTripBanner({super.key, required this.onEndTrip});

  @override
  State<ActiveTripBanner> createState() => _ActiveTripBannerState();
}

class _ActiveTripBannerState extends State<ActiveTripBanner> {
  final DateTime _startTime = DateTime.now();

  String get _elapsed {
    final diff = DateTime.now().difference(_startTime);
    final m = diff.inMinutes.toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bike, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aktif Sürüş', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (_, __) => Text(_elapsed, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onEndTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }
}
