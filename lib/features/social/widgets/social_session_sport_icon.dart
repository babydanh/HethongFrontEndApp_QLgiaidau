import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:flutter/material.dart';

/// Icon SVG của môn trên thẻ buổi giao lưu (thay cho chip chữ). Tên môn là
/// nhãn trợ năng và tooltip.
class SocialSessionSportIcon extends StatelessWidget {
  final String sport;
  final String sportName;
  final double size;

  const SocialSessionSportIcon({
    super.key,
    required this.sport,
    this.sportName = '',
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localized = l10n.sportDisplayName(sport);
    final label = sportName.trim().isNotEmpty ? sportName.trim() : localized;
    return Semantics(
      label: label,
      image: true,
      child: Tooltip(
        message: label,
        child: ExcludeSemantics(
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: SportChoiceTile.buildSportIcon(sport, size)),
          ),
        ),
      ),
    );
  }
}
