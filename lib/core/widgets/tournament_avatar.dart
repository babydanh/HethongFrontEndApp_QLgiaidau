import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/club_brand_avatar.dart';

/// Tournament identity avatar backed by the shared entity image widget.
class TournamentAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? bannerUrl;
  final String tournamentName;
  final String? sport;
  final double size;
  final double? borderWidth;
  final Color? borderColor;

  const TournamentAvatar({
    super.key,
    this.imageUrl,
    this.bannerUrl,
    required this.tournamentName,
    this.sport,
    this.size = 38,
    this.borderWidth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClubBrandAvatar(
      logoUrl: imageUrl,
      bannerUrl: bannerUrl,
      size: size,
      bannerFit: BoxFit.contain,
      backgroundColor: colors.bgSurface,
      borderColor: borderColor ?? colors.border,
      borderWidth: borderWidth ?? 1,
    );
  }
}
