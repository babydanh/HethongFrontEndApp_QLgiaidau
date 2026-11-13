import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/court_camera_matches.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_live_status_action.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stream_key_qr_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Mở popup của một sân. [courtId] null là nhóm camera chưa gắn sân: chỉ có
/// hành động trên camera, không có URL phát và không có trận.
Future<void> showCourtCameraPopup(
  BuildContext context, {
  required String tournamentId,
  required String? courtId,
  required String courtName,
  bool readOnly = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => CourtCameraPopup(
    tournamentId: tournamentId,
    courtId: courtId,
    courtName: courtName,
    readOnly: readOnly,
  ),
);

const _maskedUrl = '••••••••••••';

/// Popup (bottom sheet) của một sân: URL phát (che, bấm mới sửa), camera PUSH
/// của sân (QR stream key, xoá) và các trận của sân, trận chưa xong ở trên.
///
/// Mọi thay đổi đi qua repository có sẵn rồi đọc lại danh sách camera: máy chủ
/// là nguồn đúng, popup không tự vá dữ liệu cục bộ.
class CourtCameraPopup extends ConsumerStatefulWidget {
  const CourtCameraPopup({
    super.key,
    required this.tournamentId,
    required this.courtId,
    required this.courtName,
    this.readOnly = false,
  });

  final String tournamentId;
  final String? courtId;
  final String courtName;
  final bool readOnly;

  @override
  ConsumerState<CourtCameraPopup> createState() => _CourtCameraPopupState();
}

class _CourtCameraPopupState extends ConsumerState<CourtCameraPopup> {
  final TextEditingController _url = TextEditingController();
  bool _editing = false;
  bool _reveal = false;
  bool _saving = false;
  final Set<String> _busyCameraIds = <String>{};

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  List<TournamentCameraModel> get _cameras =>
      ref.read(tournamentCamerasProvider(widget.tournamentId)).value ??
      const <TournamentCameraModel>[];

  TournamentCameraModel? get _courtCamera {
    final courtId = widget.courtId;
    return courtId == null ? null : cameraForCourt(_cameras, courtId);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _toggleEditor() {
    if (widget.readOnly) return;
    setState(() {
      _editing = !_editing;
      if (_editing) _url.text = _courtCamera?.playbackUrl ?? '';
    });
  }

  Future<void> _writeUrl(String url, String doneText) async {
    final courtId = widget.courtId;
    if (courtId == null || _saving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref
          .read(tournamentCamerasProvider(widget.tournamentId).notifier)
          .setCourtPlaybackUrl(courtId: courtId, playbackUrl: url);
      if (!mounted) return;
      setState(() => _editing = false);
      _toast(doneText);
    } on Object {
      // Máy chủ có thể trả lại URL trong thông báo lỗi, nên chỉ hiện chuỗi cố định.
      if (mounted) _toast(l10n.tournamentManagementCameraUrlSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final url = _url.text.trim();
    if (url.isEmpty) {
      _toast(l10n.tournamentManagementCameraUrlRequired);
      return Future<void>.value();
    }
    return _writeUrl(url, l10n.tournamentManagementCameraUrlSaved);
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementCameraClearUrl,
      message: l10n.tournamentManagementCameraClearUrlConfirm(widget.courtName),
      confirmLabel: l10n.tournamentManagementCameraClearUrl,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _writeUrl('', l10n.tournamentManagementCameraUrlCleared);
  }

  /// QR chứa stream key nên không bao giờ chỉ cách một lần chạm: hỏi trước.
  Future<void> _openStreamKey(TournamentCameraModel camera) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentStreamKeyConfirmTitle,
      message: l10n.tournamentStreamKeyConfirmMessage,
      confirmLabel: l10n.tournamentStreamKeyConfirmAction,
    );
    if (!confirmed || !mounted) return;
    await StreamKeyQrSheet.show(context, camera: camera);
  }

  Future<void> _deleteCamera(TournamentCameraModel camera) async {
    if (_busyCameraIds.contains(camera.id)) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: l10n.tournamentCameraDeleteConfirm(camera.name),
      confirmLabel: l10n.tournamentManagementDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyCameraIds.add(camera.id));
    try {
      await ref.read(cameraAdminRepositoryProvider).deleteCamera(camera.id);
      await ref
          .read(tournamentCamerasProvider(widget.tournamentId).notifier)
          .refresh();
      if (mounted) _toast(l10n.tournamentCameraDeleted(camera.name));
    } on Object catch (failure) {
      if (mounted) {
        _toast(
          tournamentSheetServerMessage(failure) ??
              ErrorParser.parse(
                failure,
                l10n.tournamentCameraActionFailed,
                l10n,
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyCameraIds.remove(camera.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final courtId = widget.courtId;
    final cameras =
        ref.watch(tournamentCamerasProvider(widget.tournamentId)).value ??
        const <TournamentCameraModel>[];
    final courtCamera = courtId == null
        ? null
        : cameraForCourt(cameras, courtId);
    // Camera PULL của sân đã nằm trong dòng URL; chỉ camera PUSH (có QR, xoá
    // được) và nhóm chưa gắn sân mới cần dòng riêng.
    final cameraRows = [
      for (final camera in cameras)
        if (courtId == null
            ? camera.courtId == null
            : camera.courtId == courtId && camera.mode == 'PUSH')
          camera,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, courtCamera),
            if (courtId != null) _urlSection(context, l10n, courtCamera),
            for (final camera in cameraRows) _cameraRow(l10n, camera),
            if (courtId != null) _matches(context, l10n, courtId),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, TournamentCameraModel? camera) {
    final colors = LavishColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.courtName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
          ),
          if (camera != null) CameraStatusBadge(status: camera.status),
        ],
      ),
    );
  }

  Widget _urlSection(
    BuildContext context,
    AppLocalizations l10n,
    TournamentCameraModel? camera,
  ) {
    final colors = LavishColors.of(context);
    final url = camera?.playbackUrl;
    final hasUrl = url != null && url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const ValueKey('court-camera-url-row'),
            borderRadius: BorderRadius.circular(12),
            onTap: _toggleEditor,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
              decoration: BoxDecoration(
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.courtCamUrlLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      !hasUrl
                          ? l10n.courtCamUrlEmpty
                          : _reveal
                          ? url
                          : _maskedUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colors.text),
                    ),
                  ),
                  if (hasUrl)
                    IconButton(
                      key: const ValueKey('court-camera-url-reveal'),
                      tooltip: _reveal
                          ? l10n.tournamentManagementCameraHideUrl
                          : l10n.tournamentManagementCameraShowUrl,
                      onPressed: () => setState(() => _reveal = !_reveal),
                      icon: Icon(
                        _reveal
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  if (!widget.readOnly)
                    IconButton(
                      tooltip: l10n.courtCamUrlEdit,
                      onPressed: _toggleEditor,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                ],
              ),
            ),
          ),
          if (_editing) _urlEditor(l10n, camera, hasUrl),
        ],
      ),
    );
  }

  Widget _urlEditor(
    AppLocalizations l10n,
    TournamentCameraModel? camera,
    bool hasUrl,
  ) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('court-camera-url-field'),
          controller: _url,
          enabled: !_saving,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            hintText: l10n.tournamentManagementCameraUrlHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            if (camera != null) CameraLiveStatusAction(cameraId: camera.id),
            if (hasUrl)
              IconButton(
                key: const ValueKey('court-camera-url-clear'),
                tooltip: l10n.tournamentManagementCameraClearUrl,
                onPressed: _saving ? null : _clear,
                icon: const Icon(Icons.link_off_rounded),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.tournamentManagementSave),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _cameraRow(AppLocalizations l10n, TournamentCameraModel camera) {
    final enabled = !widget.readOnly && !_busyCameraIds.contains(camera.id);
    return LavishRow(
      key: ValueKey('camera-card-${camera.id}'),
      leading: const LavishIconBox(child: Icon(Icons.videocam_rounded)),
      title: camera.name,
      subtitle: camera.mode,
      trailing: [
        CameraStatusBadge(status: camera.status),
        // Chỉ camera PUSH có stream key; camera PULL chỉ là một URL.
        if (camera.mode == 'PUSH')
          IconButton(
            key: ValueKey('camera-stream-key-${camera.id}'),
            tooltip: l10n.tournamentStreamKeyTooltip,
            onPressed: enabled ? () => _openStreamKey(camera) : null,
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
        if (!widget.readOnly)
          IconButton(
            key: ValueKey('camera-delete-${camera.id}'),
            tooltip: l10n.tournamentCameraDeleteTooltip,
            onPressed: enabled ? () => _deleteCamera(camera) : null,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: LavishColors.bad,
            ),
          ),
      ],
    );
  }

  Widget _matches(BuildContext context, AppLocalizations l10n, String courtId) {
    final matches = ref.watch(
      managedMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: null,
      )),
    );
    final rows = courtCameraMatches(
      matches.value ?? const <MatchModel>[],
      courtId,
    );
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          l10n.courtCamNoMatches,
          style: TextStyle(color: LavishColors.of(context).muted),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [for (final match in rows) _CourtMatchRow(match)],
      ),
    );
  }
}

/// Một dòng trận: mã trận và giờ, hai bên (kèm điểm khi đã/đang đấu), trạng thái.
class _CourtMatchRow extends StatelessWidget {
  const _CourtMatchRow(this.match);

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    final phase = courtMatchPhase(match);
    final time = match.scheduledTime;
    final showScore = phase != CourtMatchPhase.upcoming;
    String side(int n) {
      final label = matchSideLabel(match, n);
      return label.isEmpty ? l10n.matchNotDetermined : label;
    }

    Widget team(int n, int score) => Row(
      children: [
        Expanded(
          child: Text(side(n), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (showScore)
          Text('$score', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );

    final (label, tone) = switch (phase) {
      CourtMatchPhase.live => (l10n.organizer_statusOngoing, LavishTone.bad),
      CourtMatchPhase.upcoming => (
        l10n.resultsBoard_upcoming,
        LavishTone.accent,
      ),
      CourtMatchPhase.done => (l10n.resultsBoard_doneBadge, LavishTone.neutral),
    };
    return Opacity(
      opacity: phase == CourtMatchPhase.done ? 0.6 : 1,
      child: Container(
        key: ValueKey('court-match-${match.matchCode ?? match.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rowLine)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.matchCode ?? '#${match.matchNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (time != null)
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: TextStyle(fontSize: 11, color: colors.muted),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [team(1, match.score1), team(2, match.score2)],
              ),
            ),
            const SizedBox(width: 10),
            LavishPill(label, tone: tone),
          ],
        ),
      ),
    );
  }
}
