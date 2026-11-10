import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/social_bracket_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_social_session_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_bracket_rules.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Host-only form: turn the joined players of a club-less session into a Lite bracket.
class SocialBracketForm extends ConsumerStatefulWidget {
  const SocialBracketForm({
    super.key,
    required this.sessionId,
    required this.members,
    required this.matchType,
    required this.onDone,
  });

  final String sessionId;
  final List<CommunityMemberModel> members;

  /// 'SINGLES' or 'DOUBLES' (from the dialog's Đơn/Đôi toggle).
  final String matchType;

  /// Called with the tournament id, for both a new bracket and an existing one (409).
  final void Function(String tournamentId) onDone;

  @override
  ConsumerState<SocialBracketForm> createState() => _SocialBracketFormState();
}

class _SocialBracketFormState extends ConsumerState<SocialBracketForm> {
  String _bracketType = socialBracketTypes.first;
  late final Set<String> _selected = {
    for (final member in widget.members) member.userId,
  };
  bool _busy = false;

  String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
    'SINGLE_ELIMINATION' => l10n.socialBracket_typeSingleElimination,
    'DOUBLE_ELIMINATION' => l10n.socialBracket_typeDoubleElimination,
    'ROUND_ROBIN' => l10n.socialBracket_typeRoundRobin,
    _ => l10n.socialBracket_typeGroupKnockout,
  };

  String _errorMessage(AppLocalizations l10n, Object error) {
    if (error is! SocialApiException) return l10n.socialBracket_error;
    return switch (error.code) {
      'BRACKET_PARTICIPANTS_INVALID' => l10n.socialBracket_errorInvalidPlayers,
      'FORBIDDEN_NOT_HOST' => l10n.socialBracket_errorNotHost,
      'SESSION_CLOSED' => l10n.socialBracket_errorClosed,
      'SOCIAL_SESSION_BELONGS_TO_CLUB' => l10n.socialBracket_errorClub,
      _ => error.message.isNotEmpty ? error.message : l10n.socialBracket_error,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit = canSubmitBracket(
      matchType: widget.matchType,
      selectedCount: _selected.length,
      busy: _busy,
    );
    if (!canSubmit) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(socialSessionRepositoryProvider)
          .createBracket(
            widget.sessionId,
            bracketType: _bracketType,
            matchType: widget.matchType,
            participantUserIds: _selected.toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.socialBracket_created)),
      );
      widget.onDone(result.tournamentId);
    } on SocialBracketExistsException catch (existing) {
      if (!mounted) return;
      widget.onDone(existing.tournamentId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(l10n, error)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _toggle(String userId) => setState(() {
    if (!_selected.remove(userId)) _selected.add(userId);
  });

  void _toggleAll() => setState(() {
    if (_selected.length == widget.members.length) {
      _selected.clear();
    } else {
      _selected.addAll(widget.members.map((member) => member.userId));
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allSelected = _selected.length == widget.members.length;
    final canSubmit = canSubmitBracket(
      matchType: widget.matchType,
      selectedCount: _selected.length,
      busy: _busy,
    );
    final hint = widget.matchType == 'SINGLES'
        ? l10n.socialBracket_hintSingles
        : l10n.socialBracket_hintDoubles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 0,
            children: [
              for (final type in socialBracketTypes)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  showCheckmark: false,
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  label: Text(_typeLabel(l10n, type)),
                  selected: _bracketType == type,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _bracketType = type),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.socialBracket_players} · '
                  '${l10n.socialBracket_selected(_selected.length, widget.members.length)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _busy ? null : _toggleAll,
                child: Text(
                  allSelected
                      ? l10n.socialBracket_clearAll
                      : l10n.socialBracket_selectAll,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final member in widget.members)
                CheckboxListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  value: _selected.contains(member.userId),
                  activeColor: AppTheme.primary,
                  onChanged: _busy ? null : (_) => _toggle(member.userId),
                  title: Text(
                    member.userFullName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withValues(
                    alpha: 0.25,
                  ),
                ),
                onPressed: canSubmit ? _submit : null,
                child: Text(
                  _busy
                      ? l10n.socialBracket_submitting
                      : l10n.socialBracket_submit,
                ),
              ),
              if (!canSubmit && !_busy)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
