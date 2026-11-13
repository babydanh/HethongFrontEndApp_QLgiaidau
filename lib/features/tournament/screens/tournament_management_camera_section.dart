import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/camera_wall_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_create_flow.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_court_card.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_match_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_tab_header.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

/// Tên VĐV khi đội không có tên (domain để `''`); bên trống hẳn là
/// "Chưa xác định" để nhãn không chỉ còn dấu "–".
String _matchLabel(AppLocalizations l10n, MatchModel match) {
  String side(int n) {
    final label = matchSideLabel(match, n);
    return label.isEmpty ? l10n.matchNotDetermined : label;
  }

  return '${side(1)} – ${side(2)}';
}

/// Trận có camera: gán riêng hoặc sân của trận có URL camera (như Web).
bool _matchHasCamera(MatchModel match, List<TournamentCameraModel> cameras) {
  final courtId = match.courtId;
  if (courtId == null || courtId.isEmpty) return false;
  return cameraForCourt(cameras, courtId)?.hasPlaybackUrl ?? false;
}

/// Matches that can be moved onto a court: real fixtures that have not
/// finished. BYE and completed rows have nothing left to schedule.
List<MatchModel> _assignableMatches(List<MatchModel> matches) => matches
    .where(
      (match) =>
          match.hasTeams &&
          !match.isByeMatch &&
          !match.isFullByeMatch &&
          !match.isCompleted,
    )
    .toList(growable: false);

/// Organizer camera board: one collapsed card per court (tap for the court
/// popup with its matches), one pool of matches.
///
/// Assigning a match to a court goes through `PATCH /matches/{id}/schedule`
/// with the court id — the backend then hands the match that court's camera.
/// Nothing is moved locally: the match list is server state, so a failed write
/// leaves the board exactly as it was.
///
/// A match is assigned from the court menu (⋯) on its row; there is no
/// drag-and-drop.
class TournamentManagementCameraSection extends ConsumerStatefulWidget {
  const TournamentManagementCameraSection({
    super.key,
    required this.tournamentId,
    this.divisionId,
    this.readOnly = false,
  });

  final String tournamentId;
  final String? divisionId;
  final bool readOnly;

  @override
  ConsumerState<TournamentManagementCameraSection> createState() =>
      _TournamentManagementCameraSectionState();
}

class _TournamentManagementCameraSectionState
    extends ConsumerState<TournamentManagementCameraSection> {
  late Future<List<Map<String, dynamic>>> _venuesFuture;

  /// Court shown alone; null = every court.
  String? _courtFilterId;

  CameraMatchFilter _filter = const CameraMatchFilter();

  /// Matches with an assignment in flight, so only that row shows a spinner.
  final Set<String> _busyMatchIds = <String>{};

  @override
  void initState() {
    super.initState();
    _venuesFuture = ref
        .read(tournamentManagementRepositoryProvider)
        .getVenues(widget.tournamentId);
  }

  void _reloadVenues() {
    setState(() {
      _venuesFuture = ref
          .read(tournamentManagementRepositoryProvider)
          .getVenues(widget.tournamentId);
    });
  }

  /// Flattens venues into courts. A court without an id cannot be addressed by
  /// the camera routes, so it is dropped instead of shown as a row that can
  /// never be assigned.
  List<TournamentCourtRef> _courtsOf(List<Map<String, dynamic>> venues) {
    final courts = <TournamentCourtRef>[];
    for (final venue in venues) {
      final venueName = tournamentManagementRecordName(venue);
      final address = (venue['locationAddress'] ?? venue['address'] ?? '')
          .toString();
      final rawCourts = venue['courts'];
      if (rawCourts is! List) continue;
      for (final rawCourt in rawCourts) {
        if (rawCourt is! Map) continue;
        final court = Map<String, dynamic>.from(rawCourt);
        final id = (court['id'] ?? court['courtId'] ?? '').toString();
        if (id.isEmpty) continue;
        courts.add(
          TournamentCourtRef(
            id: id,
            name: (court['name'] ?? court['courtName'] ?? '').toString(),
            venueName: venueName,
            address: address,
          ),
        );
      }
    }
    return courts;
  }

  Future<void> _assignToCourt(
    MatchModel match,
    TournamentCourtRef court,
  ) async {
    if (_busyMatchIds.contains(match.id)) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    if (match.courtId == court.id) {
      _showMessage(
        l10n.tournamentManagementCameraAlreadyAssigned(
          _matchLabel(l10n, match),
          court.name,
        ),
      );
      return;
    }
    setState(() => _busyMatchIds.add(match.id));
    try {
      await ref
          .read(matchRepositoryProvider)
          .updateSchedule(
            widget.tournamentId,
            match.id,
            courtId: court.id,
            courtName: court.name.isEmpty ? null : court.name,
            courtAddress: court.address.isEmpty ? null : court.address,
          );
      // Which camera a match ends up on is the server's call, so both lists
      // are re-read instead of patched locally.
      ref.invalidate(
        managedMatchesWithDivisionProvider((
          tournamentId: widget.tournamentId,
          divisionId: widget.divisionId,
        )),
      );
      await ref
          .read(tournamentCamerasProvider(widget.tournamentId).notifier)
          .refresh();
      if (!mounted) return;
      _showMessage(
        l10n.tournamentManagementCameraAssigned(
          _matchLabel(l10n, match),
          court.name,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        ErrorParser.parse(
          error,
          l10n.tournamentManagementCameraAssignFailed,
          l10n,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyMatchIds.remove(match.id));
    }
  }

  Future<void> _assignCameraToMatch(
    MatchModel match,
    TournamentCameraModel camera,
  ) async {
    if (_busyMatchIds.contains(match.id)) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    setState(() => _busyMatchIds.add(match.id));
    try {
      await ref
          .read(tournamentCamerasProvider(widget.tournamentId).notifier)
          .assignCamera(matchId: match.id, cameraId: camera.id);
      if (!mounted) return;
      _showMessage(l10n.tournamentManagementCameraManualAssigned(camera.name));
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        ErrorParser.parse(
          error,
          l10n.tournamentManagementCameraManualAssignFailed,
          l10n,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyMatchIds.remove(match.id));
    }
  }

  /// Collapsed card for one court; tapping opens the court popup. Byes and
  /// matches without both sides are not worth a row there.
  Widget _courtTile(
    AppLocalizations l10n,
    TournamentCourtRef court,
    List<MatchModel> matches,
    List<TournamentCameraModel> cameras,
  ) {
    final courtMatches = matches
        .where(
          (match) =>
              match.courtId == court.id &&
              match.hasTeams &&
              !match.isByeMatch &&
              !match.isFullByeMatch,
        )
        .toList(growable: false);
    final courtCamera = cameraForCourt(cameras, court.id);
    return CameraCourtTile(
      key: ValueKey('camera-court-tile-${court.id}'),
      court: court,
      camera: courtCamera,
      matchCount: courtMatches.length,
      onTap: () => showCameraCourtSheet(
        context,
        tournamentId: widget.tournamentId,
        court: court,
        camera: courtCamera,
        courtMatches: courtMatches,
        allMatches: matches,
        cameras: cameras,
        readOnly: widget.readOnly,
        labelOf: (match) => _matchLabel(l10n, match),
        hasCameraOf: (match) => _matchHasCamera(match, cameras),
        onPickCamera: _assignCameraToMatch,
      ),
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _venuesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TournamentManagementError(
            error: snapshot.error,
            onRetry: _reloadVenues,
          );
        }
        final courts = _courtsOf(
          snapshot.data ?? const <Map<String, dynamic>>[],
        );
        final matchesAsync = ref.watch(
          managedMatchesWithDivisionProvider((
            tournamentId: widget.tournamentId,
            divisionId: widget.divisionId,
          )),
        );
        final camerasAsync = ref.watch(
          tournamentCamerasProvider(widget.tournamentId),
        );
        final matches = matchesAsync.asData?.value ?? const <MatchModel>[];
        final assignable = _assignableMatches(matches);
        final cameras =
            camerasAsync.asData?.value ?? const <TournamentCameraModel>[];
        // Same stage label as the rest of the app ("Bảng A • Lượt 1", "Tứ
        // kết"), named against every match so bracket size is right.
        final stageLabels = {
          for (final match in assignable)
            match.id: MatchRoundLabel.formatRound(
              match: match,
              allMatches: matches,
              includeMatchCode: false,
              l10n: l10n,
            ),
        };
        String stageOf(MatchModel match) => stageLabels[match.id] ?? '';
        final visible = filterCameraMatches(
          matches: assignable,
          query: _filter.query,
          stage: _filter.stage,
          onlyNoCamera: _filter.onlyNoCamera,
          stageOf: stageOf,
          labelOf: (match) => _matchLabel(l10n, match),
          hasCameraOnCourt: (courtId) =>
              cameraForCourt(cameras, courtId) != null,
        );
        final activeCourtId = courts.any((court) => court.id == _courtFilterId)
            ? _courtFilterId
            : null;
        final shownCourts = activeCourtId == null
            ? courts
            : courts.where((court) => court.id == activeCourtId).toList();
        final poolMatches = activeCourtId == null
            ? visible
            : visible.where((match) => match.courtId == activeCourtId).toList();

        // Sized to its content and never scrolls on its own: the host page
        // scrolls, so the tournament header moves with it like on other tabs.
        return ListView(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            CameraTabHeader(
              cameras: camerasAsync.asData == null ? null : cameras,
              filter: _filter,
              stages: cameraMatchStages(assignable, stageOf),
              onFilterChanged: (value) => setState(() => _filter = value),
              onCreateCamera: widget.readOnly || courts.isEmpty
                  ? null
                  : () => runCreateCameraFlow(
                      context: context,
                      ref: ref,
                      tournamentId: widget.tournamentId,
                      courts: courts,
                      refresh: () => ref
                          .read(
                            tournamentCamerasProvider(
                              widget.tournamentId,
                            ).notifier,
                          )
                          .refresh(),
                    ),
              onRefresh: () => ref
                  .read(tournamentCamerasProvider(widget.tournamentId).notifier)
                  .refresh(),
              onWatchCameras: () => showCameraWall(
                context,
                tournamentId: widget.tournamentId,
                divisionId: widget.divisionId,
                courtNames: {
                  for (final court in courts)
                    court.id: court.name.isEmpty ? court.id : court.name,
                },
                matchLabelOf: (match) => _matchLabel(l10n, match),
              ),
            ),
            if (courts.length > 1)
              _CourtChips(
                courts: courts,
                selectedId: activeCourtId,
                onSelected: (id) => setState(() => _courtFilterId = id),
              ),
            const SizedBox(height: AppTheme.spacingMD),
            if (snapshot.connectionState == ConnectionState.waiting)
              const BoneListLoading(itemCount: 3, leadingAvatar: false)
            else if (courts.isEmpty)
              TournamentManagementEmpty(
                title: l10n.tournamentManagementCameraNoCourts,
                icon: Icons.sports_tennis_rounded,
              )
            else ...[
              _MatchPool(
                tournamentId: widget.tournamentId,
                cameras: cameras,
                matches: poolMatches,
                filterActive: _filter.isActive && assignable.isNotEmpty,
                onClearFilter: () =>
                    setState(() => _filter = const CameraMatchFilter()),
                isLoading: matchesAsync.isLoading,
                courts: courts,
                busyMatchIds: _busyMatchIds,
                readOnly: widget.readOnly,
                onAssign: _assignToCourt,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              for (final court in shownCourts) ...[
                _courtTile(l10n, court, matches, cameras),
                const SizedBox(height: AppTheme.spacingSM),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// Court filter: "Tất cả sân" plus one chip per court.
class _CourtChips extends StatelessWidget {
  const _CourtChips({
    required this.courts,
    required this.selectedId,
    required this.onSelected,
  });

  final List<TournamentCourtRef> courts;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingXS,
      children: [
        ChoiceChip(
          key: const ValueKey('camera-court-chip-all'),
          label: Text(l10n.camCourtAll),
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final court in courts)
          ChoiceChip(
            key: ValueKey('camera-court-chip-${court.id}'),
            label: Text(court.name.isEmpty ? court.id : court.name),
            selected: selectedId == court.id,
            onSelected: (_) => onSelected(court.id),
          ),
      ],
    );
  }
}

/// Matches that can be given a court from the row's ⋯ menu.
class _MatchPool extends StatelessWidget {
  const _MatchPool({
    required this.tournamentId,
    required this.cameras,
    required this.matches,
    required this.filterActive,
    required this.onClearFilter,
    required this.isLoading,
    required this.courts,
    required this.busyMatchIds,
    required this.readOnly,
    required this.onAssign,
  });

  final String tournamentId;
  final List<TournamentCameraModel> cameras;
  final List<MatchModel> matches;

  /// Có lọc đang bật trong khi vẫn còn trận để gán: danh sách rỗng là do lọc.
  final bool filterActive;
  final VoidCallback onClearFilter;
  final bool isLoading;
  final List<TournamentCourtRef> courts;
  final Set<String> busyMatchIds;
  final bool readOnly;
  final Future<void> Function(MatchModel, TournamentCourtRef) onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementCameraMatchPool,
      subtitle: l10n.tournamentManagementCameraMatchPoolHint,
      child: isLoading && matches.isEmpty
          ? const BoneListLoading(itemCount: 3, leadingAvatar: false)
          : matches.isEmpty && filterActive
          ? Column(
              children: [
                Text(l10n.camTabNoMatchFound),
                TextButton(
                  onPressed: onClearFilter,
                  child: Text(l10n.camTabClearFilter),
                ),
              ],
            )
          : matches.isEmpty
          ? TournamentManagementEmpty(
              title: l10n.tournamentManagementCameraMatchPoolEmpty,
              icon: Icons.sports_score_rounded,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < matches.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: context.colors.border),
                  CameraMatchRow(
                    tournamentId: tournamentId,
                    match: matches[i],
                    label: _matchLabel(l10n, matches[i]),
                    hasCamera: _matchHasCamera(matches[i], cameras),
                    readOnly: readOnly,
                    isBusy: busyMatchIds.contains(matches[i].id),
                    courts: courts,
                    onAssign: (court) => onAssign(matches[i], court),
                  ),
                ],
              ],
            ),
    );
  }
}
