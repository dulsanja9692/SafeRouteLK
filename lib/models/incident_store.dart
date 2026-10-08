import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class Incident {
  final String id;
  final double lat;
  final double lng;
  final String type;
  final int severity;
  final String description;
  final DateTime time;
  final String category;
  final String? customName;
  final String? safeSpotType;
  final String? source;

  Incident({
    required this.id,
    required this.lat,
    required this.lng,
    required this.type,
    required this.severity,
    required this.description,
    required this.time,
    required this.category,
    this.customName,
    this.safeSpotType,
    this.source,
  });

  String get displayName =>
      customName != null && customName!.isNotEmpty
          ? customName!
          : type;

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type'] ?? 'Other',
      severity: (json['severity'] as num).toInt(),
      description: json['description'] ?? '',
      time: DateTime.tryParse(json['timestamp'] ?? '') ??
          DateTime.now(),
      category: json['category'] ?? 'danger',
      customName: json['customName'],
      safeSpotType: json['safeSpotType'],
      source: json['source'],
    );
  }

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      type: data['type'] ?? 'Other',
      severity: (data['severity'] as num).toInt(),
      description: data['description'] ?? '',
      time: (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      category: data['category'] ?? 'danger',
      customName: data['customName'],
      safeSpotType: data['safeSpotType'],
      source: data['source'] ?? 'community',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lat': lat,
      'lng': lng,
      'type': type,
      'severity': severity,
      'description': description,
      'timestamp': Timestamp.fromDate(time),
      'category': category,
      'customName': customName,
      'safeSpotType': safeSpotType,
      'source': source ?? 'community',
    };
  }
}

class IncidentStore extends ChangeNotifier {
  static final IncidentStore _instance = IncidentStore._internal();
  factory IncidentStore() => _instance;
  IncidentStore._internal();

  final List<Incident> _incidents = [];
  bool _loaded = false;
  bool get isLoaded => _loaded;

  final _firestore = FirebaseFirestore.instance;

  List<Incident> get all => List.unmodifiable(_incidents);
  List<Incident> get dangers =>
      _incidents.where((i) => i.category == 'danger').toList();
  List<Incident> get safeSpots =>
      _incidents.where((i) => i.category == 'safe').toList();

  // ── Load from JSON asset (scraped data) ──
  Future<void> loadFromAssets() async {
    if (_loaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/saferoute_data.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _incidents.clear();
      for (final item in jsonList) {
        try {
          _incidents.add(Incident.fromJson(item));
        } catch (e) {
          debugPrint('Error parsing incident: $e');
        }
      }
      debugPrint('✅ Loaded ${_incidents.length} incidents from JSON');
    } catch (e) {
      debugPrint('❌ Error loading JSON: $e');
    }

    // Also load from Firestore
    await _loadFromFirestore();
    _loaded = true;
    notifyListeners();
  }

  // ── Load community reports from Firestore ──
  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final incident = Incident.fromFirestore(doc);
          // Add only if not already in list (avoid duplicates)
          if (!_incidents.any((i) => i.id == incident.id)) {
            _incidents.insert(0, incident);
          }
        } catch (e) {
          debugPrint('Error parsing Firestore doc: $e');
        }
      }
      debugPrint(
          '✅ Loaded ${snapshot.docs.length} reports from Firestore');
    } catch (e) {
      debugPrint('❌ Firestore load error: $e');
    }
  }

  // ── Listen to real-time updates from Firestore ──
  void listenToFirestore() {
    _firestore
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          try {
            final incident = Incident.fromFirestore(change.doc);
            if (!_incidents.any((i) => i.id == incident.id)) {
              _incidents.insert(0, incident);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error processing new doc: $e');
          }
        }
      }
    });
  }

  // ── Add new incident — saves to Firestore ──
  Future<void> addIncident(Incident incident) async {
    // Add to local list immediately
    _incidents.insert(0, incident);
    notifyListeners();

    // Save to Firestore
    try {
      await _firestore
          .collection('incidents')
          .doc(incident.id)
          .set(incident.toFirestore());
      debugPrint('✅ Saved to Firestore: ${incident.id}');
    } catch (e) {
      debugPrint('❌ Firestore save error: $e');
    }
  }
}