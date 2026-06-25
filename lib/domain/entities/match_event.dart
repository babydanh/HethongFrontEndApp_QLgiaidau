import 'package:app_quanly_giaidau/core/utils/date_parser.dart';

enum MatchEventType {
  score,
  foul,
  yellowCard,
  redCard,
  injury,
  penalty,
  other
}

extension MatchEventTypeExt on MatchEventType {
  String get value {
    switch (this) {
      case MatchEventType.score:
        return 'score';
      case MatchEventType.foul:
        return 'foul';
      case MatchEventType.yellowCard:
        return 'yellow_card';
      case MatchEventType.redCard:
        return 'red_card';
      case MatchEventType.injury:
        return 'injury';
      case MatchEventType.penalty:
        return 'penalty';
      case MatchEventType.other:
        return 'other';
    }
  }

  static MatchEventType fromString(String val) {
    switch (val) {
      case 'score':
        return MatchEventType.score;
      case 'foul':
        return MatchEventType.foul;
      case 'yellow_card':
        return MatchEventType.yellowCard;
      case 'red_card':
        return MatchEventType.redCard;
      case 'injury':
        return MatchEventType.injury;
      case 'penalty':
        return MatchEventType.penalty;
      default:
        return MatchEventType.other;
    }
  }
}

class MatchEvent {
  final String id;
  final DateTime timestamp;
  final String teamId;
  final MatchEventType type;
  final String description;
  final int pointsChange;

  const MatchEvent({
    required this.id,
    required this.timestamp,
    required this.teamId,
    required this.type,
    this.description = '',
    this.pointsChange = 0,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'] as String? ?? '',
      timestamp: DateParser.parseDate(json['timestamp']),
      teamId: json['teamId'] as String? ?? '',
      type: MatchEventTypeExt.fromString(json['type'] as String? ?? 'other'),
      description: json['description'] as String? ?? '',
      pointsChange: json['pointsChange'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'teamId': teamId,
      'type': type.value,
      'description': description,
      'pointsChange': pointsChange,
    };
  }

  MatchEvent copyWith({
    String? id,
    DateTime? timestamp,
    String? teamId,
    MatchEventType? type,
    String? description,
    int? pointsChange,
  }) {
    return MatchEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      teamId: teamId ?? this.teamId,
      type: type ?? this.type,
      description: description ?? this.description,
      pointsChange: pointsChange ?? this.pointsChange,
    );
  }
}
