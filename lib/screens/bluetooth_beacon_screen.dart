import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothBeaconScreen extends StatefulWidget {
  const BluetoothBeaconScreen({super.key});

  @override
  State<BluetoothBeaconScreen> createState() => _BluetoothBeaconScreenState();
}

class _BluetoothBeaconScreenState extends State<BluetoothBeaconScreen> {
  final List<ScanResult> _devices = [];
  final List<int> _rssiHistory = [];

  ScanResult? _selected;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _rssiTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();
  BluetoothCharacteristic? connectedCharacteristic;

  bool _scanning = false;
  bool _isConnected = false;
  bool _isPlayingAlert = false;
  bool _warningAlarmSent = false;

  String _connStatus = 'Disconnected';
  String _distanceLabel = 'Idle';
  String _distanceMessage =
      'Scan and connect to a BLE device to start monitoring.';
  int? _liveRssi;

  String _pendingZone = '';
  int _pendingZoneCount = 0;
  String _currentZone = '';

  @override
  void initState() {
    super.initState();
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _rssiTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _findDevices() async {
    if (_scanning) return;

    setState(() {
      _devices.clear();
      _selected = null;
      _scanning = true;
      _isConnected = false;
      connectedCharacteristic = null;
      _warningAlarmSent = false;
      _connStatus = 'Scanning...';
      _distanceLabel = 'Scanning';
      _distanceMessage = 'Looking for nearby BLE devices...';
      _liveRssi = null;
      _rssiHistory.clear();
      _pendingZone = '';
      _pendingZoneCount = 0;
      _currentZone = '';
    });

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          _devices
            ..clear()
            ..addAll(results);
        });
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() {
        _scanning = false;
        _connStatus = 'Disconnected';
        if (_devices.isEmpty) {
          _distanceLabel = 'No Devices';
          _distanceMessage =
              'No BLE devices found. Keep Bluetooth and Location turned on.';
        } else {
          _distanceLabel = 'Ready';
          _distanceMessage = 'Select a device and tap Connect.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _connStatus = 'Disconnected';
        _distanceLabel = 'Scan Failed';
        _distanceMessage = 'Could not scan for BLE devices.';
      });
      _showSnack('Scan failed: $e');
    }
  }

  Future<void> _connectBeacon() async {
    if (_selected == null) {
      _showSnack('Select a device first');
      return;
    }

    try {
      await FlutterBluePlus.stopScan();

      setState(() {
        _connStatus = 'Connecting...';
        _distanceLabel = 'Connecting';
        _distanceMessage = 'Trying to connect to ${_deviceName(_selected!)}';
      });

      await _selected!.device.connect(
        timeout: const Duration(seconds: 10),
      );

      connectedCharacteristic = null;
      _warningAlarmSent = false;

      final services = await _selected!.device.discoverServices();

      for (final service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        if (serviceUuid.contains('1234')) {
          for (final characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toString().toLowerCase();
            if (charUuid.contains('5678')) {
              connectedCharacteristic = characteristic;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _isConnected = true;
        _connStatus = 'Connected';
        _distanceLabel = 'Connected';
        _distanceMessage = 'Live monitoring has started.';
      });

      _showSnack('Connected to ${_deviceName(_selected!)}');
      _startRssiMonitoring();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _connStatus = 'Connection Failed';
        _distanceLabel = 'Connection Failed';
        _distanceMessage = 'Could not connect to the selected device.';
      });
      _showSnack('Connection failed: $e');
    }
  }

  void _startRssiMonitoring() {
    _rssiTimer?.cancel();
    _rssiHistory.clear();
    _pendingZone = '';
    _pendingZoneCount = 0;
    _currentZone = '';
    _warningAlarmSent = false;

    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isConnected || _selected == null) return;

      try {
        final rssi = await _selected!.device.readRssi();
        _updateDistanceUi(rssi);
      } catch (e) {
        timer.cancel();
        await _sendStopToEsp32();

        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _connStatus = 'Disconnected';
          _distanceLabel = 'Disconnected';
          _distanceMessage = 'Connection lost while monitoring RSSI.';
        });
        _showSnack('RSSI read failed: $e');
      }
    });
  }

  void _updateDistanceUi(int rssi) {
    _rssiHistory.add(rssi);
    if (_rssiHistory.length > 3) {
      _rssiHistory.removeAt(0);
    }

    final avgRssi = _getAverageRssi();
    final newZone = _zoneFromRssi(avgRssi);

    if (newZone != _currentZone) {
      if (_pendingZone == newZone) {
        _pendingZoneCount++;
      } else {
        _pendingZone = newZone;
        _pendingZoneCount = 1;
      }

      if (_pendingZoneCount >= 1) {
        _currentZone = newZone;
        _pendingZone = '';
        _pendingZoneCount = 0;

        setState(() {
          _liveRssi = avgRssi.round();
          _distanceLabel = newZone;
          _distanceMessage = _messageFromZone(newZone, avgRssi);
        });

        _triggerFeedback(newZone);

        if (newZone == 'Warning') {
          _showSnack('Warning: Device is far away!');
        } else if (newZone == 'Medium / Far') {
          _showSnack('Notice: Device distance increased.');
        }
      } else {
        setState(() {
          _liveRssi = avgRssi.round();
        });
      }
    } else {
      _pendingZone = '';
      _pendingZoneCount = 0;

      setState(() {
        _liveRssi = avgRssi.round();
        _distanceLabel = newZone;
        _distanceMessage = _messageFromZone(newZone, avgRssi);
      });

      if (newZone == 'Warning') {
        _ensureWarningAlarm();
      } else {
        _ensureWarningStopped();
      }
    }
  }

  double _getAverageRssi() {
    if (_rssiHistory.isEmpty) return -100;
    final sum = _rssiHistory.reduce((a, b) => a + b);
    return sum / _rssiHistory.length;
  }

  String _zoneFromRssi(double rssi) {
    if (rssi >= -55) return 'Very Near';
    if (rssi >= -65) return 'Near';
    if (rssi >= -75) return 'Medium / Far';
    return 'Warning';
  }

  String _messageFromZone(String zone, double rssi) {
    final value = rssi.toStringAsFixed(1);

    switch (zone) {
      case 'Very Near':
        return 'Device is very close. Signal is strong. (RSSI: $value)';
      case 'Near':
        return 'Device is near. Signal is stable. (RSSI: $value)';
      case 'Medium / Far':
        return 'Device is getting farther. Keep an eye on it. (RSSI: $value)';
      case 'Warning':
        return 'Device is far away. Please check immediately. (RSSI: $value)';
      case 'Ready':
        return 'Select a device and tap Connect.';
      case 'No Devices':
        return 'No BLE devices found.';
      default:
        return _distanceMessage;
    }
  }

  Future<void> _triggerFeedback(String zone) async {
    if (zone == 'Medium / Far') {
      await HapticFeedback.heavyImpact();
      await _sendStopToEsp32();
    } else if (zone == 'Warning') {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
      await _playAlertSound();
      await _sendAlertToEsp32();
    } else {
      await _sendStopToEsp32();
    }
  }

  Future<void> _ensureWarningAlarm() async {
    if (!_warningAlarmSent) {
      await _sendAlertToEsp32();
    }
  }

  Future<void> _ensureWarningStopped() async {
    if (_warningAlarmSent) {
      await _sendStopToEsp32();
    }
  }

  Future<void> _sendAlertToEsp32() async {
    try {
      if (connectedCharacteristic != null && !_warningAlarmSent) {
        await connectedCharacteristic!.write(
          utf8.encode("ALERT"),
        );
        _warningAlarmSent = true;
      }
    } catch (e) {
      print("Send ALERT failed: $e");
    }
  }

  Future<void> _sendStopToEsp32() async {
    try {
      if (connectedCharacteristic != null && _warningAlarmSent) {
        await connectedCharacteristic!.write(
          utf8.encode("STOP"),
        );
      }
    } catch (e) {
      print("Send STOP failed: $e");
    } finally {
      _warningAlarmSent = false;
    }
  }

  Future<void> _playAlertSound() async {
    if (_isPlayingAlert) return;

    try {
      _isPlayingAlert = true;
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    } finally {
      _isPlayingAlert = false;
    }
  }

  void _showBeaconDetails() {
    if (_selected == null) {
      _showSnack('Select a device first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeaconDetailsPage(
          device: _selected!,
          currentRssi: _liveRssi ?? _selected!.rssi,
          distanceLabel: _distanceLabel,
          distanceMessage: _distanceMessage,
        ),
      ),
    );
  }

  String _deviceName(ScanResult result) {
    if (result.device.platformName.isNotEmpty) {
      return result.device.platformName;
    }
    if (result.advertisementData.advName.isNotEmpty) {
      return result.advertisementData.advName;
    }
    return '(unknown)';
  }

  Color _zoneColor() {
    switch (_distanceLabel) {
      case 'Very Near':
        return const Color(0xFF22C55E);
      case 'Near':
        return const Color(0xFF14B8A6);
      case 'Medium / Far':
        return const Color(0xFFF59E0B);
      case 'Warning':
        return const Color(0xFFEF4444);
      case 'Connected':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _zoneIcon() {
    switch (_distanceLabel) {
      case 'Very Near':
        return Icons.gps_fixed_rounded;
      case 'Near':
        return Icons.near_me_rounded;
      case 'Medium / Far':
        return Icons.warning_amber_rounded;
      case 'Warning':
        return Icons.notifications_active_rounded;
      case 'Connected':
        return Icons.bluetooth_connected_rounded;
      default:
        return Icons.bluetooth_searching_rounded;
    }
  }

  double _gaugeProgress() {
    final value = (_liveRssi ?? -100).toDouble();
    const min = -100.0;
    const max = -40.0;
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return normalized;
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF312E81),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoneColor = _zoneColor();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF090D1A),
              Color(0xFF131B37),
              Color(0xFF1B1464),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                        ),
                      ),
                      child: const Icon(Icons.bluetooth, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beacon Guard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Live distance monitoring',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    _buildHeroCard(zoneColor),
                    const SizedBox(height: 16),
                    _buildActionRow(),
                    const SizedBox(height: 16),
                    _buildQuickInfoCards(),
                    const SizedBox(height: 20),
                    const Text(
                      'Available Devices',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_devices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141A2E),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            'No devices found.',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ..._devices.map((d) {
                        final selected =
                            _selected?.device.remoteId == d.device.remoteId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _deviceCard(d, selected),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(Color zoneColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B1464),
            Color(0xFF171F4A),
            Color(0xFF10172C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: zoneColor.withOpacity(0.18),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statusPill(
                _isConnected ? 'Connected' : _connStatus,
                _isConnected ? const Color(0xFF22C55E) : const Color(0xFF64748B),
              ),
              const Spacer(),
              Icon(
                _zoneIcon(),
                color: zoneColor,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 210,
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(210, 210),
                    painter: RssiGaugePainter(
                      progress: _gaugeProgress(),
                      color: zoneColor,
                    ),
                  ),
                  Container(
                    width: 134,
                    height: 134,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF2B2F77),
                          Color(0xFF191E42),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: zoneColor.withOpacity(0.22),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _liveRssi == null ? '--' : '$_liveRssi',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'RSSI',
                          style: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _distanceLabel,
            style: TextStyle(
              color: zoneColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _distanceMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            title: _scanning ? 'Scanning...' : 'Find',
            icon: _scanning ? Icons.sync : Icons.search_rounded,
            color1: const Color(0xFF7C3AED),
            color2: const Color(0xFFA855F7),
            onTap: _scanning ? null : _findDevices,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            title: 'Details',
            icon: Icons.info_outline_rounded,
            color1: const Color(0xFFEC4899),
            color2: const Color(0xFFF59E0B),
            onTap: _showBeaconDetails,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            title: 'Connect',
            icon: Icons.bluetooth_connected_rounded,
            color1: const Color(0xFF06B6D4),
            color2: const Color(0xFF22C55E),
            onTap: _connectBeacon,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _miniCard(
            'Live RSSI',
            _liveRssi == null ? '--' : '$_liveRssi',
            Icons.network_check_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniCard(
            'Selected',
            _selected == null ? 'None' : _deviceName(_selected!),
            Icons.devices_other_rounded,
          ),
        ),
      ],
    );
  }

  Widget _miniCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141A2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: [color1, color2]),
            boxShadow: [
              BoxShadow(
                color: color1.withOpacity(0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceCard(ScanResult d, bool selected) {
    final name = _deviceName(d);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF22C55E)],
              )
            : null,
        color: selected ? null : const Color(0xFF141A2E),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141A2E),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'ID: ${d.device.remoteId.str}\nScan RSSI: ${d.rssi}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          trailing: selected
              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E))
              : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          onTap: () => setState(() => _selected = d),
        ),
      ),
    );
  }
}

class BeaconDetailsPage extends StatelessWidget {
  final ScanResult device;
  final int currentRssi;
  final String distanceLabel;
  final String distanceMessage;

  const BeaconDetailsPage({
    super.key,
    required this.device,
    required this.currentRssi,
    required this.distanceLabel,
    required this.distanceMessage,
  });

  String _deviceName(ScanResult result) {
    if (result.device.platformName.isNotEmpty) {
      return result.device.platformName;
    }
    if (result.advertisementData.advName.isNotEmpty) {
      return result.advertisementData.advName;
    }
    return '(unknown)';
  }

  @override
  Widget build(BuildContext context) {
    final name = _deviceName(device);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF090D1A),
              Color(0xFF131B37),
              Color(0xFF1B1464),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Beacon Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A2E),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Device Name', name),
                      const SizedBox(height: 16),
                      _detailRow('Device ID', device.device.remoteId.str),
                      const SizedBox(height: 16),
                      _detailRow('Live RSSI', '$currentRssi'),
                      const SizedBox(height: 16),
                      _detailRow('Distance Status', distanceLabel),
                      const SizedBox(height: 16),
                      _detailRow('Message', distanceMessage),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class RssiGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  RssiGaugePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 16.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final basePaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi * 0.75,
        endAngle: math.pi * 0.75,
        colors: [
          color.withOpacity(0.3),
          color,
          Colors.white,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      basePaint,
    );

    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RssiGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
