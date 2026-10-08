import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incident_store.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});
  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  String _selectedFilter = 'All';
  final MapController _mapController = MapController();
  static const LatLng _sriLanka = LatLng(7.8731, 80.7718);

  final List<String> _filters = [
    'All', 'Theft', 'Poor Lighting', 'Accident',
    'Harassment', 'Damaged Road', 'Other'
  ];

  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    IncidentStore().addListener(_refresh);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation({bool promptUser = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!promptUser) return;
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_userLocation!, 12);
      }
    } catch (e) {
      debugPrint('GPS Error: $e');
    }
  }

  @override
  void dispose() {
    IncidentStore().removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Color _colorBySeverity(int s) {
    if (s >= 7) return const Color(0xFFFF4444);
    if (s >= 4) return const Color(0xFFFF8C00);
    return const Color(0xFF00FF88);
  }

  List<Incident> get _filteredIncidents {
    final dangers = IncidentStore().dangers;
    if (_selectedFilter == 'All') return dangers;
    return dangers.where((i) => i.type == _selectedFilter).toList();
  }

  void _showDetail(Incident incident) {
    final color = _colorBySeverity(incident.severity);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 3, height: 18,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(incident.type.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 14,
                      fontWeight: FontWeight.bold, letterSpacing: 3)),
            ]),
            const SizedBox(height: 14),
            Text(incident.description,
                style: const TextStyle(
                    color: Color(0xFFE2E8F0), fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: color.withAlpha(100)),
                  borderRadius: BorderRadius.circular(4),
                  color: color.withAlpha(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 6),
                  Text('SEVERITY  ${incident.severity}/10',
                      style: TextStyle(color: color, fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ]),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined,
                  size: 13, color: Color(0xFF4A5568)),
              const SizedBox(width: 4),
              Text(
                '${incident.lat.toStringAsFixed(3)}°N, '
                '${incident.lng.toStringAsFixed(3)}°E',
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 11)),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidents = _filteredIncidents;

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
              decoration: BoxDecoration(
                  color: const Color(0xFFFF4444),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('HEATMAP',
              style: TextStyle(fontSize: 14, letterSpacing: 4,
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w600)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(width: 8, height: 8,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00FF88))),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _sriLanka,
              initialZoom: 7.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                  'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key=1648ce0e-4ba8-46c6-9749-9a2a24b5142e',
                userAgentPackageName: 'com.saferoute.lk',
              ),

              // User's GPS location marker (blue pulse)
              if (_userLocation != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _userLocation!,
                    radius: 60,
                    color: const Color(0xFF00D4FF).withAlpha(25),
                    borderColor: const Color(0xFF00D4FF).withAlpha(60),
                    borderStrokeWidth: 1,
                    useRadiusInMeter: true,
                  ),
                ]),
              if (_userLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _userLocation!,
                    width: 20, height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00D4FF),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4FF).withAlpha(120),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),

              // Heatmap circles
              CircleLayer(
                circles: incidents.map((inc) {
                  final color = _colorBySeverity(inc.severity);
                  return CircleMarker(
                    point: LatLng(inc.lat, inc.lng),
                    radius: inc.severity * 80.0,
                    color: color.withAlpha(60),
                    borderColor: color.withAlpha(160),
                    borderStrokeWidth: 1.5,
                    useRadiusInMeter: true,
                  );
                }).toList(),
              ),

              // Severity markers
              MarkerLayer(
                markers: incidents.map((inc) {
                  final color = _colorBySeverity(inc.severity);
                  return Marker(
                    point: LatLng(inc.lat, inc.lng),
                    width: 32, height: 32,
                    child: GestureDetector(
                      onTap: () => _showDetail(inc),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withAlpha(30),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Center(
                          child: Text('${inc.severity}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Filter chips
          Positioned(
            top: 12, left: 12, right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00FF88)
                              : const Color(0xFF1E2A35),
                        ),
                        color: isSelected
                            ? const Color(0xFF00FF88).withAlpha(20)
                            : const Color(0xFF0D1117).withAlpha(220),
                      ),
                      child: Text(f,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00FF88)
                                : const Color(0xFF4A5568),
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            letterSpacing: 1,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Legend
          Positioned(
            bottom: 20, left: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117).withAlpha(230),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E2A35)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('THREAT ZONES',
                      style: TextStyle(color: Color(0xFF4A5568),
                          fontSize: 9, letterSpacing: 2)),
                  SizedBox(height: 8),
                  _LegendItem(color: Color(0xFFFF4444),
                      label: 'HIGH  7–10'),
                  SizedBox(height: 5),
                  _LegendItem(color: Color(0xFFFF8C00),
                      label: 'MED   4–6'),
                  SizedBox(height: 5),
                  _LegendItem(color: Color(0xFF00FF88),
                      label: 'LOW   1–3'),
                ],
              ),
            ),
          ),

          // Zone count
          Positioned(
            bottom: 20, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117).withAlpha(230),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E2A35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${incidents.length}',
                      style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Text('ZONES',
                      style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 9, letterSpacing: 2)),
                  if (IncidentStore().dangers.length > 5) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${IncidentStore().dangers.length - 5} NEW',
                      style: const TextStyle(
                          color: Color(0xFFFF4444),
                          fontSize: 9, letterSpacing: 1),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Empty state
          if (incidents.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withAlpha(220),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2A35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF00FF88), size: 32),
                    const SizedBox(height: 10),
                    Text(
                      _selectedFilter == 'All'
                          ? 'NO INCIDENTS REPORTED'
                          : 'NO $_selectedFilter INCIDENTS',
                      style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Area is clear',
                        style: TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110.0),
        child: FloatingActionButton(
          heroTag: 'heatmap_loc_fab',
          onPressed: () {
            if (_userLocation != null) {
              _mapController.move(_userLocation!, 14);
            } else {
              _getCurrentLocation(promptUser: true);
            }
          },
          backgroundColor: const Color(0xFF0D1117),
          child: const Icon(Icons.my_location, color: Color(0xFF00FF88)),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
          color: color, fontSize: 11, letterSpacing: 1)),
    ]);
  }
}