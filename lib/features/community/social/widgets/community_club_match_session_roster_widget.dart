import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_sessions_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityClubMatchSessionRosterWidget extends ConsumerStatefulWidget {
  final String sessionId;
  final String communityId;

  const CommunityClubMatchSessionRosterWidget({
    super.key,
    required this.sessionId,
    required this.communityId,
  });

  @override
  ConsumerState<CommunityClubMatchSessionRosterWidget> createState() =>
      _CommunityClubMatchSessionRosterWidgetState();
}

class _CommunityClubMatchSessionRosterWidgetState
    extends ConsumerState<CommunityClubMatchSessionRosterWidget> {
  ClubMatchSessionModel? _session;
  List<ClubMatchParticipantModel> _participants = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(clubMatchSessionRepositoryProvider);
      final values = await Future.wait([
        repo.get(widget.sessionId),
        repo.participants(widget.sessionId),
      ]);
      if (mounted) {
        setState(() {
          _session = values[0] as ClubMatchSessionModel;
          _participants = values[1] as List<ClubMatchParticipantModel>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinOrWithdraw() async {
    final session = _session;
    if (session == null || _busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final repo = ref.read(clubMatchSessionRepositoryProvider);
      if (session.canWithdraw) {
        await repo.withdraw(session.id);
      } else {
        await repo.selfJoin(session.id);
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorParser.parse(error, '', l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createMock() async {
    final session = _session;
    if (session == null || _busy) return;
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clubMatchSessionCreateMock),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 255,
          decoration: InputDecoration(
            hintText: l10n.clubMatchSessionMockNameHint,
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.clubMatchSessionCreateMock),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(clubMatchSessionRepositoryProvider)
          .createMockParticipant(session.id, name);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorParser.parse(error, '', l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final session = _session;
    if (session == null) return const SizedBox.shrink();
    final active = _participants
        .where((item) => item.status == 'ACTIVE')
        .toList();
    final totalSlots = session.maxParticipants < active.length
        ? active.length
        : session.maxParticipants;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.clubMatchSessionParticipants} · ${active.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${active.length}/$totalSlots',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (session.canJoin || session.canWithdraw)
                  FilledButton.tonal(
                    onPressed: _busy || session.status != 'OPEN'
                        ? null
                        : _joinOrWithdraw,
                    child: Text(
                      session.canWithdraw
                          ? l10n.clubMatchSessionWithdraw
                          : l10n.clubMatchSessionJoin,
                    ),
                  ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ClubMatchSessionDetailPage(session: session),
                    ),
                  ),
                  child: Text(l10n.clubMatchSessionTitle),
                ),
                if (session.canManage && session.status == 'OPEN')
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _createMock,
                    icon: const Icon(Icons.person_add_alt_rounded, size: 16),
                    label: Text(l10n.clubMatchSessionCreateMock),
                  ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: .72,
            ),
            itemCount: totalSlots,
            itemBuilder: (context, index) {
              final item = index < active.length ? active[index] : null;
              final name = item?.displayName.trim().isNotEmpty == true
                  ? item!.displayName
                  : '${l10n.clubMatchSessionMockPlayer} ${index + 1}';
              final canTapEmptySlot =
                  item == null &&
                  (session.canJoin || session.canWithdraw) &&
                  session.status == 'OPEN';
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: canTapEmptySlot ? _joinOrWithdraw : null,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: item == null
                            ? colors.bgSurface
                            : item.isMock
                            ? colors.warning.withValues(alpha: .18)
                            : colors.info.withValues(alpha: .16),
                        child: item == null
                            ? Icon(Icons.add_rounded, color: colors.textMuted)
                            : Text(
                                name
                                    .substring(
                                      0,
                                      name.length > 2 ? 2 : name.length,
                                    )
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: item.isMock
                                      ? colors.warning
                                      : colors.info,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item == null ? 'Slot #${index + 1}' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: item == null
                              ? colors.textMuted
                              : colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item?.isMock == true)
                        Text(
                          l10n.clubMatchSessionMockPlayer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.warning, fontSize: 9),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
