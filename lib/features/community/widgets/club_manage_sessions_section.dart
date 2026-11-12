import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_session_create_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_sessions_screen.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_manage_session_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Max sessions shown inline; the rest sit behind "All".
const _inlineSessionLimit = 3;

/// Sessions block of the club manage screen: the single "create session"
/// button plus the latest sessions as Social cards.
class ClubManageSessionsSection extends ConsumerWidget {
  final String clubId;
  const ClubManageSessionsSection({super.key, required this.clubId});

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClubMatchSessionCreateScreen(communityId: clubId),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.clubMatchSessionCreated)));
    }
  }

  void _openAll(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ClubMatchSessionsScreen(communityId: clubId),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final sessions = ref.watch(clubMatchSessionsProvider(clubId));
    final items = sessions.asData?.value ?? const [];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.clubManageSessionsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (items.length > _inlineSessionLimit)
                TextButton(
                  onPressed: () => _openAll(context),
                  child: Text(l10n.infoAll),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _create(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                l10n.clubMatchSessionCreate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (sessions.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    l10n.clubMatchSessionListLoadFailed,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(clubMatchSessionsProvider(clubId)),
                    child: Text(l10n.infoRetry),
                  ),
                ],
              ),
            )
          else if (items.isEmpty && !sessions.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  l10n.clubMatchSessionEmpty,
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
            ),
          for (final session in items.take(_inlineSessionLimit))
            ClubManageSessionCard(
              session: session,
              onTap: () => _openAll(context),
            ),
        ],
      ),
    );
  }
}
