import 'package:app_quanly_giaidau/core/utils/date_parser.dart';

class Penalty {
  final String teamId;
  final String type;
  final String? reason;
  final DateTime timestamp;

  const Penalty({
    required this.teamId,
    required this.type,
    this.reason,
    required this.timestamp,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      teamId: json['teamId'] ?? '',
      type: json['type'] ?? 'warning',
      reason: json['reason'],
      timestamp: DateParser.parseDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'type': type,
      if (reason != null) 'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
