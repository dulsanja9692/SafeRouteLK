import 'package:flutter/material.dart';
import '../models/incident_store.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});
  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    IncidentStore().addListener(_refresh);
  }

  @override
  void dispose() {
    IncidentStore().removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final store = IncidentStore();
    final all = store.all;

    final filtered = _filter == 'All'
        ? all
        : _filter == 'Danger'
            ? store.dangers
            : store.safeSpots;

    return Scaffold(
      backgroundColor: const Color(0xFF050A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: const Color(0xFF00FF88).withAlpha(30)),
        ),
        title: Row(children: [
          Container(width: 3, height: 18,
              decoration: BoxDecoration(color: const Color(0xFF00FF88),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('CITIZEN PORTAL',
              style: TextStyle(fontSize: 14, letterSpacing: 4,
                  color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF00FF88).withAlpha(60)),
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF00FF88).withAlpha(10),
            ),
            child: Text('${all.length} ACTIVE',
                style: const TextStyle(color: Color(0xFF00FF88),
                    fontSize: 11, letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats + filter row
          Container(
            color: const Color(0xFF0D1117),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(children: [
              _StatBadge(
                  label: 'ALL',
                  count: all.length,
                  color: const Color(0xFF4A5568),
                  selected: _filter == 'All',
                  onTap: () => setState(() => _filter = 'All')),
              const SizedBox(width: 8),
              _StatBadge(
                  label: 'DANGER',
                  count: store.dangers.length,
                  color: const Color(0xFFFF4444),
                  selected: _filter == 'Danger',
                  onTap: () => setState(() => _filter = 'Danger')),
              const SizedBox(width: 8),
              _StatBadge(
                  label: 'SAFE',
                  count: store.safeSpots.length,
                  color: const Color(0xFF00FF88),
                  selected: _filter == 'Safe',
                  onTap: () => setState(() => _filter = 'Safe')),
              const Spacer(),
              const Text('LIVE',
                  style: TextStyle(color: Color(0xFF2D3748),
                      fontSize: 10, letterSpacing: 2)),
              const SizedBox(width: 6),
              Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00FF88))),
            ]),
          ),
          Container(height: 1, color: const Color(0xFF1E2A35)),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('NO REPORTS YET',
                        style: TextStyle(color: Color(0xFF2D3748),
                            letterSpacing: 3, fontSize: 12)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _IncidentCard(incident: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatBadge({required this.label, required this.count,
      required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? color : color.withAlpha(60)),
          borderRadius: BorderRadius.circular(4),
          color: selected ? color.withAlpha(20) : color.withAlpha(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text('$label  $count',
              style: TextStyle(color: color, fontSize: 11,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  const _IncidentCard({required this.incident});

  Color get _color {
    if (incident.category == 'safe') return const Color(0xFF00FF88);
    if (incident.severity >= 7) return const Color(0xFFFF4444);
    if (incident.severity >= 4) return const Color(0xFFFF8C00);
    return const Color(0xFF00FF88);
  }

  String get _riskLabel {
    if (incident.category == 'safe') return 'SAFE';
    if (incident.severity >= 7) return 'HIGH';
    if (incident.severity >= 4) return 'MED';
    return 'LOW';
  }

  IconData get _typeIcon {
    switch (incident.type) {
      case 'Theft': return Icons.wallet_outlined;
      case 'Poor Lighting': return Icons.light_mode_outlined;
      case 'Accident': return Icons.car_crash_outlined;
      case 'Harassment': return Icons.person_off_outlined;
      case 'Damaged Road': return Icons.construction_outlined;
      case 'Safe Spot': return Icons.shield_outlined;
      default: return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withAlpha(40)),
        color: const Color(0xFF0D1117),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _color.withAlpha(80)),
            color: _color.withAlpha(15),
          ),
          child: incident.category == 'safe'
              ? Icon(Icons.shield_outlined, color: _color, size: 18)
              : Center(
                  child: Text('${incident.severity}',
                      style: TextStyle(color: _color,
                          fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(_typeIcon, size: 13, color: const Color(0xFF4A5568)),
                const SizedBox(width: 5),
                Text(incident.type.toUpperCase(),
                    style: const TextStyle(color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.bold,
                        fontSize: 12, letterSpacing: 1.5)),
              ]),
              const SizedBox(height: 4),
              Text(incident.description,
                  style: const TextStyle(
                      color: Color(0xFF4A5568), fontSize: 12)),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 11, color: Color(0xFF2D3748)),
                const SizedBox(width: 3),
                Text(
                  '${incident.lat.toStringAsFixed(3)}°N, '
                  '${incident.lng.toStringAsFixed(3)}°E',
                  style: const TextStyle(
                      color: Color(0xFF2D3748), fontSize: 11)),
              ]),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: _color.withAlpha(80)),
            borderRadius: BorderRadius.circular(4),
            color: _color.withAlpha(15),
          ),
          child: Text(_riskLabel,
              style: TextStyle(color: _color, fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
      ]),
    );
  }
}