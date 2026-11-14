import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/match/utils/live_embed.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_embed_player.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_add_help.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/facebook_live_panel.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Backend DTO bounds (`CreateCameraDto.name`).
const _nameMinLength = 2;
const _nameMaxLength = 255;

/// What the editor hands back. In edit mode only [courtId] is meaningful: the
/// web has no route to rename a camera or change its mode/URL, so the app
/// does not invent one.
class CameraEditorValue {
  const CameraEditorValue({
    required this.name,
    required this.mode,
    this.courtId,
    this.playbackUrl,
  });

  final String name;

  /// A new camera is always `PUSH` (AQP); an edited one keeps its own mode.
  final String mode;
  final String? courtId;

  /// Link live YouTube/Facebook đã chuẩn hoá; chỉ có khi tạo camera PULL.
  final String? playbackUrl;
}

/// Dựng khung xem trước của link live; test thay bằng widget giả để khỏi chạm plugin WebView.
typedef LivePreviewBuilder =
    Widget Function(BuildContext context, LiveEmbedResult embed);

Widget _defaultPreview(BuildContext context, LiveEmbedResult embed) =>
    LiveEmbedPlayer(key: ValueKey<String?>(embed.embedUrl), embed: embed);

typedef CameraEditorSubmit = Future<void> Function(CameraEditorValue value);

/// Sheet to add a camera (name and optional court; it always goes through AQP)
/// or, when [camera] is given, to move an existing camera to another court
/// (OpenSpec `quan-ly-giai-web-parity`, task 5.1).
///
/// [onSubmit] performs the write; the sheet closes with `true` when it returns
/// and shows the server message verbatim when it throws.
class CameraEditorSheet extends StatefulWidget {
  const CameraEditorSheet({
    super.key,
    required this.courts,
    required this.onSubmit,
    this.camera,
    this.previewBuilder = _defaultPreview,
    this.facebookLiveTournamentId,
    this.facebookLiveRepository,
  });

  /// Cả hai có mới hiện "Tạo live trên fanpage Facebook" (chỉ khi tạo camera mới).
  final String? facebookLiveTournamentId;
  final IFacebookCameraLiveRepository? facebookLiveRepository;

  final List<TournamentCourtRef> courts;
  final LivePreviewBuilder previewBuilder;
  final CameraEditorSubmit onSubmit;
  final TournamentCameraModel? camera;

  /// Drag is off from the start: the sheet can turn busy right after opening
  /// and the route's drag flags are fixed at push time.
  static Future<bool?> show(
    BuildContext context, {
    required List<TournamentCourtRef> courts,
    required CameraEditorSubmit onSubmit,
    TournamentCameraModel? camera,
    LivePreviewBuilder previewBuilder = _defaultPreview,
    String? facebookLiveTournamentId,
    IFacebookCameraLiveRepository? facebookLiveRepository,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => CameraEditorSheet(
      courts: courts,
      onSubmit: onSubmit,
      camera: camera,
      previewBuilder: previewBuilder,
      facebookLiveTournamentId: facebookLiveTournamentId,
      facebookLiveRepository: facebookLiveRepository,
    ),
  );

  @override
  State<CameraEditorSheet> createState() => _CameraEditorSheetState();
}

class _CameraEditorSheetState extends State<CameraEditorSheet> {
  final _nameController = TextEditingController();
  final _linkController = TextEditingController();
  bool _liveSource = false;
  late String? _courtId = widget.camera?.courtId;
  bool _busy = false;
  String? _nameError;
  String? _error;

  bool get _isEdit => widget.camera != null;

  LiveEmbedResult get _embed => LiveEmbed.parse(_linkController.text);
  bool get _canSubmit => !_liveSource || _embed.isOk;

  @override
  void dispose() {
    _nameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final nameInvalid =
        !_isEdit &&
        (name.length < _nameMinLength || name.length > _nameMaxLength);
    if (nameInvalid) {
      setState(() {
        _nameError = l10n.tournamentCameraNameInvalid(
          _nameMinLength,
          _nameMaxLength,
        );
      });
      return;
    }
    setState(() {
      _busy = true;
      _nameError = null;
      _error = null;
    });
    try {
      await widget.onSubmit(
        CameraEditorValue(
          name: widget.camera?.name ?? name,
          mode: widget.camera?.mode ?? (_liveSource ? 'PULL' : 'PUSH'),
          courtId: _courtId,
          playbackUrl: _liveSource && !_isEdit ? _embed.canonicalUrl : null,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            tournamentSheetServerMessage(failure) ??
            ErrorParser.parse(failure, l10n.tournamentCameraActionFailed, l10n);
      });
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!mounted || text == null || text.isEmpty) return;
    setState(() => _linkController.text = text);
  }

  String _liveError(AppLocalizations l10n, LiveEmbedError error) =>
      switch (error) {
        LiveEmbedError.channelPage => l10n.tournamentCameraLiveErrorChannel,
        LiveEmbedError.noVideoId => l10n.tournamentCameraLiveErrorNoId,
        LiveEmbedError.notEmbed => l10n.tournamentCameraLiveErrorUnsupported,
      };

  Widget _buildLiveLink(AppLocalizations l10n) {
    final colors = context.colors;
    final embed = _embed;
    final hasValue = _linkController.text.trim().isNotEmpty;
    final error = hasValue ? embed.error : null;
    final facebookTournamentId = widget.facebookLiveTournamentId;
    final facebookRepository = widget.facebookLiveRepository;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (facebookTournamentId != null && facebookRepository != null) ...[
          FacebookLivePanel(
            tournamentId: facebookTournamentId,
            repository: facebookRepository,
            enabled: !_busy,
            onCreated: (watchUrl) =>
                setState(() => _linkController.text = watchUrl),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const ValueKey('camera-live-link'),
          controller: _linkController,
          enabled: !_busy,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.tournamentCameraLiveLinkLabel,
            helperText: hasValue ? null : l10n.tournamentCameraLiveLinkHint,
            helperMaxLines: 3,
            suffixIcon: TextButton(
              key: const ValueKey('camera-live-paste'),
              onPressed: _busy ? null : _paste,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(l10n.tournamentCameraLivePaste),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _liveError(l10n, error),
              key: const ValueKey('camera-live-error'),
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
        if (embed.isOk) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              key: const ValueKey('camera-live-chip'),
              avatar: Icon(
                embed.platform == LiveEmbedPlatform.youtube
                    ? Icons.smart_display_outlined
                    : Icons.facebook,
                size: 18,
              ),
              label: Text(
                embed.platform == LiveEmbedPlatform.youtube
                    ? 'YouTube'
                    : 'Facebook',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tournamentCameraLivePreviewTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.previewBuilder(context, embed),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tournamentCameraLivePreviewHelp,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final camera = widget.camera;
    return TournamentManageSheet(
      title: _isEdit
          ? l10n.tournamentCameraEditTitle
          : l10n.tournamentCameraAddTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('camera-editor-submit'),
          onPressed: _busy || !_canSubmit ? null : _submit,
          child: Text(
            _isEdit
                ? l10n.tournamentManagementSave
                : _liveSource
                ? l10n.tournamentCameraLiveSave
                : l10n.tournamentCameraAdd,
          ),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (camera != null) ...[
            Text(
              camera.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(camera.mode, style: TextStyle(color: colors.textSecondary)),
          ] else ...[
            _SourceSelector(
              live: _liveSource,
              enabled: !_busy,
              onChanged: (live) => setState(() => _liveSource = live),
            ),
            const SizedBox(height: 12),
            if (!_liveSource) ...[
              const CameraAddHelp(),
              const SizedBox(height: 8),
            ],
            TextField(
              key: const ValueKey('camera-editor-name'),
              controller: _nameController,
              enabled: !_busy,
              maxLength: _nameMaxLength,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.tournamentCameraNameLabel,
                errorText: _nameError,
              ),
            ),
            if (_liveSource) ...[
              const SizedBox(height: 12),
              _buildLiveLink(l10n),
            ],
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: const ValueKey('camera-editor-court'),
            // A court that is no longer listed (archived, no id) would trip the
            // dropdown's assert; show "no court" but keep _courtId so a plain save
            // stays a no-op.
            initialValue: widget.courts.any((court) => court.id == _courtId)
                ? _courtId
                : null,
            decoration: InputDecoration(
              labelText: l10n.tournamentCameraCourtLabel,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.tournamentCameraCourtNone),
              ),
              for (final court in widget.courts)
                DropdownMenuItem<String?>(
                  value: court.id,
                  child: Text(
                    court.name.isEmpty ? court.id : court.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(() => _courtId = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const ValueKey('camera-editor-error'),
              style: TextStyle(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chọn nguồn camera: điện thoại/OBS qua AQP (mặc định) hoặc link live YouTube/Facebook.
class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.live,
    required this.enabled,
    required this.onChanged,
  });

  final bool live;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, 48)),
      ),
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.videocam_outlined),
          label: Text(
            l10n.tournamentCameraSourcePush,
            key: const ValueKey('camera-source-push'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.live_tv_outlined),
          label: Text(
            l10n.tournamentCameraSourceLive,
            key: const ValueKey('camera-source-live'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      selected: {live},
      onSelectionChanged: enabled ? (value) => onChanged(value.first) : null,
    );
  }
}
