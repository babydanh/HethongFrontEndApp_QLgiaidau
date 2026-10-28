import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_round_state.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_editor_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_opening_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/registration_divisions_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stage_round_config_sheet.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TournamentManagementDivisionsSection extends ConsumerStatefulWidget {
  const TournamentManagementDivisionsSection({
    super.key,
    required this.tournament,
  });
  final Tournament tournament;

  @override
  ConsumerState<TournamentManagementDivisionsSection> createState() =>
      _TournamentManagementDivisionsSectionState();
}

class _TournamentManagementDivisionsSectionState
    extends ConsumerState<TournamentManagementDivisionsSection> {
  late Future<List<Map<String, dynamic>>> _divisionsFuture;
  bool _isBusy = false;
  bool _configuring = false;
  String? _mutationError;

  /// Hạng mục đủ chỗ đã đề nghị đóng trong phiên màn này (không persist,
  /// rời màn là hỏi lại — tương đương sessionStorage của Web).
  final _askedFullDivisionIds = <String>{};
  bool _fullPromptActive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _divisionsFuture = ref
      .read(tournamentManagementRepositoryProvider)
      .getManageDivisions(widget.tournament.id);
  void _reload() => setState(() {
    _mutationError = null;
    _load();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _divisionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return TournamentManagementError(
            error: snapshot.error,
            onRetry: _reload,
          );
        final divisions = snapshot.data ?? const <Map<String, dynamic>>[];
        // Hạng mục vừa đủ chỗ còn mở: đề nghị đóng sau khi khung hiển thị xong
        // (đối chiếu Web prompt close-full-divisions).
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybePromptFullDivisions(divisions),
        );
        // Hạt giống chỉ áp dụng cho nội dung vòng bảng + loại trực tiếp.
        final seedDivisions = divisions
            .where(
              (division) => AppConstants.supportsSeeding(
                division['bracketType']?.toString(),
              ),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TournamentManagementSectionCard(
              title: l10n.tournamentManagementDivisions,
              subtitle: l10n.tournamentManagementDivisionsDescription,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('division-bulk-open'),
                        onPressed: _isBusy || divisions.isEmpty
                            ? null
                            : _openBulkRegistrationSheet(divisions),
                        icon: const Icon(Icons.event_available_rounded),
                        label: Text(l10n.divisionBulkOpenButton),
                      ),
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _addDivision,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.tournamentManagementAddDivision),
                      ),
                    ],
                  ),
                  if (_mutationError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n.tournamentManagementActionError,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                  if (divisions.isEmpty)
                    TournamentManagementEmpty(
                      title: l10n.tournamentManagementDivisionsEmpty,
                      subtitle:
                          l10n.tournamentManagementDivisionsEmptyDescription,
                      icon: Icons.category_outlined,
                    )
                  else ...[
                    const SizedBox(height: 12),
                    for (final division in divisions) ...[
                      _DivisionCard(
                        division: division,
                        isBusy: _isBusy,
                        // Khoá/mở đăng ký chỉ chặn VĐV tự đăng ký, không đụng sơ đồ:
                        // làm được mọi lúc trước khi giải kết thúc hoặc bị huỷ.
                        canToggleRegistration: !const {
                          'COMPLETED',
                          'CANCELLED',
                        }.contains(widget.tournament.status.toUpperCase()),
                        onEdit: () => _editDivision(division),
                        // Watch (không read) để menu hiện đúng ngay khi trận
                        // của giải mới về; read lúc build luôn thấy rỗng.
                        onConfigureRounds:
                            (ref
                                        .watch(
                                          matchesProvider(widget.tournament.id),
                                        )
                                        .asData
                                        ?.value
                                        .any(
                                          (match) =>
                                              match.divisionId ==
                                              _divisionId(division),
                                        ) ??
                                    false) &&
                                !_isSwiss(division['bracketType'])
                            ? () => _configureRounds(division)
                            : null,
                        onToggleRegistration: () =>
                            _toggleRegistration(division),
                        onReopenWithDeadline: () =>
                            _reopenWithDeadline(division),
                        onDelete: () => _deleteDivision(division),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
            if (seedDivisions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _TournamentSeedsSection(
                tournamentId: widget.tournament.id,
                divisions: seedDivisions,
              ),
            ],
          ],
        );
      },
    );
  }

  void _maybePromptFullDivisions(List<Map<String, dynamic>> divisions) {
    if (!mounted || _fullPromptActive) return;
    final pending = divisions
        .where((division) {
          final id = _divisionId(division);
          if (id.isEmpty || _askedFullDivisionIds.contains(id)) {
            return false;
          }
          return divisionIsFull(division) &&
              divisionRegistrationOpen(
                division,
                widget.tournament.status.toUpperCase(),
              );
        })
        .toList(growable: false);
    if (pending.isEmpty) return;
    _fullPromptActive = true;
    // Huỷ prompt coi như đã hỏi các hạng mục đangshown (không lặp lại vòng
    // lặp hỏi ngay sau khi đóng); quyết định từng hàng vẫn ghi riêng.
    for (final division in pending) {
      _askedFullDivisionIds.add(_divisionId(division));
    }
    FullDivisionsPromptSheet.show(
      context,
      tournamentId: widget.tournament.id,
      divisions: pending,
    ).whenComplete(() {
      if (mounted) setState(() => _fullPromptActive = false);
    });
  }

  VoidCallback _openBulkRegistrationSheet(
    List<Map<String, dynamic>> divisions,
  ) => () {
    RegistrationDivisionsBulkSheet.show(
      context,
      tournamentId: widget.tournament.id,
      tournamentStatus: widget.tournament.status.toUpperCase(),
      tournamentDeadline: widget.tournament.registrationEndDate,
      divisions: divisions,
    ).whenComplete(() {
      if (mounted) _reload();
    });
  };

  /// Sheet hạng mục duy nhất cho tạo mới (đối chiếu Web `CreateDivisionModal`).
  Future<void> _addDivision() async {
    final saved = await DivisionEditorSheet.show(
      context,
      tournament: widget.tournament,
    );
    if (saved == true && mounted) _reload();
  }

  /// Sheet hạng mục cho sửa (thay dialog đổi tên + dialog cấu hình cũ).
  Future<void> _editDivision(Map<String, dynamic> division) async {
    // Loading the stage takes a moment: ignore taps meanwhile.
    if (_configuring || _isBusy) return;
    _configuring = true;
    try {
      await _runEditDivision(division);
    } finally {
      _configuring = false;
    }
  }

  Future<void> _runEditDivision(Map<String, dynamic> division) async {
    final divisionId = _divisionId(division);
    if (divisionId.isEmpty) return;
    // Once the bracket exists the Swiss config lives on the stage.
    SwissStageInfo? stage;
    var minPlayed = 0;
    if (_isSwiss(division['bracketType'])) {
      try {
        final repo = ref.read(tournamentRepositoryProvider);
        stage = await repo.getSwissStage(
          widget.tournament.id,
          divisionId: divisionId,
        );
        if (stage != null) {
          final matches = await repo.getBracketMatches(
            widget.tournament.id,
            divisionId: divisionId,
          );
          minPlayed = swissRoundState(matches, 0).currentRound;
        }
      } catch (_) {
        if (mounted) setState(() => _mutationError = 'error');
        return;
      }
      if (!mounted) return;
    }
    // Khoá kết cấu khi hạng mục đã sinh sơ đồ: Backend chặn updateDivision
    // sau đó, Swiss thì chỉ vá được stage (lockContent như dialog cũ).
    final lockContent = stage != null || _divisionHasBracket(divisionId);
    final saved = await DivisionEditorSheet.show(
      context,
      tournament: widget.tournament,
      division: division,
      swissStage: stage,
      swissMinPlayedRounds: minPlayed,
      lockContent: lockContent,
      onDelete: () => _deleteDivision(division),
    );
    if (saved == true && mounted) _reload();
  }

  /// Sheet cấu hình từng vòng của stage (task 2.2): chỉ mở khi hạng mục đã
  /// sinh sơ đồ; Swiss không có vòng riêng để cấu hình (Web trả danh sách
  /// rỗng cho SWISS) nên ẩn nút.
  Future<void> _configureRounds(Map<String, dynamic> division) async {
    if (_configuring || _isBusy) return;
    _configuring = true;
    try {
      final saved = await StageRoundConfigSheet.show(
        context,
        tournament: widget.tournament,
        division: division,
      );
      if (saved == true && mounted) _reload();
    } finally {
      _configuring = false;
    }
  }

  /// Hạng mục đã có sơ đồ chưa: soi danh sách trận của giải (trận sinh cùng
  /// sơ đồ, cùng tín hiệu với cảnh báo "chưa sơ đồ" của sheet khai mạc).
  bool _divisionHasBracket(String divisionId) {
    final matches = ref
        .read(matchesProvider(widget.tournament.id))
        .asData
        ?.value;
    return matches?.any((match) => match.divisionId == divisionId) ?? false;
  }

  Future<void> _toggleRegistration(Map<String, dynamic> division) async {
    final divisionId = _divisionId(division);
    if (divisionId.isEmpty) return;
    await _mutate(
      () =>
          ref.read(tournamentManagementRepositoryProvider).updateDivisionConfig(
            widget.tournament.id,
            divisionId,
            {'isRegistrationLocked': !_isRegistrationLocked(division)},
          ),
    );
    // Mở/đóng nội dung có thể đổi trạng thái cả giải (Đang mở ⇄ Đã đóng).
    if (mounted) ref.invalidate(tournamentProvider(widget.tournament.id));
  }

  /// Quá hạn thì mở lại phải kèm hạn mới, nếu không server vẫn coi là đóng.
  Future<void> _reopenWithDeadline(Map<String, dynamic> division) async {
    final divisionId = _divisionId(division);
    if (divisionId.isEmpty) return;
    final deadline = await pickTournamentManagementDeadline(context);
    if (deadline == null || !mounted) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .updateDivisionConfig(widget.tournament.id, divisionId, {
            'isRegistrationLocked': false,
            'registrationEndDate': deadline.toUtc().toIso8601String(),
          }),
    );
    if (mounted) ref.invalidate(tournamentProvider(widget.tournament.id));
  }

  Future<void> _deleteDivision(Map<String, dynamic> division) async {
    final l10n = AppLocalizations.of(context)!;
    final divisionId = _divisionId(division);
    if (divisionId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementDeleteDivision,
      message: l10n.tournamentManagementDeleteDivisionConfirm(
        _divisionName(division),
      ),
      confirmLabel: l10n.tournamentManagementDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .deleteDivision(divisionId),
    );
  }

  Future<void> _mutate<T>(Future<T> Function() operation) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await operation();
      if (mounted) _reload();
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _DivisionCard extends StatelessWidget {
  const _DivisionCard({
    required this.division,
    required this.isBusy,
    required this.canToggleRegistration,
    required this.onEdit,
    required this.onConfigureRounds,
    required this.onToggleRegistration,
    required this.onReopenWithDeadline,
    required this.onDelete,
  });
  final Map<String, dynamic> division;
  final bool isBusy;
  final bool canToggleRegistration;
  final VoidCallback onEdit;

  /// null = chưa có sơ đồ (hoặc Swiss): ẩn mục cấu hình từng vòng.
  final VoidCallback? onConfigureRounds;
  final VoidCallback onToggleRegistration;
  final VoidCallback onReopenWithDeadline;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final match = (division['matchType'] ?? '').toString().toUpperCase();
    final bracket = (division['bracketType'] ?? '').toString().toUpperCase();
    final maximum = division['maxParticipants']?.toString();
    final locked = _isRegistrationLocked(division);
    final deadline = _registrationDeadline(division);
    final expired = deadline != null && !deadline.isAfter(DateTime.now());
    final registrationOpen = division['registrationOpen'];
    final registrationLabel = switch (registrationOpen) {
      true when deadline == null =>
        '${l10n.tournamentManagementDivisionRegistrationOpen} · ${l10n.tournamentManagementDivisionNoDeadline}',
      true => l10n.tournamentManagementDivisionRegistrationOpen,
      false => l10n.tournamentManagementDivisionRegistrationClosed,
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _divisionName(division),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_matchTypeLabel(l10n, match)} · ${_bracketTypeLabel(l10n, bracket)}${maximum == null ? '' : ' · ${l10n.tournamentManagementMaxParticipants}: $maximum'}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                if (registrationLabel != null)
                  Text(
                    registrationLabel,
                    style: TextStyle(
                      color: registrationOpen == true
                          ? colors.textSecondary
                          : colors.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !isBusy,
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'rounds') onConfigureRounds?.call();
              if (value == 'registration') onToggleRegistration();
              if (value == 'reopen-deadline') onReopenWithDeadline();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(l10n.divisionEditorEditTitle),
              ),
              // Cấu hình từng vòng chỉ có khi hạng mục đã sinh sơ đồ.
              if (onConfigureRounds != null)
                PopupMenuItem(
                  value: 'rounds',
                  child: Text(l10n.stageRoundMenuTitle),
                ),
              // Quá hạn mà mở lại thì phải đặt hạn mới; còn hạn thì bật/tắt khoá.
              if (expired)
                PopupMenuItem(
                  value: 'reopen-deadline',
                  enabled: canToggleRegistration,
                  child: Text(
                    l10n.tournamentManagementDivisionReopenWithDeadline,
                  ),
                )
              else
                PopupMenuItem(
                  value: 'registration',
                  enabled: canToggleRegistration,
                  child: Text(
                    locked
                        ? l10n.tournamentManagementDivisionUnlockRegistration
                        : l10n.tournamentManagementDivisionLockRegistration,
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.tournamentManagementDelete,
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentSeedsSection extends ConsumerStatefulWidget {
  const _TournamentSeedsSection({
    required this.tournamentId,
    required this.divisions,
  });
  final String tournamentId;
  final List<Map<String, dynamic>> divisions;
  @override
  ConsumerState<_TournamentSeedsSection> createState() =>
      _TournamentSeedsSectionState();
}

class _TournamentSeedsSectionState
    extends ConsumerState<_TournamentSeedsSection> {
  String? _divisionId;
  Future<List<OrganizerOpsParticipant>>? _participantsFuture;
  final Map<String, int?> _seeds = {};
  bool _isBusy = false;
  String? _error;

  String? get _activeDivisionId {
    final ids = widget.divisions
        .map(_divisionIdFor)
        .where((id) => id.isNotEmpty)
        .toSet();
    if (_divisionId != null && ids.contains(_divisionId)) return _divisionId;
    return ids.isEmpty ? null : ids.first;
  }

  void _loadParticipants(String? divisionId) {
    if (divisionId == null) {
      _participantsFuture = Future.value(const <OrganizerOpsParticipant>[]);
      return;
    }
    _participantsFuture = ref
        .read(tournamentRepositoryProvider)
        .getOrganizerParticipants(widget.tournamentId, divisionId: divisionId);
    _seeds.clear();
  }

  @override
  void initState() {
    super.initState();
    _divisionId = _activeDivisionId;
    _loadParticipants(_divisionId);
  }

  @override
  void didUpdateWidget(covariant _TournamentSeedsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_divisionId == null ||
        !widget.divisions.any(
          (division) => _divisionIdFor(division) == _divisionId,
        )) {
      _divisionId = _activeDivisionId;
      _loadParticipants(_divisionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final divisionId = _activeDivisionId;
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementSeeding,
      subtitle: l10n.tournamentManagementSeedingDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: divisionId,
            decoration: InputDecoration(
              labelText: l10n.tournamentManagementDivision,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final division in widget.divisions)
                DropdownMenuItem(
                  value: _divisionIdFor(division),
                  child: Text(_divisionName(division)),
                ),
            ],
            onChanged: _isBusy
                ? null
                : (value) {
                    if (value != null)
                      setState(() {
                        _divisionId = value;
                        _loadParticipants(value);
                        _error = null;
                      });
                  },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isBusy || divisionId == null ? null : _autoSeed,
                icon: _isBusy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(l10n.tournamentManagementAutoSeed),
              ),
              FilledButton.icon(
                onPressed: _isBusy || divisionId == null ? null : _saveSeeds,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.tournamentManagementSaveSeeds),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error == 'validation'
                  ? l10n.tournamentManagementSeedValidationError
                  : l10n.tournamentManagementActionError,
              style: TextStyle(color: context.colors.error),
            ),
          ],
          const SizedBox(height: 10),
          if (_participantsFuture == null)
            TournamentManagementEmpty(
              title: l10n.tournamentManagementParticipantsEmpty,
              icon: Icons.groups_outlined,
            )
          else
            FutureBuilder<List<OrganizerOpsParticipant>>(
              future: _participantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                if (snapshot.hasError)
                  return TournamentManagementError(
                    error: snapshot.error,
                    onRetry: () =>
                        setState(() => _loadParticipants(divisionId)),
                  );
                final participants =
                    snapshot.data ?? const <OrganizerOpsParticipant>[];
                if (participants.isEmpty)
                  return TournamentManagementEmpty(
                    title: l10n.tournamentManagementParticipantsEmpty,
                    icon: Icons.groups_outlined,
                  );
                return Column(
                  children: [
                    for (final participant in participants)
                      _SeedRow(
                        participant: participant,
                        onChanged: (value) => _seeds[participant.id] = value,
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _autoSeed() async {
    if (_isBusy || _activeDivisionId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementAutoSeed,
      message: l10n.tournamentManagementAutoSeedConfirm,
      confirmLabel: l10n.tournamentManagementAutoSeed,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .autoSeedParticipants(
            widget.tournamentId,
            divisionId: _activeDivisionId,
          );
      if (!mounted) return;
      setState(() => _loadParticipants(_activeDivisionId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tournamentManagementSeedsSaved)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _saveSeeds() async {
    if (_isBusy || _activeDivisionId == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final participants = await _participantsFuture;
      if (!mounted || participants == null || participants.isEmpty) return;
      final currentSeeds = {
        for (final participant in participants)
          participant.id: _seeds.containsKey(participant.id)
              ? _seeds[participant.id]
              : participant.seed,
      };
      final clearedExistingSeed = participants.any(
        (participant) =>
            participant.seed != null &&
            _seeds.containsKey(participant.id) &&
            _seeds[participant.id] == null,
      );
      final values = currentSeeds.values.whereType<int>().toList();
      if (clearedExistingSeed ||
          values.any((value) => value < 1) ||
          values.toSet().length != values.length) {
        setState(() => _error = 'validation');
        return;
      }
      await ref
          .read(tournamentManagementRepositoryProvider)
          .updateTournamentSeeds(widget.tournamentId, [
            for (final participant in participants)
              if (currentSeeds[participant.id] case final int seed)
                {'participantId': participant.id, 'seed': seed},
          ]);
      if (!mounted) return;
      setState(() => _loadParticipants(_activeDivisionId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tournamentManagementSeedsSaved)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({required this.participant, required this.onChanged});
  final OrganizerOpsParticipant participant;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: ParticipantLabel(
              teamName: participant.teamName,
              players: participant.players,
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
          SizedBox(
            width: 88,
            child: TextFormField(
              key: ValueKey('${participant.id}-${participant.seed}'),
              initialValue: participant.seed?.toString() ?? '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.tournamentManagementSeed,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => onChanged(int.tryParse(value.trim())),
            ),
          ),
        ],
      ),
    );
  }
}

String _divisionId(Map<String, dynamic> division) =>
    (division['id'] ?? division['divisionId'] ?? '').toString();
String _divisionIdFor(Map<String, dynamic> division) => _divisionId(division);
String _divisionName(Map<String, dynamic> division) =>
    (division['name'] ?? '').toString();

/// Khoá hiệu lực do server tính (khoá nội dung hoặc khoá cả giải sau "Chốt").
bool _isRegistrationLocked(Map<String, dynamic> division) =>
    (division['effectiveIsRegistrationLocked'] ??
        division['isRegistrationLocked']) ==
    true;

/// Hạn hiệu lực: hạn riêng nội dung, không có thì hạn giải (server tính sẵn).
DateTime? _registrationDeadline(Map<String, dynamic> division) {
  final raw =
      division['effectiveRegistrationEndDate'] ??
      division['registrationEndDate'];
  return raw is String ? DateTime.tryParse(raw) : null;
}

bool _isSwiss(Object? bracketType) =>
    bracketType?.toString().toUpperCase() == 'SWISS';

String _matchTypeLabel(AppLocalizations l10n, String value) =>
    switch (value.toUpperCase()) {
      'SINGLES' => l10n.tournamentManagementMatchSingles,
      'DOUBLES' => l10n.tournamentManagementMatchDoubles,
      'MIXED_DOUBLES' => l10n.tournamentManagementMatchMixedDoubles,
      _ => l10n.tournamentManagementStatusOther,
    };

String _bracketTypeLabel(AppLocalizations l10n, String value) => switch (value
    .toUpperCase()) {
  'SINGLE_ELIMINATION' => l10n.tournamentManagementBracketSingleElimination,
  'DOUBLE_ELIMINATION' => l10n.tournamentManagementBracketDoubleElimination,
  'ROUND_ROBIN' => l10n.tournamentManagementBracketRoundRobin,
  'GROUP_STAGE_KNOCKOUT' => l10n.tournamentManagementBracketGroupThenKnockout,
  'SWISS' => l10n.tournamentManagementBracketSwiss,
  _ => l10n.tournamentManagementStatusOther,
};
