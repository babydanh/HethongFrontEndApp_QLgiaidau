import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/camera_patch.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_facebook_code.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Backend DTO bounds (`UpdateCameraDto`).
const _nameMinLength = 2;
const _nameMaxLength = 255;
const _urlMaxLength = 2000;

typedef CameraEditSubmit = Future<void> Function(CameraPatch patch);

/// Sheet to rename a camera and, only when the backend flags the URL as
/// editable, change its playback URL. [onSubmit] gets just the changed fields;
/// the sheet closes with `true` when it returns and shows the server message
/// verbatim when it throws.
class CameraEditSheet extends StatefulWidget {
  const CameraEditSheet({
    super.key,
    required this.camera,
    required this.onSubmit,
  });

  final TournamentCameraModel camera;
  final CameraEditSubmit onSubmit;

  /// Drag is off from the start: the sheet can turn busy right after opening
  /// and the route's drag flags are fixed at push time.
  static Future<bool?> show(
    BuildContext context, {
    required TournamentCameraModel camera,
    required CameraEditSubmit onSubmit,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => CameraEditSheet(camera: camera, onSubmit: onSubmit),
  );

  @override
  State<CameraEditSheet> createState() => _CameraEditSheetState();
}

class _CameraEditSheetState extends State<CameraEditSheet> {
  late final _nameController = TextEditingController(text: widget.camera.name);
  late final _urlController = TextEditingController(
    text: widget.camera.playbackUrl ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  CameraPatch get _patch => buildCameraPatch(
    widget.camera,
    name: _nameController.text,
    playbackUrl: _urlController.text,
  );

  bool get _nameInvalid {
    final length = _patch.name?.length ?? _nameMinLength;
    return length < _nameMinLength || length > _nameMaxLength;
  }

  bool get _urlInvalid {
    final url = _patch.playbackUrl;
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    return url.length > _urlMaxLength ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty;
  }

  bool get _canSubmit =>
      !_busy && !_patch.isEmpty && !_nameInvalid && !_urlInvalid;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    final patch = _patch;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(patch);
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
    return TournamentManageSheet(
      title: l10n.tournamentCameraEditAction,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('camera-edit-submit'),
          onPressed: _canSubmit ? _submit : null,
          child: Text(l10n.tournamentManagementSave),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('camera-edit-name'),
            controller: _nameController,
            enabled: !_busy,
            maxLength: _nameMaxLength,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.tournamentCameraNameLabel,
              errorText: _nameInvalid
                  ? l10n.tournamentCameraNameInvalid(
                      _nameMinLength,
                      _nameMaxLength,
                    )
                  : null,
            ),
          ),
          if (widget.camera.playbackUrlEditable) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('camera-edit-url'),
              controller: _urlController,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.tournamentCameraEditUrlLabel,
                errorText: _urlInvalid
                    ? l10n.tournamentCameraEditUrlInvalid
                    : null,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const ValueKey('camera-edit-error'),
              style: TextStyle(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
