import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

abstract class IMatchEventRenderer {
  IconData getIcon(MatchEvent event);
  Color getColor(BuildContext context, MatchEvent event);
  String getActionText(MatchEvent event);
}

class ScoreEventRenderer implements IMatchEventRenderer {
  @override
  IconData getIcon(MatchEvent event) =>
      event.pointsChange > 0 ? Icons.add_circle : Icons.remove_circle;

  @override
  Color getColor(BuildContext context, MatchEvent event) =>
      event.pointsChange > 0 ? context.colors.success : context.colors.error;

  @override
  String getActionText(MatchEvent event) =>
      '${event.pointsChange > 0 ? '+' : ''}${event.pointsChange} điểm';
}

class YellowCardEventRenderer implements IMatchEventRenderer {
  @override
  IconData getIcon(MatchEvent event) => Icons.rectangle;

  @override
  Color getColor(BuildContext context, MatchEvent event) => Colors.yellow.shade700;

  @override
  String getActionText(MatchEvent event) => 'Thẻ Vàng';
}

class RedCardEventRenderer implements IMatchEventRenderer {
  @override
  IconData getIcon(MatchEvent event) => Icons.rectangle;

  @override
  Color getColor(BuildContext context, MatchEvent event) => Colors.red.shade700;

  @override
  String getActionText(MatchEvent event) => 'Thẻ Đỏ';
}

class FoulEventRenderer implements IMatchEventRenderer {
  @override
  IconData getIcon(MatchEvent event) => Icons.warning_rounded;

  @override
  Color getColor(BuildContext context, MatchEvent event) => Colors.orange.shade700;

  @override
  String getActionText(MatchEvent event) => 'Phạm lỗi: ${event.description}';
}

class DefaultEventRenderer implements IMatchEventRenderer {
  @override
  IconData getIcon(MatchEvent event) => Icons.info;

  @override
  Color getColor(BuildContext context, MatchEvent event) => context.colors.info;

  @override
  String getActionText(MatchEvent event) => event.description;
}

class MatchEventRendererFactory {
  static final Map<MatchEventType, IMatchEventRenderer> _renderers = {
    MatchEventType.score: ScoreEventRenderer(),
    MatchEventType.yellowCard: YellowCardEventRenderer(),
    MatchEventType.redCard: RedCardEventRenderer(),
    MatchEventType.foul: FoulEventRenderer(),
  };

  static IMatchEventRenderer getRenderer(MatchEventType type) {
    return _renderers[type] ?? DefaultEventRenderer();
  }
}
