import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';

/// Keeps the legacy admin deep link stable while routing to the current
/// management workspace for the tournament's actual product type.
class TournamentManagementDispatcher extends ConsumerWidget {
  const TournamentManagementDispatcher({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));
    final l10n = AppLocalizations.of(context)!;

    return tournamentAsync.when(
      loading: () => _StateScaffold(
        title: l10n.unnamed,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _StateScaffold(
        title: l10n.errorPrefix,
        child: _RetryState(
          message: ErrorParser.parse(error, l10n.errorPrefix, l10n),
          onRetry: () => ref.invalidate(tournamentProvider(tournamentId)),
        ),
      ),
      data: (tournament) {
        if (tournament == null) {
          return _StateScaffold(
            title: l10n.tournamentNotFound,
            child: _RetryState(
              message: l10n.tournamentNotFound,
              onRetry: () => ref.invalidate(tournamentProvider(tournamentId)),
            ),
          );
        }

        if (tournament.isLite) {
          return LiteManagementScreen(tournamentId: tournamentId);
        }

        return OrganizerOpsScreen(tournamentId: tournamentId);
      },
    );
  }
}

class _StateScaffold extends StatelessWidget {
  const _StateScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
      ),
      body: child,
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: context.colors.error,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.dashboard_retry),
            ),
          ],
        ),
      ),
    );
  }
}
