import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityPollWidget extends ConsumerStatefulWidget {
  final String communityId;
  final CommunityPollModel poll;
  final String? tournamentId;
  final String? tournamentInviteCode;

  const CommunityPollWidget({
    super.key,
    required this.communityId,
    required this.poll,
    this.tournamentId,
    this.tournamentInviteCode,
  });

  @override
  ConsumerState<CommunityPollWidget> createState() =>
      _CommunityPollWidgetState();
}

class _CommunityPollWidgetState extends ConsumerState<CommunityPollWidget> {
  late CommunityPollModel _poll;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
  }

  bool _isPositiveRegistrationOption(String text) {
    final value = text.trim().toLowerCase();
    return value.contains('có tham gia') ||
        value.contains('đăng ký') ||
        value.contains('yes') ||
        value.contains('✅');
  }

  bool _isDeclineRegistrationOption(String text) {
    final value = text.trim().toLowerCase();
    return value.contains('không tham gia') ||
        value == 'không' ||
        value.contains('bận') ||
        value.contains('no') ||
        value.contains('❌');
  }

  Future<void> _syncTournamentRegistration({
    required bool wasPositive,
    required bool isPositive,
    required bool isDecline,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final tournamentId = widget.tournamentId;
    final inviteCode = widget.tournamentInviteCode;
    if (tournamentId == null || tournamentId.trim().isEmpty) return;

    final shouldJoin = isPositive && !wasPositive;
    final shouldWithdraw = wasPositive && !isPositive;
    if (!shouldJoin && !shouldWithdraw) return;

    try {
      if (shouldJoin) {
        if (inviteCode == null || inviteCode.trim().isEmpty) {
          throw FormatException(l10n.communityPoll_missingInviteCode);
        }
        await ref.read(tournamentRepositoryProvider).joinLite(inviteCode);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.communityPoll_registrationJoined)),
          );
        }
      } else {
        await ref
            .read(tournamentRepositoryProvider)
            .withdraw(tournamentId: tournamentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.communityPoll_registrationWithdrawn)),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldJoin
                ? l10n.communityPoll_registrationJoinPending
                : l10n.communityPoll_registrationWithdrawPending,
          ),
        ),
      );
    }
  }

  Future<void> _vote(String optionId) async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy || _poll.isClosed) return;
    final previousSelected = _poll.options
        .where((option) => option.isVoted)
        .toList();
    final wasPositive = previousSelected.any(
      (option) => _isPositiveRegistrationOption(option.optionText),
    );
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(communitySocialRepositoryProvider)
          .votePoll(widget.communityId, _poll.id, optionId);
      if (mounted) setState(() => _poll = updated);

      CommunityPollOption? selected;
      for (final option in updated.options) {
        if (option.id == optionId) {
          selected = option;
          break;
        }
      }
      if (selected != null) {
        final isPositive = updated.options.any(
          (option) =>
              option.isVoted &&
              _isPositiveRegistrationOption(option.optionText),
        );
        final isDecline = updated.options.any(
          (option) =>
              option.isVoted && _isDeclineRegistrationOption(option.optionText),
        );
        await _syncTournamentRegistration(
          wasPositive: wasPositive,
          isPositive: isPositive,
          isDecline: isDecline,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityPoll_voteError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addOption() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.communityPoll_addOptionTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(hintText: l10n.communityPoll_optionHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.communityPoll_add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(communitySocialRepositoryProvider)
          .addPollOption(widget.communityId, _poll.id, value);
      if (mounted) setState(() => _poll = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityPoll_addOptionError)),
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
    final total = _poll.options.fold<int>(
      0,
      (sum, option) => sum + option.voteCount,
    );
    final sortedOptions = [..._poll.options]
      ..sort((a, b) {
        int score(String text) {
          if (text.contains('Có tham gia') ||
              text.contains('Đăng ký') ||
              text.contains('✅'))
            return 1;
          if (text.contains('Chưa chắc chắn') ||
              text.contains('suy nghĩ') ||
              text.contains('⏳'))
            return 2;
          if (text.contains('Không') ||
              text.contains('Bận') ||
              text.contains('❌'))
            return 3;
          return 2;
        }

        return score(a.optionText).compareTo(score(b.optionText));
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll_outlined, color: AppTheme.primary),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Text(
                  _poll.question,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (_poll.isClosed)
                Text(
                  l10n.communityPoll_closed,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            _poll.allowMultipleAnswers
                ? l10n.communityPoll_multipleHint
                : l10n.communityPoll_singleHint,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          if (widget.tournamentId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.communityPoll_tournamentHint,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: AppTheme.spacingSM),
          ...sortedOptions.map((option) {
            final ratio = total == 0 ? 0.0 : option.voteCount / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _busy || _poll.isClosed ? null : () => _vote(option.id),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 42,
                        color: AppTheme.primary.withValues(alpha: .18),
                        backgroundColor: colors.bgCard,
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              option.isVoted
                                  ? (_poll.allowMultipleAnswers
                                        ? Icons.check_box
                                        : Icons.radio_button_checked)
                                  : (_poll.allowMultipleAnswers
                                        ? Icons.check_box_outline_blank
                                        : Icons.radio_button_unchecked),
                              size: 18,
                              color: option.isVoted
                                  ? AppTheme.primary
                                  : colors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.optionText,
                                style: TextStyle(
                                  fontWeight: option.isVoted
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            Text(
                              '${option.voteCount}',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_poll.allowAddOptions && !_poll.isClosed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : _addOption,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.communityPoll_addOption),
              ),
            ),
          Text(
            l10n.communityPoll_voteCount(total),
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
