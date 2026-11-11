import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_add_help.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
  });

  final String name;

  /// A new camera is always `PUSH` (AQP); an edited one keeps its own mode.
  final String mode;
  final String? courtId;
}

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
  late String? _courtId = widget.camera?.courtId;
  bool _busy = false;
  String? _nameError;
  String? _error;

  bool get _isEdit => widget.camera != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
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
          mode: widget.camera?.mode ?? 'PUSH',
          courtId: _courtId,
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
            const CameraAddHelp(),
            const SizedBox(height: 8),
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
