part of '../screens/club_detail_screen.dart';

extension _ClubDetailSettingsDelete on _ClubDetailScreenState {
  Future<void> _showDeleteClubDialog(
    Community club,
    AppColorsExtension colors,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.club_deleteConfirmTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.club_deleteWarning(club.name),
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.clubDetailDeleteNameHint,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.clubDetailCurrentClubName,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.matchesCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              nameController.text.trim() == club.name.trim(),
            ),
            child: Text(
              l10n.delete,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (confirm == true) {
      try {
        await ref
            .read(communityRepositoryProvider)
            .deleteCommunity(widget.clubId);
        invalidateCommunityCollections(ref);
        ref.invalidate(communityDetailProvider(widget.clubId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.club_deleted),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Deep-link thẳng vào CLB không có stack để pop — về /home an toàn.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clubDetailMemberActionError),
              backgroundColor: colors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
