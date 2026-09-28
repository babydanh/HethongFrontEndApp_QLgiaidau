import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Reusable tournament image with a SportO brand fallback.
class TournamentAvatar extends StatelessWidget {
  final String? imageUrl;
  final String tournamentName;
  final String? sport;
  final double size;
  final bool fillHeight;
  final double? borderWidth;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  const TournamentAvatar({
    super.key,
    this.imageUrl,
    required this.tournamentName,
    this.sport,
    this.size = 38,
    this.fillHeight = false,
    this.borderWidth,
    this.borderColor,
    this.borderRadius,
  });

  String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    if (url.startsWith('http')) return url;

    String apiBase = 'http://localhost:3000/api/v1';
    try {
      apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      if (!kIsWeb && Platform.isAndroid && apiBase.contains('localhost')) {
        apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
      }
    } catch (_) {}

    final host = apiBase.replaceAll('/api/v1', '');
    return '$host$url';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedUrl = _resolveImageUrl(imageUrl);
    final hasImage = resolvedUrl.isNotEmpty;
    final radius = borderRadius;
    final image = hasImage
        ? Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallback(context),
          )
        : _buildFallback(context);

    return Container(
      width: size,
      height: fillHeight ? null : size,
      constraints: fillHeight ? BoxConstraints(minHeight: size) : null,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? colors.border,
          width: borderWidth ?? 1,
        ),
      ),
      child: radius == null
          ? ClipOval(child: image)
          : ClipRRect(borderRadius: radius, child: image),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: size,
        height: size,
        child: Container(
          color: colors.bgSurface,
          alignment: Alignment.center,
          padding: EdgeInsets.all(size * 0.12),
          child: SvgPicture.asset(
            'assets/images/sporto_v1.svg',
            fit: BoxFit.contain,
            semanticsLabel: 'SportO',
          ),
        ),
      ),
    );
  }
}
