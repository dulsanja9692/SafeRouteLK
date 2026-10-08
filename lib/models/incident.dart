class Incident {
  final String id;
  final double lat;
  final double lng;
  final String type;
  final int severity;
  final String description;
  final DateTime time;

  Incident({
    required this.id,
    required this.lat,
    required this.lng,
    required this.type,
    required this.severity,
    required this.description,
    required this.time,
  });
}