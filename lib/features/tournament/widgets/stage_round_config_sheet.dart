import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/sport_rule_presets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_editor_sheet.dart'
    show
        divisionEditorPresetDescription,
        divisionEditorPresetLabel,
        divisionEditorSetOptionLabel,
        divisionEditorSetUnitLabel;
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Một vòng chọn được trong sheet cấu hình (port `RoundOption` của Web
/// `DivisionRoundRulesSection`): stage thật từ `GET /tournaments/:id/bracket`
/// kèm số vòng — 0 là cấu hình dùng chung của stage, còn lại là từng vòng
/// (vòng bảng kiểu `leg_N`, loại trực tiếp theo số vòng của trận).
class _RoundOption {
  const _RoundOption({
    required this.stage,
    required this.roundNumber,
    required this.name,
    required this.isGroupStage,
    this.override,
  });

  final Map<String, dynamic> stage;
  final int roundNumber;

  /// Tên hiển thị ("Vòng bảng dùng chung", "Lượt 2", "Chung kết", "Vòng 16"…).
  final String name;

  /// Stage vòng bảng (ROUND_ROBIN): vòng 0 là cấu hình chung, lượt là `leg_N`.
  final bool isGroupStage;

  /// Cấu hình riêng đã lưu của vòng: `roundConfig.rounds[key]` (vòng 0 là cả
  /// `roundConfig` của stage — đối chiếu Web `handleOpenRoundModal`).
  final Map<String, dynamic>? override;

  String get stageId => stage['id']?.toString() ?? '';

  String get key => '$stageId#${roundNumber}_$name';
}

/// Sheet cấu hình từng vòng của stage khi hạng mục đã sinh sơ đồ (task 2.2,
/// đối chiếu Web `DivisionRoundRulesSection` + modal `roundModal`):
/// chọn vòng của stage, đặt sân, giờ mặc định, luật riêng của vòng (khi giải
/// không chạy Lite) và ghi chú điều phối; lưu gọi
/// `PATCH /tournaments/stages/:stageId` với `roundConfig` ghép đúng Web
/// `handleSaveStageDetails` (giữ nguyên mọi key khác của stage).
///
/// Stateful và bọc khung [TournamentManageSheet] trong `build` để `busy` đổi
/// được bên trong sheet (helper `show` của khung chốt busy một lần lúc mở).
class StageRoundConfigSheet extends ConsumerStatefulWidget {
  const StageRoundConfigSheet({
    super.key,
    required this.tournament,
    required this.division,
  });

  final Tournament tournament;

  /// Hạng mục từ `GET /tournaments/:id/divisions`: dùng `roundConfig` để suy
  /// luật gốc của hạng mục và đếm số lượt vòng bảng.
  final Map<String, dynamic> division;

  /// Mở sheet cấu hình từng vòng. Trả về `true` khi đã lưu thành công.
  ///
  /// Mở bằng `showModalBottomSheet` trực tiếp (builder trả sheet stateful này
  /// — khung [TournamentManageSheet] nằm trong `build` của state), drag tắt
  /// từ đầu theo pattern các sheet quản lý giải.
  static Future<bool?> show(
    BuildContext context, {
    required Tournament tournament,
    required Map<String, dynamic> division,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) =>
        StageRoundConfigSheet(tournament: tournament, division: division),
  );

  @override
  ConsumerState<StageRoundConfigSheet> createState() =>
      _StageRoundConfigSheetState();
}

class _StageRoundConfigSheetState extends ConsumerState<StageRoundConfigSheet> {
  late final String _divisionId =
      (widget.division['id'] ?? widget.division['divisionId'] ?? '').toString();
  late final Map<String, dynamic>? _divisionRoundConfig = _asMap(
    widget.division['roundConfig'],
  );
  late final bool _isSwiss =
      (widget.division['bracketType'] ?? '').toString().toUpperCase() ==
      'SWISS';

  /// Luật gốc của hạng mục (đối chiếu Web state `sportRuleKind`… của trang
  /// quản lý — resolve từ `roundConfig` hạng mục, fallback theo môn của giải).
  late final SportRuleView _baseView;
  late final SportRulePresetKind _sportKind;

  /// Giải chạy Lite thì modal chỉ còn sân/giờ/ghi chú (đối chiếu Web
  /// `isLiteMode` của trang quản lý).
  late final bool _isLiteMode;

  bool _loading = true;
  String? _loadError;
  List<_RoundOption> _rounds = const [];
  int _selected = 0;

  // Trường của vòng đang chọn (port state `stageVenueId`… của Web).
  late final TextEditingController _venue = TextEditingController();
  late final TextEditingController _note = TextEditingController();
  DateTime? _scheduledAt;
  late int _setsToWin;
  late int _pointsPerSet;
  late bool _winByTwo;
  late int _maxDeucePoints;
  late bool _superTiebreakEnabled;
  late int _superTiebreakPoints;

  late final TextEditingController _pointsController = TextEditingController();
  late final TextEditingController _maxDeuceController =
      TextEditingController();
  late final TextEditingController _tiebreakPointsController =
      TextEditingController();

  bool _busy = false;
  String? _errorText;

  bool get _supportsTiebreak =>
      _sportKind == SportRulePresetKind.tennis ||
      _sportKind == SportRulePresetKind.pickleballSideOut;

  @override
  void initState() {
    super.initState();
    final fallbackKind = inferSportRuleKindFromText(
      widget.tournament.sportRules?['kind'],
      widget.tournament.sport,
    );
    _baseView = resolveSportRuleView(_divisionRoundConfig, fallbackKind);
    _sportKind = _baseView.kind;
    // Legacy roundConfig không ghi mode tường minh: rơi về mode của giải
    // (đối chiếu Web applyDivisionFormValues).
    _isLiteMode =
        (explicitScoringMode(_divisionRoundConfig) ??
            explicitScoringMode(widget.tournament.sportRules) ??
            'LITE') !=
        'STRICT';
    _loadStages();
  }

  @override
  void dispose() {
    _venue.dispose();
    _note.dispose();
    _pointsController.dispose();
    _maxDeuceController.dispose();
    _tiebreakPointsController.dispose();
    super.dispose();
  }

  Future<void> _loadStages() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final stages = await ref
          .read(tournamentRepositoryProvider)
          .getDivisionStages(widget.tournament.id, divisionId: _divisionId);
      if (!mounted) return;
      setState(() {
        _rounds = _buildRounds(stages, AppLocalizations.of(context)!);
        _loading = false;
      });
      if (_rounds.isNotEmpty) _selectRound(_rounds.first);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError =
            tournamentSheetServerMessage(error) ??
            AppLocalizations.of(context)!.tournamentManagementActionError;
      });
    }
  }

  /// Danh sách vòng chọn được (port `rounds` của Web
  /// `DivisionRoundRulesSection`, chỉ stage thật vì sheet chỉ mở khi đã có
  /// sơ đồ; Web còn dựng stage nháp `__draft_gsk_*` lưu xuống division —
  /// ngoài phạm vi task này).
  List<_RoundOption> _buildRounds(
    List<Map<String, dynamic>> stages,
    AppLocalizations l10n,
  ) {
    final rounds = <_RoundOption>[];
    final groupStage = stages
        .where((stage) => _stageType(stage) == 'ROUND_ROBIN')
        .firstOrNull;
    if (groupStage != null) {
      final stageRc = _asMap(groupStage['roundConfig']);
      rounds.add(
        _RoundOption(
          stage: groupStage,
          roundNumber: 0,
          name: l10n.stageRoundSharedGroupStage,
          isGroupStage: true,
          override: stageRc,
        ),
      );
      // Số lượt vòng bảng: cấu hình hạng mục, tối thiểu 1 (đối chiếu Web
      // `configuredGroupRounds`).
      final configuredLegs = _configuredGroupLegs();
      for (var leg = 1; leg <= configuredLegs; leg++) {
        rounds.add(
          _RoundOption(
            stage: groupStage,
            roundNumber: leg,
            name: l10n.stageRoundLeg(leg),
            isGroupStage: true,
            override: _asMap(_asMap(stageRc?['rounds'])?['leg_$leg']),
          ),
        );
      }
    }
    for (final stage in stages) {
      final type = _stageType(stage);
      if (type == 'SINGLE_ELIMINATION' || type == 'DOUBLE_ELIMINATION') {
        rounds.addAll(_knockoutRounds(stage, l10n));
      }
    }
    return rounds;
  }

  /// Số lượt vòng bảng đã cấu hình của hạng mục (đối chiếu Web
  /// `configuredGroupRounds`: `groupsConfig.roundsToPlay` + lượt override
  /// `leg_N` đã lưu trong `roundConfig.rounds` của hạng mục).
  int _configuredGroupLegs() {
    final groupsConfig = _asMap(_divisionRoundConfig?['groupsConfig']);
    final persisted = groupsConfig?['roundsToPlay'];
    var legs = persisted is num && persisted.toInt() >= 1
        ? persisted.toInt()
        : 1;
    final divisionRounds = _asMap(_divisionRoundConfig?['rounds']);
    for (final key in divisionRounds?.keys ?? const Iterable<String>.empty()) {
      final match = RegExp(r'^leg_(\d+)$').firstMatch(key);
      if (match != null) {
        legs = math.max(legs, int.tryParse(match.group(1)!) ?? 1);
      }
    }
    return legs;
  }

  /// Các vòng loại trực tiếp của một stage: đếm theo số vòng của trận trong
  /// từng bảng, nhánh thắng là chuẩn khi trùng số vòng với nhánh thua/chung
  /// kết (port `getStageRounds` của Web `DivisionRoundRulesSection`).
  List<_RoundOption> _knockoutRounds(
    Map<String, dynamic> stage,
    AppLocalizations l10n,
  ) {
    final roundsByNumber = <int, ({int capacity, bool isGrandFinal})>{};
    for (final group in (stage['groups'] as List? ?? const [])) {
      final groupMap = _asMap(group);
      final matches = groupMap?['matches'] as List? ?? const [];
      final groupName = groupMap?['name']?.toString() ?? '';
      final isGrandFinalGroup = RegExp(
        'grand|chung',
        caseSensitive: false,
      ).hasMatch(groupName);
      final roundNumbers = <int>{
        for (final match in matches)
          if (_asMap(match)?['roundNumber'] is num)
            (_asMap(match)!['roundNumber'] as num).toInt(),
      };
      for (final roundNumber in roundNumbers) {
        final matchCount = matches
            .where(
              (match) =>
                  _asMap(match)?['roundNumber'] is num &&
                  (_asMap(match)!['roundNumber'] as num).toInt() == roundNumber,
            )
            .length;
        final isGrandFinal = isGrandFinalGroup;
        final previous = roundsByNumber[roundNumber];
        if (previous == null || (!isGrandFinal && previous.isGrandFinal)) {
          roundsByNumber[roundNumber] = (
            capacity: math.max(2, matchCount * 2),
            isGrandFinal: isGrandFinal,
          );
        }
      }
    }
    final entries = roundsByNumber.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalRounds = math.max(1, entries.length);
    final stageRc = _asMap(stage['roundConfig']);
    return [
      for (final (index, entry) in entries.indexed)
        _RoundOption(
          stage: stage,
          roundNumber: entry.key,
          name: entry.value.isGrandFinal
              ? l10n.matchTableRoundFinal
              : _knockoutRoundLabel(l10n, index, totalRounds),
          isGroupStage: false,
          override: _asMap(_asMap(stageRc?['rounds'])?['${entry.key}']),
        ),
    ];
  }

  /// Nhãn vòng loại trực tiếp theo vị trí (port `getKnockoutRoundLabel` của
  /// Web `BracketTab`): từ cuối lên — chung kết, bán kết, tứ kết, vòng 16…
  String _knockoutRoundLabel(
    AppLocalizations l10n,
    int index,
    int totalRounds,
  ) {
    final fromEnd = totalRounds - 1 - index;
    return switch (fromEnd) {
      0 => l10n.matchTableRoundFinal,
      1 => l10n.matchTableRoundSemifinal,
      2 => l10n.matchTableRoundQuarterfinal,
      3 => l10n.stageRoundKnockoutOf(16),
      4 => l10n.stageRoundKnockoutOf(32),
      5 => l10n.stageRoundKnockoutOf(64),
      _ => l10n.stageRoundKnockoutOf(1 << fromEnd),
    };
  }

  /// Chọn vòng: nạp cấu hình riêng của vòng đó vào các trường (port
  /// `handleOpenRoundModal` của Web — thiếu gì rơi về cấu hình stage, vòng 0
  /// thì để trống, luật rơi về luật gốc hạng mục).
  void _selectRound(_RoundOption round) {
    setState(() {
      _selected = _rounds.indexOf(round);
      final rc = round.override;
      final stage = round.stage;
      final venue =
          rc?['venue_id'] ??
          (round.roundNumber == 0 ? '' : stage['venueId'] ?? '');
      _venue.text = venue?.toString() ?? '';
      final scheduledRaw =
          rc?['scheduled_date'] ??
          (round.roundNumber == 0 ? null : stage['scheduledDate']);
      _scheduledAt = scheduledRaw is String
          ? DateTime.tryParse(scheduledRaw)?.toLocal()
          : null;
      _note.text = rc?['custom_notes']?.toString() ?? '';
      final view = rc != null
          ? resolveSportRuleView(rc, _sportKind)
          : _baseView;
      _setsToWin = view.setsToWin;
      _pointsPerSet = view.pointsPerSet;
      _winByTwo = view.winByTwo;
      _maxDeucePoints = view.maxPoints;
      _superTiebreakEnabled = view.hasCustomTiebreakTarget;
      _superTiebreakPoints = view.tiebreakPoints;
      _pointsController.text = '${view.pointsPerSet}';
      _maxDeuceController.text = '${view.maxPoints}';
      _tiebreakPointsController.text = '${view.tiebreakPoints}';
      _errorText = null;
    });
  }

  /// Chọn giờ mặc định: chọn ngày rồi giờ (tham khảo
  /// `pickTournamentManagementDeadline`, không ràng buộc tương lai vì giờ
  /// mặc định của vòng có thể là thời điểm bất kỳ).
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      // Nhập giờ trực tiếp như ô input của Web, khỏi lật mặt đồng hồ.
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// Lưu cấu hình vòng (port `handleSaveStageDetails` của Web — nhánh stage
  /// thật): `roundConfig` gửi đi = luật gốc hạng mục → giữ nguyên cấu hình
  /// cũ của stage → luật vòng đè lên (vòng 0) hoặc ghi vào `rounds[key]`,
  /// luôn gửi đủ `venue_id`/`scheduled_date`/`custom_notes` (null khi trống).
  Future<void> _save() async {
    if (_busy || _rounds.isEmpty) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final round = _rounds[_selected];
      final stageRc = _asMap(round.stage['roundConfig']);
      final currentRounds = _asMap(stageRc?['rounds']) ?? const {};
      final isStageOverride = round.roundNumber == 0;
      final isGroupStageLeg = round.isGroupStage && !isStageOverride;
      final roundKey = isGroupStageLeg
          ? 'leg_${round.roundNumber}'
          : '${round.roundNumber}';
      final venueId = _venue.text.trim();
      final note = _note.text.trim();
      final nextRoundRule = <String, dynamic>{
        ...buildSportRulesPayload(
          kind: _sportKind,
          setsToWin: _setsToWin,
          pointsPerSet: _pointsPerSet,
          winByTwo: _winByTwo,
          maxPoints: _winByTwo ? _maxDeucePoints : null,
          tiebreakPoints: _superTiebreakEnabled ? _superTiebreakPoints : null,
        ),
        'venue_id': venueId.isEmpty ? null : venueId,
        'scheduled_date': _scheduledAt?.toUtc().toIso8601String(),
        'custom_notes': note.isEmpty ? null : note,
      };
      final roundConfig = <String, dynamic>{
        ...buildSportRulesPayload(
          kind: _sportKind,
          setsToWin: _baseView.setsToWin,
          pointsPerSet: _baseView.pointsPerSet,
          winByTwo: _baseView.winByTwo,
          maxPoints: _baseView.winByTwo ? _baseView.maxPoints : null,
          tiebreakPoints: _baseView.hasCustomTiebreakTarget
              ? _baseView.tiebreakPoints
              : null,
          tiebreakerMode: _baseView.tiebreakerMode,
          roundsToPlay: _baseView.roundsToPlay,
        ),
        // Cấu hình cũ của stage giữ nguyên mọi key (swiss, groupsConfig,
        // mode…) — Backend thay cả object `roundConfig` khi PATCH.
        ...?stageRc,
        if (isStageOverride) ...nextRoundRule,
        'kind': _sportKind.apiValue,
        'rounds': isStageOverride
            ? Map<String, dynamic>.of(currentRounds)
            : {...currentRounds, roundKey: nextRoundRule},
      };
      await ref
          .read(tournamentRepositoryProvider)
          .updateStageRoundConfig(
            widget.tournament.id,
            round.stageId,
            roundConfig,
          );
      if (_isSwiss) {
        ref.invalidate(
          swissStageProvider((
            tournamentId: widget.tournament.id,
            divisionId: _divisionId,
          )),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorText =
              tournamentSheetServerMessage(error) ??
              AppLocalizations.of(context)!.tournamentManagementActionError;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManageSheet(
      title: l10n.stageRoundTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('stage-round-save'),
          onPressed: _busy || _rounds.isEmpty ? null : _save,
          child: Text(l10n.stageRoundSave),
        ),
        TextButton(
          key: const ValueKey('stage-round-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_loadError!, style: TextStyle(color: context.colors.error)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('stage-round-retry'),
            onPressed: _loadStages,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.tournamentManagementRetry),
          ),
        ],
      );
    }
    if (_rounds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.stageRoundEmpty,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLiteMode)
          _StageRoundNotice(
            title: l10n.stageRoundLiteTitle,
            description: l10n.stageRoundLiteDescription,
          ),
        DropdownButtonFormField<String>(
          key: const ValueKey('stage-round-select'),
          initialValue: _rounds[_selected].key,
          decoration: InputDecoration(
            labelText: l10n.stageRoundSelectLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final round in _rounds)
              DropdownMenuItem(value: round.key, child: Text(round.name)),
          ],
          onChanged: _busy
              ? null
              : (value) {
                  final index = _rounds.indexWhere(
                    (round) => round.key == value,
                  );
                  if (index >= 0) _selectRound(_rounds[index]);
                },
        ),
        if (!_isLiteMode) ..._buildRulesSection(l10n),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('stage-round-venue'),
          controller: _venue,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: l10n.stageRoundCourtLabel,
            hintText: l10n.stageRoundCourtPlaceholder,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.stageRoundDefaultTimeLabel,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                _scheduledAt == null
                    ? l10n.stageRoundNoTime
                    : DateFormat('dd/MM/yyyy HH:mm').format(_scheduledAt!),
                style: TextStyle(color: context.colors.textPrimary),
              ),
            ),
            IconButton(
              key: const ValueKey('stage-round-pick-time'),
              tooltip: l10n.stageRoundDefaultTimeLabel,
              onPressed: _busy ? null : _pickDateTime,
              icon: const Icon(Icons.schedule_rounded),
            ),
            if (_scheduledAt != null)
              IconButton(
                key: const ValueKey('stage-round-clear-time'),
                tooltip: l10n.stageRoundClearTime,
                onPressed: _busy
                    ? null
                    : () => setState(() => _scheduledAt = null),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('stage-round-note'),
          controller: _note,
          enabled: !_busy,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.stageRoundNoteLabel,
            hintText: l10n.stageRoundNotePlaceholder,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(_errorText!, style: TextStyle(color: context.colors.error)),
        ],
      ],
    );
  }

  /// Khối luật riêng của vòng (ẩn khi giải chạy Lite — đối chiếu Web
  /// `!s.isLiteMode`): preset nhanh + số set + điểm/set + win-by-2 + trần
  /// deuce + super tiebreak + dòng tổng hợp.
  List<Widget> _buildRulesSection(AppLocalizations l10n) {
    return [
      const SizedBox(height: 16),
      Text(
        l10n.stageRoundQuickPresets,
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final preset in getSportRulePresets(_sportKind))
            Tooltip(
              message: divisionEditorPresetDescription(l10n, preset.id),
              child: ChoiceChip(
                key: ValueKey('stage-round-preset-${preset.id}'),
                label: Text(
                  '${divisionEditorPresetLabel(l10n, preset.id)} · ${preset.setsToWin}×${preset.pointsPerSet}',
                ),
                selected:
                    _setsToWin == preset.setsToWin &&
                    _pointsPerSet == preset.pointsPerSet &&
                    _winByTwo == preset.winByTwo,
                onSelected: _busy ? null : (_) => _applyPreset(preset),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              key: const ValueKey('stage-round-sets-to-win'),
              initialValue: _setsToWin,
              decoration: InputDecoration(
                labelText: l10n.divisionEditorSetsToWin,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in _setsToWinOptions)
                  DropdownMenuItem(
                    value: value,
                    child: Text(
                      divisionEditorSetOptionLabel(l10n, _sportKind, value),
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _setsToWin = value);
                      }
                    },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const ValueKey('stage-round-points-per-set'),
              controller: _pointsController,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: divisionEditorSetUnitLabel(l10n, _sportKind),
                border: const OutlineInputBorder(),
              ),
              onChanged: _clampPoints,
            ),
          ),
        ],
      ),
      CheckboxListTile(
        key: const ValueKey('stage-round-win-by-two'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          l10n.divisionEditorWinByTwo,
          style: TextStyle(color: context.colors.textPrimary),
        ),
        value: _winByTwo,
        onChanged: _busy
            ? null
            : (value) => setState(() => _winByTwo = value == true),
      ),
      if (_winByTwo)
        SizedBox(
          width: 160,
          child: TextField(
            key: const ValueKey('stage-round-max-deuce'),
            controller: _maxDeuceController,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.divisionEditorMaxDeucePoints,
              border: const OutlineInputBorder(),
            ),
            onChanged: _clampMaxDeuce,
          ),
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.divisionEditorNoDeuceLimit,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ),
      if (_supportsTiebreak) ...[
        CheckboxListTile(
          key: const ValueKey('stage-round-super-tiebreak'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            l10n.divisionEditorSuperTiebreak,
            style: TextStyle(color: context.colors.textPrimary),
          ),
          value: _superTiebreakEnabled,
          onChanged: _busy
              ? null
              : (value) =>
                    setState(() => _superTiebreakEnabled = value == true),
        ),
        if (_superTiebreakEnabled)
          SizedBox(
            width: 160,
            child: TextField(
              key: const ValueKey('stage-round-tiebreak-points'),
              controller: _tiebreakPointsController,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.divisionEditorTiebreakPoints,
                border: const OutlineInputBorder(),
              ),
              onChanged: _clampTiebreakPoints,
            ),
          ),
      ],
      const SizedBox(height: 8),
      _StageRoundNotice(
        title: _summary(l10n),
        description: _sportKind == SportRulePresetKind.pickleballSideOut
            ? l10n.stageRoundSideOutSummary
            : null,
      ),
    ];
  }

  String _summary(AppLocalizations l10n) => l10n.stageRoundSummary(
    _setsToWin,
    _sportKind == SportRulePresetKind.pickleballSideOut
        ? l10n.stageRoundUnitGame
        : l10n.stageRoundUnitSet,
    _pointsPerSet,
    _sportKind == SportRulePresetKind.tennis
        ? l10n.stageRoundPointUnitTennis
        : l10n.stageRoundPoints,
    _winByTwo ? l10n.stageRoundMarginWinByTwo : l10n.stageRoundMarginTarget,
    _supportsTiebreak
        ? ' • ${l10n.divisionEditorSuperTiebreak.toLowerCase()}: $_superTiebreakPoints'
        : '',
  );

  /// Giá trị đã lưu nằm ngoài danh sách chuẩn của môn thì thêm vào để
  /// dropdown không vỡ (như division editor).
  List<int> get _setsToWinOptions {
    final options = sportRuleSetOptions(_sportKind);
    if (options.contains(_setsToWin)) return options;
    return [...options, _setsToWin]..sort();
  }

  void _applyPreset(SportRulePreset preset) {
    setState(() {
      _setsToWin = preset.setsToWin;
      _pointsPerSet = preset.pointsPerSet;
      _winByTwo = preset.winByTwo;
      _maxDeucePoints = preset.maxPoints;
      _superTiebreakEnabled = preset.tiebreakPoints != null;
      _superTiebreakPoints = preset.tiebreakPoints ?? preset.pointsPerSet;
      _pointsController.text = '${preset.pointsPerSet}';
      _maxDeuceController.text = '${preset.maxPoints}';
      _tiebreakPointsController.text =
          '${preset.tiebreakPoints ?? preset.pointsPerSet}';
    });
  }

  void _clampPoints(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;
    final clamped = math.max(1, parsed);
    setState(() => _pointsPerSet = clamped);
    if (clamped != parsed) _pointsController.text = '$clamped';
  }

  /// Trần deuce không thấp hơn điểm/set (Web `Math.max(pointsPerSet, …)`).
  void _clampMaxDeuce(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;
    final clamped = math.max(_pointsPerSet, parsed);
    setState(() => _maxDeucePoints = clamped);
    if (clamped != parsed) _maxDeuceController.text = '$clamped';
  }

  void _clampTiebreakPoints(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;
    final clamped = math.max(1, parsed);
    setState(() => _superTiebreakPoints = clamped);
    if (clamped != parsed) _tiebreakPointsController.text = '$clamped';
  }
}

String _stageType(Map<String, dynamic> stage) =>
    (stage['type'] ?? '').toString().toUpperCase();

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// Một khối thông báo nền nhạt (banner Lite, dòng tổng hợp luật).
class _StageRoundNotice extends StatelessWidget {
  const _StageRoundNotice({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (description != null)
            Text(
              description!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}
