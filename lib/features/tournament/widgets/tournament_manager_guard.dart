import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/tournament_manage_access_provider.dart';

/// Shows [child] only to users who may manage the tournament; everyone else
/// gets a "no permission" state and the management screens never mount (so
/// they make no organizer-only API calls).
class TournamentManagerGuard extends ConsumerWidget {
  const TournamentManagerGuard({
    super.key,
    required this.tournamentId,
    required this.child,
  });

  final String tournamentId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(tournamentManageAccessProvider(tournamentId));
    return access.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.opsTitle)),
        body: const BoneDetailLoading(),
      ),
      error: (error, _) => _GuardMessage(
        message: ErrorParser.parse(error, l10n.errorPrefix, l10n),
        onRetry: () =>
            ref.invalidate(tournamentManageAccessProvider(tournamentId)),
      ),
      data: (allowed) =>
          allowed ? child : _GuardMessage(message: l10n.opsNoPermission),
    );
  }
}

class _GuardMessage extends StatelessWidget {
  const _GuardMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.opsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(onPressed: onRetry, child: Text(l10n.opsRetry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
