import 'package:flutter/material.dart';

import '../../data/models/trip_summary_model.dart';

class TripSummaryScreen extends StatelessWidget {
  final TripSummary summary;

  const TripSummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Yolculuk Tamamlandı'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _BadgeCard(summary: summary),
            const SizedBox(height: 16),
            _CostCard(cost: summary.cost),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _StatCard(
                  icon: Icons.route,
                  label: 'Mesafe',
                  value: '${summary.distanceKm.toStringAsFixed(1)} km',
                  color: const Color(0xFF3B82F6),
                ),
                _StatCard(
                  icon: Icons.timer,
                  label: 'Süre',
                  value: '${summary.durationMinutes} dk',
                  color: const Color(0xFFF59E0B),
                ),
                _StatCard(
                  icon: Icons.eco,
                  label: 'CO₂ Tasarrufu',
                  value: '${summary.carbonSavingKg.toStringAsFixed(2)} kg',
                  color: const Color(0xFF22C55E),
                ),
                _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Yakılan Kalori',
                  value: '${summary.caloriesBurned} kcal',
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.pointsEarned > 0)
              _PointsBanner(points: summary.pointsEarned),
            if ((summary.transferSuggestion ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              _TransferCard(suggestion: summary.transferSuggestion!),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final TripSummary summary;
  const _BadgeCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            'Trip ${summary.tripId}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sürüş başarıyla tamamlandı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  final double cost;
  const _CostCard({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text('Toplam Ücret', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '₺${cost.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  final int points;
  const _PointsBanner({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            '+$points puan kazandınız!',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final String suggestion;
  const _TransferCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_transit, color: Colors.lightBlueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktarma Önerisi',
                  style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(suggestion, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
