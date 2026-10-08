import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incident_store.dart';

class SafeSpotsScreen extends StatefulWidget {
  const SafeSpotsScreen({super.key});
  @override
  State<SafeSpotsScreen> createState() => _SafeSpotsScreenState();
}

class _SafeSpotsScreenState extends State<SafeSpotsScreen> {
  final MapController _mapController = MapController();
  static const LatLng _sriLanka = LatLng(7.8731, 80.7718);

  final List<Map<String, dynamic>> _staticSpots = [
    {'lat': 6.9271, 'lng': 79.8612, 'name': 'Colombo Police HQ',
        'type': 'Police', 'open': '24/7', 'verified': true},
    {'lat': 6.9320, 'lng': 79.8640, 'name': 'Cargills Food City',
        'type': 'Store', 'open': '7AM–11PM', 'verified': true},
    {'lat': 6.9240, 'lng': 79.8590, 'name': 'Nawaloka Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
    {'lat': 6.9300, 'lng': 79.8680, 'name': 'Liberty Plaza',
        'type': 'Mall', 'open': '10AM–9PM', 'verified': true},
    {'lat': 6.8517, 'lng': 79.8651, 'name': 'Dehiwala Police Station',
        'type': 'Police', 'open': '24/7', 'verified': true},
    {'lat': 6.9380, 'lng': 79.8610, 'name': 'Lanka Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
    {'lat': 7.2906, 'lng': 80.6337, 'name': 'Kandy Police Station',
        'type': 'Police', 'open': '24/7', 'verified': true},
    {'lat': 7.2906, 'lng': 80.6400, 'name': 'Kandy National Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
    {'lat': 6.0535, 'lng': 80.2210, 'name': 'Galle Police Station',
        'type': 'Police', 'open': '24/7', 'verified': true},
    {'lat': 9.6615, 'lng': 80.0255, 'name': 'Jaffna Teaching Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
    {'lat': 8.5874, 'lng': 81.2152, 'name': 'Trincomalee Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
    {'lat': 8.3114, 'lng': 80.4037, 'name': 'Anuradhapura Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
    {'lat': 5.9549, 'lng': 80.5550, 'name': 'Matara Police Station',
        'type': 'Police', 'open': '24/7', 'verified': true},
    {'lat': 6.6806, 'lng': 80.3992, 'name': 'Ratnapura Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
    {'lat': 7.4867, 'lng': 80.3647, 'name': 'Kurunegala Hospital',
        'type': 'Hospital', 'open': '24/7', 'verified': true},
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

  Color _colorByType(String type) {
    switch (type) {
      case 'Police':   return const Color(0xFF00D4FF);
      case 'Hospital': return const Color(0xFFFF4444);
      case 'Store':    return const Color(0xFF00FF88);
      case 'Mall':     return const Color(0xFFFF8C00);
      default:         return const Color(0xFF00FF88);
    }
  }

  IconData _iconByType(String type) {
    switch (type) {
      case 'Police':   return Icons.local_police_outlined;
      case 'Hospital': return Icons.local_hospital_outlined;
      case 'Store':    return Icons.store_outlined;
      case 'Mall':     return Icons.shopping_bag_outlined;
      default:         return Icons.shield_outlined;
    }
  }

  void _showSpotDetail({
    required String name,
    required String type,
    required String open,
    required bool verified,
    required String description,
  }) {
    final color = _colorByType(type);
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
                  decoration: BoxDecoration(color: color,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(child: Text(name,
                  style: const TextStyle(color: Color(0xFFE2E8F0),
                      fontSize: 15, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 12),
            if (description.isNotEmpty) ...[
              Text(description,
                  style: const TextStyle(
                      color: Color(0xFF4A5568), fontSize: 13)),
              const SizedBox(height: 12),
            ],
            Row(children: [
              _InfoChip(label: type, color: color),
              const SizedBox(width: 8),
              _InfoChip(label: open, color: const Color(0xFF4A5568)),
              if (verified) ...[
                const SizedBox(width: 8),
                const _InfoChip(label: 'VERIFIED',
                    color: Color(0xFF00FF88)),
              ],
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF00FF88).withAlpha(40)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF00FF88).withAlpha(10),
              ),
              child: Row(children: [
                Icon(verified
                    ? Icons.verified_outlined
                    : Icons.people_outline,
                    color: const Color(0xFF00FF88), size: 16),
                const SizedBox(width: 10),
                Text(
                  verified
                      ? 'VERIFIED SAFE LOCATION'
                      : 'COMMUNITY REPORTED SAFE SPOT',
                  style: const TextStyle(color: Color(0xFF00FF88),
                      fontSize: 11, letterSpacing: 2,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communitySpots = IncidentStore().safeSpots;
    final totalCount = _staticSpots.length + communitySpots.length;

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
          const Text('SAFE SPOTS',
              style: TextStyle(fontSize: 14, letterSpacing: 4,
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w600)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF00FF88).withAlpha(60)),
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF00FF88).withAlpha(10),
            ),
            child: Text('$totalCount SPOTS',
                style: const TextStyle(color: Color(0xFF00FF88),
                    fontSize: 11, letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
                initialCenter: _sriLanka,
                initialZoom: 7.5),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

              // Static verified markers
              MarkerLayer(
                markers: _staticSpots.map((spot) {
                  final color = _colorByType(spot['type']);
                  return Marker(
                    point: LatLng(spot['lat'], spot['lng']),
                    width: 44, height: 44,
                    child: GestureDetector(
                      onTap: () => _showSpotDetail(
                        name: spot['name'],
                        type: spot['type'],
                        open: spot['open'],
                        verified: true,
                        description: '',
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withAlpha(30),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Icon(_iconByType(spot['type']),
                            color: color, size: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Community reported safe spots
              MarkerLayer(
                markers: communitySpots.map((inc) {
                  final color = _colorByType(
                      inc.safeSpotType ?? 'Safe Spot');
                  final icon = _iconByType(
                      inc.safeSpotType ?? 'Safe Spot');
                  return Marker(
                    point: LatLng(inc.lat, inc.lng),
                    width: 44, height: 44,
                    child: GestureDetector(
                      onTap: () => _showSpotDetail(
                        name: inc.customName ?? inc.type,
                        type: inc.safeSpotType ?? 'Safe Spot',
                        open: 'Community reported',
                        verified: false,
                        description: inc.description,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withAlpha(25),
                              border: Border.all(
                                  color: color, width: 1.5),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D1117),
                                border: Border.all(
                                    color: const Color(0xFF00FF88),
                                    width: 1),
                              ),
                              child: const Icon(Icons.people,
                                  color: Color(0xFF00FF88), size: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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
                  Text('SAFE ZONES',
                      style: TextStyle(color: Color(0xFF4A5568),
                          fontSize: 9, letterSpacing: 2)),
                  SizedBox(height: 8),
                  _LegendItem(color: Color(0xFF00D4FF),
                      label: 'Police Station'),
                  SizedBox(height: 5),
                  _LegendItem(color: Color(0xFFFF4444),
                      label: 'Hospital'),
                  SizedBox(height: 5),
                  _LegendItem(color: Color(0xFF00FF88),
                      label: 'Store / Verified'),
                  SizedBox(height: 5),
                  _LegendItem(color: Color(0xFFFF8C00),
                      label: 'Mall / Plaza'),
                ],
              ),
            ),
          ),

          // Count
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
                  Text('$totalCount',
                      style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Text('SPOTS',
                      style: TextStyle(color: Color(0xFF4A5568),
                          fontSize: 9, letterSpacing: 2)),
                  if (communitySpots.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('+${communitySpots.length} NEW',
                        style: const TextStyle(
                            color: Color(0xFF00FF88),
                            fontSize: 9, letterSpacing: 1)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110.0),
        child: FloatingActionButton(
          heroTag: 'safespots_loc_fab',
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
      Text(label, style: TextStyle(color: color, fontSize: 11)),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(4),
        color: color.withAlpha(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }
}