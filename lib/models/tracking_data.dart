class TrackingEvent {
  final String time;
  final String location;
  final String status;
  final String description;

  TrackingEvent({
    required this.time,
    required this.location,
    required this.status,
    required this.description,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class TrackingData {
  final String trackingId;
  final String partner;
  final String status;
  final String statusCode;
  final String estimatedDelivery;
  final String lastUpdate;
  final String trackingUrl;
  final List<TrackingEvent> events;

  TrackingData({
    required this.trackingId,
    required this.partner,
    required this.status,
    required this.statusCode,
    required this.estimatedDelivery,
    required this.lastUpdate,
    required this.trackingUrl,
    required this.events,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    var list = json['events'] as List? ?? [];
    List<TrackingEvent> eventsList = list.map((i) => TrackingEvent.fromJson(i)).toList();

    return TrackingData(
      trackingId: json['tracking_id'] ?? '',
      partner: json['partner'] ?? '',
      status: json['status'] ?? 'Unknown',
      statusCode: json['status_code'] ?? 'unknown',
      estimatedDelivery: json['estimated_delivery'] ?? '',
      lastUpdate: json['last_update'] ?? '',
      trackingUrl: json['tracking_url'] ?? '',
      events: eventsList,
    );
  }
}
