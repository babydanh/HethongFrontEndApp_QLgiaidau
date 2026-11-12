import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_live_status_action.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/camera_wall_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_court_info.dart';
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

/// Organizer camera board: one card per court, one pool of matches.
///
/// Assigning a match to a court goes through `PATCH /matches/{id}/schedule`
/// with the court id — the backend then hands the match that court's camera.
/// Nothing is moved locally: the match list is server state, so a failed write
/// leaves the board exactly as it was.
///
/// Dragging is the fast path, not the only one — a match can also be assigned
/// from its own court menu, or by selecting it and pressing the button on the
/// target court.
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

  /// Match picked with a single tap, waiting for a court to be chosen.
  String? _selectedMatchId;

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
    setState(() {
      _busyMatchIds.add(match.id);
      _selectedMatchId = null;
    });
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
        final selectedMatch = assignable
            .where((match) => match.id == _selectedMatchId)
            .firstOrNull;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CameraTabHeader(
              cameras: camerasAsync.asData == null ? null : cameras,
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
            if (selectedMatch != null)
              _SelectionBanner(
                label: _matchLabel(l10n, selectedMatch),
                onClear: () => setState(() => _selectedMatchId = null),
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
                matches: assignable,
                isLoading: matchesAsync.isLoading,
                courts: courts,
                busyMatchIds: _busyMatchIds,
                selectedMatchId: _selectedMatchId,
                readOnly: widget.readOnly,
                onSelected: (match) =>
                    setState(() => _selectedMatchId = match.id),
                onAssign: _assignToCourt,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              for (final court in courts) ...[
                _CourtDropCard(
                  tournamentId: widget.tournamentId,
                  court: court,
                  camera: cameraForCourt(cameras, court.id),
                  matchesHere: assignable
                      .where((match) => match.courtId == court.id)
                      .toList(growable: false),
                  assignable: assignable,
                  allMatches: matches,
                  cameras: cameras,
                  busyMatchIds: _busyMatchIds,
                  selectedMatch: selectedMatch,
                  readOnly: widget.readOnly,
                  onAssign: (match) => _assignToCourt(match, court),
                  onPickCamera: (match, camera) =>
                      _assignCameraToMatch(match, camera),
                ),
                const SizedBox(height: AppTheme.spacingMD),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// Banner shown while a match is selected and waiting for a court.
class _SelectionBanner extends StatelessWidget {
  const _SelectionBanner({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingSM),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.touch_app_rounded, size: 18),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tournamentManagementCameraSelectHint,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.tournamentManagementCameraSelectedMatch(label),
                  style: TextStyle(color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(l10n.tournamentManagementCameraClearSelection),
          ),
        ],
      ),
    );
  }
}

/// Drag sources, plus the tap and court-menu assignment paths.
class _MatchPool extends StatelessWidget {
  const _MatchPool({
    required this.tournamentId,
    required this.cameras,
    required this.matches,
    required this.isLoading,
    required this.courts,
    required this.busyMatchIds,
    required this.selectedMatchId,
    required this.readOnly,
    required this.onSelected,
    required this.onAssign,
  });

  final String tournamentId;
  final List<TournamentCameraModel> cameras;
  final List<MatchModel> matches;
  final bool isLoading;
  final List<TournamentCourtRef> courts;
  final Set<String> busyMatchIds;
  final String? selectedMatchId;
  final bool readOnly;
  final ValueChanged<MatchModel> onSelected;
  final Future<void> Function(MatchModel, TournamentCourtRef) onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementCameraMatchPool,
      subtitle: l10n.tournamentManagementCameraMatchPoolHint,
      child: isLoading && matches.isEmpty
          ? const BoneListLoading(itemCount: 3, leadingAvatar: false)
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
                    isSelected: selectedMatchId == matches[i].id,
                    draggable: true,
                    courts: courts,
                    onSelected: () => onSelected(matches[i]),
                    onAssign: (court) => onAssign(matches[i], court),
                  ),
                ],
              ],
            ),
    );
  }
}

/// A court: drop target, playback-URL control and the matches scheduled there.
class _CourtDropCard extends StatelessWidget {
  const _CourtDropCard({
    required this.tournamentId,
    required this.court,
    required this.camera,
    required this.assignable,
    required this.allMatches,
    required this.matchesHere,
    required this.cameras,
    required this.busyMatchIds,
    required this.selectedMatch,
    required this.readOnly,
    required this.onAssign,
    required this.onPickCamera,
  });

  final String tournamentId;
  final TournamentCourtRef court;
  final TournamentCameraModel? camera;

  /// Every match that can be dropped here, not just the ones already on this
  /// court — the dragged match comes from the pool.
  final List<MatchModel> assignable;

  /// Every match of the tournament, finished ones included: the camera may
  /// still be showing one of them.
  final List<MatchModel> allMatches;
  final List<MatchModel> matchesHere;
  final List<TournamentCameraModel> cameras;
  final Set<String> busyMatchIds;
  final MatchModel? selectedMatch;
  final bool readOnly;
  final Future<void> Function(MatchModel match) onAssign;
  final Future<void> Function(MatchModel match, TournamentCameraModel camera)
  onPickCamera;

  MatchModel? _byId(String matchId) =>
      assignable.where((match) => match.id == matchId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final courtTitle = court.name.isEmpty ? court.id : court.name;
    final courtCamera = camera;
    final hasSelection = selectedMatch != null && !readOnly;

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: hasSelection ? AppTheme.primary : colors.border,
          width: hasSelection ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.sports_tennis_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courtTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (court.venueName.isNotEmpty)
                      Text(
                        court.venueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (courtCamera != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            CameraCourtInfo(
              tournamentId: tournamentId,
              camera: courtCamera,
              matches: allMatches,
              matchLabelOf: (match) => _matchLabel(l10n, match),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSM),
          CourtCameraUrlRow(
            tournamentId: tournamentId,
            courtId: court.id,
            courtName: courtTitle,
            readOnly: readOnly,
          ),
          if (courtCamera != null) ...[
            const SizedBox(height: AppTheme.spacingSM),
            CameraLiveStatusAction(cameraId: courtCamera.id),
          ],
          const SizedBox(height: AppTheme.spacingSM),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            l10n.tournamentManagementCameraMatchesHere(matchesHere.length),
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          if (matchesHere.isEmpty)
            Text(
              l10n.tournamentManagementCameraNoMatchesHere,
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            )
          else
            for (var i = 0; i < matchesHere.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.border),
              CameraMatchRow(
                tournamentId: tournamentId,
                match: matchesHere[i],
                label: _matchLabel(l10n, matchesHere[i]),
                hasCamera: _matchHasCamera(matchesHere[i], cameras),
                readOnly: readOnly,
                isBusy: busyMatchIds.contains(matchesHere[i].id),
                showCourtChip: false,
                cameras: cameras,
                onPickCamera: (value) => onPickCamera(matchesHere[i], value),
              ),
            ],
          if (hasSelection) ...[
            const SizedBox(height: AppTheme.spacingSM),
            SizedBox(
              height: kMinTouchTarget,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busyMatchIds.contains(selectedMatch!.id)
                    ? null
                    : () => onAssign(selectedMatch!),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(
                  l10n.tournamentManagementCameraAssignHere(
                    _matchLabel(l10n, selectedMatch!),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return DragTarget<CourtMatchDragData>(
      // A match already scheduled here has nothing to move, so it is refused
      // at the edge instead of answering with a "no change" message.
      onWillAcceptWithDetails: (details) =>
          _byId(details.data.matchId)?.courtId != court.id,
      onAcceptWithDetails: (details) {
        final match = _byId(details.data.matchId);
        if (match != null) onAssign(match);
      },
      builder: (context, candidates, rejected) {
        final isDropTarget = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: isDropTarget
                ? AppTheme.primary.withValues(alpha: 0.14)
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: card,
        );
      },
    );
  }
}
