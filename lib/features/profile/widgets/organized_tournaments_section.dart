import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/organized_tournaments_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Giải tôi tổ chức": 4 rows, then a "Xem thêm" button that pages by cursor.
/// Renders nothing when the user organizes no tournament.
class OrganizedTournamentsSection extends ConsumerWidget {
  const OrganizedTournamentsSection({super.key, required this.rowBuilder});

  final Widget Function(Tournament tournament) rowBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(organizedTournamentsProvider);
    return async.when(
      loading: () => const LavishRowSkeleton(count: 2),
      error: (e, s) => LavishErrorState(
        onRetry: () => ref.invalidate(organizedTournamentsProvider),
      ),
      data: (data) {
        if (data.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LavishGroupHeader(l10n.profOrgTitle),
            for (final t in data.items) rowBuilder(t),
            if (data.hasMore)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: LavishButton(
                  buttonKey: const ValueKey('profile-org-load-more'),
                  label: data.loadMoreFailed
                      ? l10n.profOrgRetry
                      : l10n.profOrgLoadMore,
                  kind: LavishButtonKind.outline,
                  dense: true,
                  busy: data.isLoadingMore,
                  onPressed: () => ref
                      .read(organizedTournamentsProvider.notifier)
                      .loadMore(),
                ),
              ),
          ],
        );
      },
    );
  }
}
