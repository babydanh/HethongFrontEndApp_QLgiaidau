import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

enum ClubStandaloneMatchAction { saved, openScoreboard }

/// Compact manual result entry for standalone club matches.
///
/// A standalone match can be finalized with a small set-by-set form. The
/// existing official score page remains available for live point-by-point
/// scoring when the user chooses it explicitly.
class ClubStandaloneMatchResultDialog extends ConsumerStatefulWidget {
  final MatchModel match;

  const ClubStandaloneMatchResultDialog({super.key, required this.match});

  static Future<ClubStandaloneMatchAction?> show(
    BuildContext context, {
    required MatchModel match,
  }) {
    return showDialog<ClubStandaloneMatchAction>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ClubStandaloneMatchResultDialog(match: match),
    );
  }

  @override
  ConsumerState<ClubStandaloneMatchResultDialog> createState() =>
      _ClubStandaloneMatchResultDialogState();
}

class _ClubStandaloneMatchResultDialogState
    extends ConsumerState<ClubStandaloneMatchResultDialog> {
  static const _maxSets = 10;

  late final List<TextEditingController> _sideAControllers;
  late final List<TextEditingController> _sideBControllers;
  late int _setCount;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isReadOnly => widget.match.isCompleted;

  @override
  void initState() {
    super.initState();
    _sideAControllers = List.generate(_maxSets, (_) => TextEditingController());
    _sideBControllers = List.generate(_maxSets, (_) => TextEditingController());

    final history = widget.match.scoreHistory;
    _setCount = history.isEmpty ? 1 : history.length.clamp(1, _maxSets);
    for (var index = 0; index < history.length && index < _maxSets; index++) {
      final set = history[index];
      final hasScore = set.score1 != 0 || set.score2 != 0 || _isReadOnly;
      if (!hasScore) continue;
      _sideAControllers[index].text = '${set.score1}';
      _sideBControllers[index].text = '${set.score2}';
    }
  }

  @override
  void dispose() {
    for (final controller in _sideAControllers) {
      controller.dispose();
    }
    for (final controller in _sideBControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<SetScoreData>? _readSets() {
    String? validation;
    final sets = <SetScoreData>[];
    var foundEmptyRow = false;

    for (var index = 0; index < _setCount; index++) {
      final rawA = _sideAControllers[index].text.trim();
      final rawB = _sideBControllers[index].text.trim();
      final isEmpty = rawA.isEmpty && rawB.isEmpty;
      if (isEmpty) {
        foundEmptyRow = true;
        continue;
      }
      if (foundEmptyRow) {
        validation = AppLocalizations.of(context)!.club_matchScoreIncomplete;
        break;
      }
      // A missing side in an otherwise entered set is an intentional zero.
      // Keep a completely blank row unused so adding extra set rows does not
      // submit unplayed 0-0 sets.
      final scoreA = rawA.isEmpty ? 0 : int.tryParse(rawA);
      final scoreB = rawB.isEmpty ? 0 : int.tryParse(rawB);
      if (scoreA == null || scoreB == null) {
        validation = AppLocalizations.of(context)!.club_matchScoreRequired;
        break;
      }
      sets.add(SetScoreData(score1: scoreA, score2: scoreB, isFinished: true));
    }

    if (validation != null) {
      setState(() => _errorMessage = validation);
      return null;
    }
    if (sets.isEmpty) {
      setState(
        () => _errorMessage = AppLocalizations.of(
          context,
        )!.club_matchScoreRequired,
      );
      return null;
    }
    return sets;
  }

  Future<void> _saveResult() async {
    if (_isReadOnly || _isSaving) return;
    final sets = _readSets();
    if (sets == null) return;

    final (sideAWins, sideBWins) = computeMatchSetsWon(sets);
    if (sideAWins == sideBWins) {
      setState(
        () => _errorMessage = AppLocalizations.of(
          context,
        )!.club_matchScoreWinnerRequired,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(matchRepositoryProvider)
          .updateScoreDetails(
            '',
            widget.match.id,
            p1SetsWon: sideAWins,
            p2SetsWon: sideBWins,
            scoreDetails: sets,
            winnerId: sideAWins > sideBWins
                ? widget.match.team1Id
                : widget.match.team2Id,
            overrideReason: 'Nhập kết quả trận riêng',
            expectedRevision: widget.match.revision,
          );
      if (!mounted) return;
      Navigator.of(context).pop(ClubStandaloneMatchAction.saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _errorText(error);
      });
    }
  }

  String _errorText(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['message'] != null) {
        final message = body['message'];
        if (message is List) return message.join('\n');
        return message.toString();
      }
      return error.message ?? AppLocalizations.of(context)!.club_actionError;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.sizeOf(context).height * 0.9;

    return Dialog(
      backgroundColor: colors.bgCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors, l10n),
            Divider(height: 1, color: colors.borderLight),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTeams(colors),
                    const SizedBox(height: 12),
                    _buildSetCount(colors, l10n),
                    const SizedBox(height: 8),
                    for (var index = 0; index < _setCount; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _buildSetRow(index, colors, l10n),
                      ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_isReadOnly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.club_matchScoreReadOnly,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.borderLight),
            _buildActions(colors, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension colors, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppTheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.club_enterStandaloneScore,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 21),
          ),
        ],
      ),
    );
  }

  Widget _buildTeams(AppColorsExtension colors) {
    return Row(
      children: [
        Expanded(
          child: _buildTeamCard(
            widget.match.team1Name,
            widget.match.team1MemberInfos,
            const Color(0xFF2563EB),
            colors,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            'VS',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: _buildTeamCard(
            widget.match.team2Name,
            widget.match.team2MemberInfos,
            const Color(0xFFEA580C),
            colors,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(
    String teamName,
    List<MatchMemberInfo> members,
    Color accent,
    AppColorsExtension colors,
  ) {
    final visibleMembers = members.take(2).toList(growable: false);
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          _buildAvatarStack(visibleMembers, teamName, accent, colors),
          const SizedBox(width: 7),
          Expanded(
            child: visibleMembers.isEmpty
                ? Text(
                    teamName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final member in visibleMembers)
                        Text(
                          member.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(
    List<MatchMemberInfo> members,
    String fallbackName,
    Color accent,
    AppColorsExtension colors,
  ) {
    if (members.length < 2) {
      return _buildAvatar(
        members.isEmpty ? null : members.first,
        fallbackName,
        accent,
        colors,
      );
    }
    return SizedBox(
      width: 39,
      height: 36,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 3,
            child: _buildAvatar(members[0], fallbackName, accent, colors),
          ),
          Positioned(
            left: 14,
            top: 3,
            child: _buildAvatar(members[1], fallbackName, accent, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    MatchMemberInfo? member,
    String fallbackName,
    Color accent,
    AppColorsExtension colors,
  ) {
    final url = member?.avatarUrl?.trim();
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.bgCard, width: 2),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) =>
                    _avatarFallback(member?.fullName ?? fallbackName, accent),
              )
            : _avatarFallback(member?.fullName ?? fallbackName, accent),
      ),
    );
  }

  Widget _avatarFallback(String name, Color accent) {
    return Center(
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: TextStyle(
          color: accent,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildSetCount(AppColorsExtension colors, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '${l10n.club_setCount}: $_setCount/$_maxSets',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          height: 34,
          child: IconButton(
            tooltip: 'Thêm set',
            onPressed: _isSaving || _isReadOnly || _setCount >= _maxSets
                ? null
                : () {
                    setState(() {
                      _setCount += 1;
                      _errorMessage = null;
                    });
                  },
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.primary,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              disabledForegroundColor: colors.textMuted,
              disabledBackgroundColor: colors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.borderLight),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSetRow(
    int index,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final sideAColor = const Color(0xFF2563EB);
    final sideBColor = const Color(0xFFEA580C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              l10n.club_setNumber(index + 1),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: _buildScoreField(
              _sideAControllers[index],
              'A',
              sideAColor,
              colors,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '–',
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: _buildScoreField(
              _sideBControllers[index],
              'B',
              sideBColor,
              colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreField(
    TextEditingController controller,
    String label,
    Color accent,
    AppColorsExtension colors,
  ) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        enabled: !_isReadOnly && !_isSaving,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: '0',
          hintStyle: TextStyle(
            color: colors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          labelStyle: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          filled: true,
          fillColor: colors.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: accent, width: 1.3),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(AppColorsExtension colors, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(
                    context,
                  ).pop(ClubStandaloneMatchAction.openScoreboard),
            icon: const Icon(Icons.scoreboard_rounded, size: 16),
            label: Text(l10n.club_openScoreboard),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _isReadOnly || _isSaving ? null : _saveResult,
            icon: _isSaving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 17),
            label: Text(l10n.club_saveMatchResult),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
