import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incident_store.dart';

class ReportScreen extends StatefulWidget {
  final void Function(bool) onMapPickerToggle;
  const ReportScreen({super.key, required this.onMapPickerToggle});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
final _searchController = TextEditingController();
  final _mapController = MapController();
    final _nameController = TextEditingController();

  String _selectedCategory = 'danger';
  String _selectedDangerType = 'Theft';
  String _selectedSafeType = 'Police';
  int _severity = 5;
  bool _submitted = false;
  bool _showMapPicker = false;

  LatLng _pickedLocation = const LatLng(6.9271, 79.8612);
  String _locationLabel = 'Tap map to select location';
  bool _locationPicked = false;
  bool _gettingGps = false;
  LatLng? _userLocation;

  final List<Map<String, dynamic>> _dangerTypes = [
    {'label': 'Theft',        'icon': Icons.wallet_outlined},
    {'label': 'Poor Lighting','icon': Icons.light_mode_outlined},
    {'label': 'Accident',     'icon': Icons.car_crash_outlined},
    {'label': 'Harassment',   'icon': Icons.person_off_outlined},
    {'label': 'Damaged Road', 'icon': Icons.construction_outlined},
    {'label': 'Other',        'icon': Icons.more_horiz},
  ];

  final List<Map<String, dynamic>> _safeTypes = [
    {'label': 'Police',           'icon': Icons.local_police_outlined,   'color': const Color(0xFF00D4FF)},
    {'label': 'Hospital',         'icon': Icons.local_hospital_outlined,  'color': const Color(0xFFFF4444)},
    {'label': 'Mall / Plaza',     'icon': Icons.shopping_bag_outlined,   'color': const Color(0xFFFF8C00)},
    {'label': 'Store',            'icon': Icons.store_outlined,          'color': const Color(0xFF00FF88)},
    {'label': 'Verified Spot',    'icon': Icons.verified_outlined,       'color': const Color(0xFF00FF88)},
    {'label': 'Community Report', 'icon': Icons.people_outline,          'color': const Color(0xFF00D4FF)},
    {'label': 'Other',            'icon': Icons.shield_outlined,         'color': const Color(0xFF4A5568)},
  ];

  Color get _severityColor {
    if (_severity >= 7) return const Color(0xFFFF4444);
    if (_severity >= 4) return const Color(0xFFFF8C00);
    return const Color(0xFF00FF88);
  }

  String get _severityLabel {
    if (_severity >= 7) return 'HIGH RISK';
    if (_severity >= 4) return 'MODERATE';
    return 'LOW RISK';
  }

  Color get _safeTypeColor {
    final match = _safeTypes.firstWhere(
        (t) => t['label'] == _selectedSafeType,
        orElse: () => _safeTypes.last);
    return match['color'] as Color;
  }

  
  void _searchCoordinates() {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    try {
      final parts = text.split(RegExp(r'[, ]+'));
      if (parts.length >= 2) {
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        final newPos = LatLng(lat, lng);
        setState(() {
          _pickedLocation = newPos;
          _userLocation = newPos;
          _locationLabel = '°N, °E';
          _locationPicked = true;
        });
        _mapController.move(newPos, 16);
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coordinates. Use format: lat, lng'),
          backgroundColor: Color(0xFFFF4444),
        ),
      );
    }
  }
void _onMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
      _locationLabel =
          '${position.latitude.toStringAsFixed(4)}°N, '
          '${position.longitude.toStringAsFixed(4)}°E';
      _locationPicked = true;
    });
  }

  void _openMapPicker() {
    widget.onMapPickerToggle(true);
    setState(() => _showMapPicker = true);
  }

  void _closeMapPicker() {
    widget.onMapPickerToggle(false);
    setState(() => _showMapPicker = false);
  }

  Future<void> _useMyLocation() async {
    setState(() => _gettingGps = true);
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable GPS.'),
              backgroundColor: Color(0xFFFF4444),
            ),
          );
        }
        setState(() => _gettingGps = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                backgroundColor: Color(0xFFFF4444),
              ),
            );
          }
          setState(() => _gettingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Enable in settings.'),
              backgroundColor: Color(0xFFFF4444),
            ),
          );
        }
        setState(() => _gettingGps = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final gpsLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedLocation = gpsLatLng;
        _userLocation = gpsLatLng;
        _locationLabel =
            '${position.latitude.toStringAsFixed(4)}°N, '
            '${position.longitude.toStringAsFixed(4)}°E';
        _locationPicked = true;
        _gettingGps = false;
        });
        _mapController.move(gpsLatLng, 16);

        debugPrint('📍 GPS Location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ GPS Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Error: $e'),
            backgroundColor: const Color(0xFFFF4444),
          ),
        );
      }
      setState(() => _gettingGps = false);
    }
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      final isSafe = _selectedCategory == 'safe';
      final incident = Incident(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lat: _pickedLocation.latitude,
        lng: _pickedLocation.longitude,
        type: isSafe ? _selectedSafeType : _selectedDangerType,
        severity: isSafe ? 1 : _severity,
        description: _descController.text,
        time: DateTime.now(),
        category: _selectedCategory,
        customName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        safeSpotType: isSafe ? _selectedSafeType : null,
      );
      IncidentStore().addIncident(incident);

      setState(() => _submitted = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            _severity = 5;
            _selectedDangerType = 'Theft';
            _selectedSafeType = 'Police';
            _selectedCategory = 'danger';
            _pickedLocation = const LatLng(6.9271, 79.8612);
            _locationLabel = 'Tap map to select location';
            _locationPicked = false;
          });
          _descController.clear();
          _nameController.clear();
        }
      });
    }
  }

  // ── Map picker screen ──
  Widget _buildMapPicker() {
    return Scaffold(
      backgroundColor: const Color(0xFF050A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF4A5568)),
          onPressed: _closeMapPicker,
        ),
        title: Row(children: [
          Container(width: 3, height: 18,
              decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('PICK LOCATION',
              style: TextStyle(fontSize: 14, letterSpacing: 4,
                  color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: const Color(0xFF00D4FF).withAlpha(40)),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
              mapController: _mapController,
              options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(6.9271, 79.8612),
              initialZoom: _userLocation != null ? 16 : 14,
              onTap: (_, point) => _onMapTap(point),
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

              // Picked location marker
              if (_locationPicked)
                MarkerLayer(markers: [
                  Marker(
                    point: _pickedLocation,
                    width: 40, height: 50,
                    child: Column(children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedCategory == 'safe'
                              ? const Color(0xFF00FF88)
                              : const Color(0xFFFF4444),
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                      ),
                      Container(
                        width: 2, height: 18,
                        color: _selectedCategory == 'safe'
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF4444),
                      ),
                    ]),
                  ),
                ]),
            ],
          ),

          // Instruction + GPS button
          Positioned(
            top: 16, left: 16, right: 16,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withAlpha(230),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF00D4FF).withAlpha(60)),
                ),
                child: const Row(children: [
                  Icon(Icons.touch_app_outlined,
                      color: Color(0xFF00D4FF), size: 16),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'TAP ANYWHERE ON THE MAP TO MARK LOCATION',
                    style: TextStyle(color: Color(0xFF00D4FF),
                        fontSize: 11, letterSpacing: 1.5,
                        fontWeight: FontWeight.bold),
                  )),
                ]),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _gettingGps ? null : _useMyLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117).withAlpha(230),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF00FF88).withAlpha(80)),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00FF88).withAlpha(15),
                        const Color(0xFF00D4FF).withAlpha(10),
                      ],
                    ),
                  ),
                  child: Row(children: [
                    _gettingGps
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00FF88),
                            ),
                          )
                        : const Icon(Icons.my_location,
                            color: Color(0xFF00FF88), size: 16),
                    const SizedBox(width: 10),
                    Text(
                      _gettingGps
                          ? 'GETTING GPS LOCATION...'
                          : 'USE MY CURRENT LOCATION',
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117).withAlpha(230),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4A5568).withAlpha(100)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search Lat, Lng (e.g. 6.9, 79.8)',
                            hintStyle: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onSubmitted: (_) => _searchCoordinates(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _searchCoordinates,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00D4FF).withAlpha(80)),
                        ),
                        child: const Icon(Icons.search, color: Color(0xFF00D4FF), size: 20),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ]),
          ),

          // Coords display
          if (_locationPicked)
            Positioned(
              bottom: 90, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withAlpha(230),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF00FF88).withAlpha(60)),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF00FF88), size: 16),
                  const SizedBox(width: 8),
                  Text(_locationLabel,
                      style: const TextStyle(
                          color: Color(0xFF00FF88), fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ]),
              ),
            ),

          // Confirm button
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: GestureDetector(
              onTap: _locationPicked ? _closeMapPicker : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _locationPicked
                        ? const Color(0xFF00FF88)
                        : const Color(0xFF1E2A35),
                  ),
                  color: _locationPicked
                      ? const Color(0xFF00FF88).withAlpha(20)
                      : const Color(0xFF0D1117),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _locationPicked
                          ? Icons.check_circle_outline
                          : Icons.touch_app_outlined,
                      color: _locationPicked
                          ? const Color(0xFF00FF88)
                          : const Color(0xFF2D3748),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _locationPicked
                          ? 'CONFIRM LOCATION'
                          : 'TAP MAP TO SELECT',
                      style: TextStyle(
                        color: _locationPicked
                            ? const Color(0xFF00FF88)
                            : const Color(0xFF2D3748),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3, fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showMapPicker) return _buildMapPicker();

    return Scaffold(
      backgroundColor: const Color(0xFF050A0E),
      appBar: _futuristicAppBar('REPORT INCIDENT'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Success banner
              if (_submitted) ...[
                const _GlowCard(
                  accentColor: Color(0xFF00FF88),
                  child: Row(children: [
                    Icon(Icons.check_circle_outline,
                        color: Color(0xFF00FF88)),
                    SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REPORT TRANSMITTED',
                            style: TextStyle(color: Color(0xFF00FF88),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2, fontSize: 12)),
                        SizedBox(height: 2),
                        Text('Portal, Heatmap & Safe Spots updated',
                            style: TextStyle(color: Color(0xFF4A5568),
                                fontSize: 12)),
                      ],
                    )),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // ── Category toggle ──
              const _SectionLabel(label: 'REPORT CATEGORY'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _CategoryButton(
                  label: 'DANGER ZONE',
                  icon: Icons.warning_amber_outlined,
                  color: const Color(0xFFFF4444),
                  selected: _selectedCategory == 'danger',
                  onTap: () => setState(() => _selectedCategory = 'danger'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _CategoryButton(
                  label: 'SAFE SPOT',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF00FF88),
                  selected: _selectedCategory == 'safe',
                  onTap: () => setState(() => _selectedCategory = 'safe'),
                )),
              ]),
              const SizedBox(height: 24),

              // ── Danger types ──
              if (_selectedCategory == 'danger') ...[
                const _SectionLabel(label: 'INCIDENT TYPE'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _dangerTypes.map((t) {
                    final isSelected = _selectedDangerType == t['label'];
                    return _TypeChip(
                      label: t['label'],
                      icon: t['icon'] as IconData,
                      color: const Color(0xFFFF4444),
                      selected: isSelected,
                      onTap: () => setState(
                          () => _selectedDangerType = t['label']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // ── Safe spot types ──
              if (_selectedCategory == 'safe') ...[
                const _SectionLabel(label: 'SAFE SPOT TYPE'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _safeTypes.map((t) {
                    final isSelected = _selectedSafeType == t['label'];
                    return _TypeChip(
                      label: t['label'],
                      icon: t['icon'] as IconData,
                      color: t['color'] as Color,
                      selected: isSelected,
                      onTap: () => setState(
                          () => _selectedSafeType = t['label']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Custom name field
                const _SectionLabel(label: 'SPOT NAME (OPTIONAL)'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Keells Super Nugegoda, My School...',
                    hintStyle: const TextStyle(
                        color: Color(0xFF2D3748), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    prefixIcon: Icon(Icons.edit_outlined,
                        color: _safeTypeColor, size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF1E2A35))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF1E2A35))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: _safeTypeColor, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Description ──
              const _SectionLabel(label: 'DESCRIPTION'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(
                    color: Color(0xFFE2E8F0), fontSize: 14),
                decoration: InputDecoration(
                  hintText: _selectedCategory == 'safe'
                      ? 'Why is this place safe? Opening hours?'
                      : 'Describe what happened...',
                  hintStyle: const TextStyle(
                      color: Color(0xFF2D3748), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E2A35))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E2A35))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF00D4FF), width: 1.5)),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Description required'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Severity (danger only) ──
              if (_selectedCategory == 'danger') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel(label: 'THREAT LEVEL'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _severityColor.withAlpha(120)),
                        borderRadius: BorderRadius.circular(4),
                        color: _severityColor.withAlpha(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min,
                          children: [
                        Container(width: 6, height: 6,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _severityColor)),
                        const SizedBox(width: 6),
                        Text('$_severityLabel  $_severity/10',
                            style: TextStyle(color: _severityColor,
                                fontSize: 11, fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbColor: _severityColor,
                    activeTrackColor: _severityColor,
                    inactiveTrackColor: const Color(0xFF1E2A35),
                    overlayColor: _severityColor.withAlpha(25),
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _severity.toDouble(),
                    min: 1, max: 10, divisions: 9,
                    onChanged: (v) =>
                        setState(() => _severity = v.round()),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Location picker ──
              const _SectionLabel(label: 'LOCATION'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openMapPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _locationPicked
                          ? const Color(0xFF00FF88).withAlpha(100)
                          : const Color(0xFF1E2A35),
                    ),
                    color: _locationPicked
                        ? const Color(0xFF00FF88).withAlpha(10)
                        : const Color(0xFF0D1117),
                  ),
                  child: Row(children: [
                    Icon(
                      _locationPicked
                          ? Icons.location_on
                          : Icons.add_location_alt_outlined,
                      color: _locationPicked
                          ? const Color(0xFF00FF88)
                          : const Color(0xFF4A5568),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationPicked
                              ? 'LOCATION MARKED'
                              : 'TAP TO MARK ON MAP',
                          style: TextStyle(
                            color: _locationPicked
                                ? const Color(0xFF00FF88)
                                : const Color(0xFF4A5568),
                            fontSize: 11, letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(_locationLabel,
                            style: const TextStyle(
                                color: Color(0xFF4A5568), fontSize: 11)),
                      ],
                    )),
                    Icon(Icons.chevron_right,
                        color: _locationPicked
                            ? const Color(0xFF00FF88)
                            : const Color(0xFF2D3748)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // ── Submit ──
              GestureDetector(
                onTap: _submitted ? null : _submitReport,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _submitted
                          ? const Color(0xFF00FF88)
                          : const Color(0xFF00FF88).withAlpha(150),
                    ),
                    color: _submitted
                        ? const Color(0xFF00FF88).withAlpha(20)
                        : const Color(0xFF00FF88).withAlpha(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _submitted ? Icons.check : Icons.send_outlined,
                        color: const Color(0xFF00FF88), size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _submitted ? 'TRANSMITTED' : 'TRANSMIT REPORT',
                        style: const TextStyle(
                            color: Color(0xFF00FF88),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──

class _CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryButton({required this.label, required this.icon,
      required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? color : const Color(0xFF1E2A35),
              width: selected ? 1.5 : 1),
          color: selected ? color.withAlpha(15) : const Color(0xFF0D1117),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? color : const Color(0xFF4A5568),
              size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: selected ? color : const Color(0xFF4A5568),
                  fontSize: 11, fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
        ]),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.icon,
      required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? color : const Color(0xFF1E2A35),
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(8),
          color: selected ? color.withAlpha(15) : const Color(0xFF0D1117),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14,
              color: selected ? color : const Color(0xFF4A5568)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, letterSpacing: 1,
                  color: selected ? color : const Color(0xFF4A5568),
                  fontWeight: selected
                      ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(color: Color(0xFF4A5568),
          fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold));
}

class _GlowCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  const _GlowCard({required this.child, required this.accentColor});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withAlpha(60)),
        color: accentColor.withAlpha(10),
      ),
      child: child);
}

AppBar _futuristicAppBar(String title) {
  return AppBar(
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
      Text(title, style: const TextStyle(fontSize: 14, letterSpacing: 4,
          color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600)),
    ]),
    actions: [
      Padding(padding: const EdgeInsets.only(right: 16),
          child: Container(width: 8, height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00FF88)))),
    ],
  );
}