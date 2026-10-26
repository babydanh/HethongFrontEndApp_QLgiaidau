import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Backend DTO bounds (`CreateCameraDto.name`, `playbackUrl`).
const _nameMinLength = 2;
const _nameMaxLength = 255;
const _urlMaxLength = 2000;

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

  /// `PUSH` or `PULL`.
  final String mode;
  final String? courtId;
  final String? playbackUrl;
}

typedef CameraEditorSubmit = Future<void> Function(CameraEditorValue value);

/// Sheet to add a camera (name, PUSH/PULL, https URL for PULL, optional court)
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
  });

  final List<TournamentCourtRef> courts;
  final CameraEditorSubmit onSubmit;
  final TournamentCameraModel? camera;

  /// Drag is off from the start: the sheet can turn busy right after opening
  /// and the route's drag flags are fixed at push time.
  static Future<bool?> show(
    BuildContext context, {
    required List<TournamentCourtRef> courts,
    required CameraEditorSubmit onSubmit,
    TournamentCameraModel? camera,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) =>
        CameraEditorSheet(courts: courts, onSubmit: onSubmit, camera: camera),
  );

  @override
  State<CameraEditorSheet> createState() => _CameraEditorSheetState();
}

class _CameraEditorSheetState extends State<CameraEditorSheet> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  late String? _courtId = widget.camera?.courtId;
  String _mode = 'PUSH';
  bool _busy = false;
  String? _nameError;
  String? _urlError;
  String? _error;

  bool get _isEdit => widget.camera != null;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        value.length <= _urlMaxLength;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final needsUrl = !_isEdit && _mode == 'PULL';
    final nameInvalid =
        !_isEdit &&
        (name.length < _nameMinLength || name.length > _nameMaxLength);
    final urlInvalid = needsUrl && !_isHttpsUrl(url);
    if (nameInvalid || urlInvalid) {
      setState(() {
        _nameError = nameInvalid
            ? l10n.tournamentCameraNameInvalid(_nameMinLength, _nameMaxLength)
            : null;
        _urlError = urlInvalid ? l10n.tournamentCameraUrlInvalid : null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _nameError = null;
      _urlError = null;
      _error = null;
    });
    try {
      await widget.onSubmit(
        CameraEditorValue(
          name: widget.camera?.name ?? name,
          mode: widget.camera?.mode ?? _mode,
          courtId: _courtId,
          playbackUrl: needsUrl ? url : null,
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
          onPressed: _busy ? null : _submit,
          child: Text(
            _isEdit ? l10n.tournamentManagementSave : l10n.tournamentCameraAdd,
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
            TextField(
              key: const ValueKey('camera-editor-name'),
              controller: _nameController,
              enabled: !_busy,
              maxLength: _nameMaxLength,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.tournamentCameraNameLabel,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tournamentCameraModeLabel,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              key: const ValueKey('camera-editor-mode'),
              style: SegmentedButton.styleFrom(minimumSize: const Size(0, 44)),
              segments: const [
                ButtonSegment(value: 'PUSH', label: Text('PUSH')),
                ButtonSegment(value: 'PULL', label: Text('PULL')),
              ],
              selected: {_mode},
              onSelectionChanged: _busy
                  ? null
                  : (value) => setState(() => _mode = value.first),
            ),
            const SizedBox(height: 6),
            Text(
              _mode == 'PUSH'
                  ? l10n.tournamentCameraModePushHint
                  : l10n.tournamentCameraModePullHint,
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            if (_mode == 'PULL') ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('camera-editor-url'),
                controller: _urlController,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.tournamentCameraUrlLabel,
                  hintText: 'https://',
                  errorText: _urlError,
                ),
              ),
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
