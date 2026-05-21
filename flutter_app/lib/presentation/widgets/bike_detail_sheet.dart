import 'package:flutter/material.dart';
import '../../data/models/bike_model.dart';

class BikeDetailSheet extends StatelessWidget {
  final BikeModel bike;
  final VoidCallback onRent;

  const BikeDetailSheet({super.key, required this.bike, required this.onRent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.directions_bike, size: 40, color: Color(0xFF22C55E)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bisiklet #${bike.serialNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'Durum: ${bike.status == 'available' ? 'Müsait' : bike.status}',
                    style: TextStyle(color: bike.status == 'available' ? Colors.green[600] : Colors.orange[700]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoCard(icon: Icons.battery_charging_full, label: 'Batarya', value: '%${bike.batteryLevel}'),
              _InfoCard(icon: Icons.attach_money, label: 'Ücret', value: '₺0.50/dk'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRent,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Kilidi Aç', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF22C55E), size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
