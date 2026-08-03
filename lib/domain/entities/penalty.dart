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
      // The API stores live penalties as team/kind/note/createdAt inside
      // scoreDetails, while older app payloads use teamId/type/reason.
      teamId: json['teamId']?.toString() ?? json['team']?.toString() ?? '',
      type: json['type']?.toString() ?? json['kind']?.toString() ?? 'warning',
      reason: (json['reason'] ?? json['note'])?.toString(),
      timestamp: DateParser.parseDate(json['timestamp'] ?? json['createdAt']),
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
