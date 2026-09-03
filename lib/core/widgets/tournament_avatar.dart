import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Reusable Tournament Avatar widget with graceful sport emoji & initial letter fallback.
/// Conforms to taste-skill design standards (anti-slop, clean visual hierarchy, no squished images).
class TournamentAvatar extends StatelessWidget {
  final String? imageUrl;
  final String tournamentName;
  final String? sport;
  final double size;
  final double? borderWidth;
  final Color? borderColor;

  const TournamentAvatar({
    super.key,
    this.imageUrl,
    required this.tournamentName,
    this.sport,
    this.size = 38,
    this.borderWidth,
    this.borderColor,
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

  String _getInitials(String name) {
    final clean = name.replaceFirst(RegExp(r'^(Giải|GIẢI)\s+', caseSensitive: false), '').trim();
    if (clean.isEmpty) return 'T';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _getSportEmoji(String? sportKey) {
    if (sportKey == null) return '🏆';
    switch (sportKey.toLowerCase()) {
      case 'pickleball':
        return '🏓';
      case 'badminton':
        return '🏸';
      case 'tennis':
        return '🎾';
      case 'table_tennis':
        return '🏓';
      case 'football':
        return '⚽';
      default:
        return '🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(imageUrl);
    final hasImage = resolvedUrl.isNotEmpty;
    final initials = _getInitials(tournamentName);
    final emoji = _getSportEmoji(sport);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
          width: borderWidth ?? 1,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(initials, emoji),
              )
            : _buildFallback(initials, emoji),
      ),
    );
  }

  Widget _buildFallback(String initials, String emoji) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFDBEAFE),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : emoji,
        style: TextStyle(
          color: const Color(0xFF1D4ED8),
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
