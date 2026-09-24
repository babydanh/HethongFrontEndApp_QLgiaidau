import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class TournamentManagementSectionCard extends StatelessWidget {
  const TournamentManagementSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class TournamentManagementError extends StatelessWidget {
  const TournamentManagementError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.tournamentManagementLoadError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tournamentManagementRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class TournamentManagementEmpty extends StatelessWidget {
  const TournamentManagementEmpty({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

Future<bool> confirmTournamentManagementAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final colors = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            AppLocalizations.of(dialogContext)!.tournamentManagementCancel,
          ),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: colors.error)
              : null,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

String tournamentManagementRecordName(Map<String, dynamic> record) =>
    (record['name'] ?? record['displayName'] ?? record['venueName'] ?? '')
        .toString();

String tournamentManagementRecordId(Map<String, dynamic> record) =>
    (record['id'] ?? record['venueId'] ?? record['userId'] ?? '').toString();
String resolveTournamentManagementImageUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    if (isAndroid && trimmed.contains('localhost')) {
      return trimmed.replaceFirst('localhost', '10.0.2.2');
    }
    if (isAndroid && trimmed.contains('127.0.0.1')) {
      return trimmed.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return trimmed;
  }
  var apiBase = 'http://localhost:3000/api/v1';
  try {
    apiBase = dotenv.env['API_BASE_URL'] ?? apiBase;
  } catch (_) {
    // The app can render offline previews before dotenv is initialized.
  }
  if (isAndroid && apiBase.contains('localhost')) {
    apiBase = apiBase.replaceFirst('localhost', '10.0.2.2');
  }
  final host = apiBase.replaceFirst(RegExp(r'/api/v1/?$'), '');
  return '${host.replaceFirst(RegExp(r'/$'), '')}/${trimmed.replaceFirst(RegExp(r'^/'), '')}';
}
