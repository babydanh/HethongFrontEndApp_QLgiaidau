import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/club_network_image.dart';

/// Shared visual identity for clubs and tournaments across app surfaces.
///
/// The source order is always logo -> banner -> SportO. Callers can hide the
/// whole slot when a real logo is required (for example, club detail header).
class ClubBrandAvatar extends StatelessWidget {
  final String? logoUrl;
  final String? bannerUrl;
  final double size;

  /// Enlarges only the logo pixels inside the clipped avatar. The default
  /// keeps existing surfaces unchanged.
  final double logoScale;
  final bool showWhenNoLogo;
  final BoxFit bannerFit;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const ClubBrandAvatar({
    super.key,
    this.logoUrl,
    this.bannerUrl,
    this.size = 56,
    this.logoScale = 1,
    this.showWhenNoLogo = true,
    this.bannerFit = BoxFit.cover,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
  });

  String _resolveUrl(String? value) {
    final normalized = value?.split(',').first.trim() ?? '';
    final lower = normalized.toLowerCase();
    if (normalized.isEmpty ||
        lower.startsWith('data:') ||
        lower.contains('sporto_v1') ||
        lower.contains('defaultfallback') ||
        lower.contains('default_fallback')) {
      return '';
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      if (!kIsWeb && Platform.isAndroid && normalized.contains('localhost')) {
        return normalized.replaceFirst('localhost', '10.0.2.2');
      }
      if (!kIsWeb && Platform.isAndroid && normalized.contains('127.0.0.1')) {
        return normalized.replaceFirst('127.0.0.1', '10.0.2.2');
      }
      return normalized;
    }

    var apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (!kIsWeb && Platform.isAndroid && apiBase.contains('localhost')) {
      apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
    }
    final host = apiBase.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return '${host.replaceFirst(RegExp(r'/$'), '')}/${normalized.replaceFirst(RegExp(r'^/'), '')}';
  }

  Widget _fallback() {
    // Use the tight SVG mark instead of the launcher PNG, whose transparent
    // canvas would make the shared avatar look undersized.
    return SvgPicture.asset(AppConstants.logoIconSvg, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final logo = _resolveUrl(logoUrl);
    final banner = _resolveUrl(bannerUrl);
    // A logo-only surface must stay empty even when a banner exists; banners
    // are a fallback for required identity slots, not a substitute for this
    // optional floating avatar.
    if (logo.isEmpty && !showWhenNoLogo) {
      return const SizedBox.shrink();
    }

    final primary = logo.isNotEmpty ? logo : banner;
    final primaryFit = logo.isNotEmpty ? BoxFit.cover : bannerFit;

    Widget renderBanner() {
      if (banner.isEmpty) return _fallback();
      return ClubNetworkImage(
        banner,
        fit: bannerFit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    Widget renderPrimary() {
      if (primary.isEmpty) return _fallback();
      final image = ClubNetworkImage(
        primary,
        fit: primaryFit,
        errorBuilder: (_, _, _) =>
            logo.isNotEmpty && banner.isNotEmpty ? renderBanner() : _fallback(),
      );
      return logo.isNotEmpty && logoScale > 1
          ? Transform.scale(scale: logoScale, child: image)
          : image;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.white,
          border: borderWidth > 0
              ? Border.all(
                  color: borderColor ?? Colors.black12,
                  width: borderWidth,
                )
              : null,
          boxShadow: boxShadow,
        ),
        child: renderPrimary(),
      ),
    );
  }
}
