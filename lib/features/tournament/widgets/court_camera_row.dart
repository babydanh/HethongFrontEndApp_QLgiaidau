import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Smallest comfortable touch target on both platforms (48dp Android, 44pt
/// iOS). The venue and camera cards are dense, so every control is pinned to it
/// explicitly instead of trusting the button's intrinsic height.
const double kMinTouchTarget = 48;

/// Playback-URL control for a single court.
///
/// Hosted in two places — the venues list and the organizer camera board — so
/// it owns the whole write path: read the court's camera, save a URL, archive
/// it. The visible state is always server state: after a successful write the
/// camera list is re-read, and a failure leaves the field as the organizer
/// typed it with the error surfaced through a snackbar.
class CourtCameraUrlRow extends ConsumerStatefulWidget {
  const CourtCameraUrlRow({
    super.key,
    required this.tournamentId,
    required this.courtId,
    required this.courtName,
    this.dense = false,
    this.readOnly = false,
  });

  final String tournamentId;
  final String courtId;
  final String courtName;

  /// Compact spacing for the venue card, where the court chip already carries
  /// the name.
  final bool dense;

  /// Read-only tournaments still show the camera state, but every write
  /// control is disabled instead of failing server-side on submit.
  final bool readOnly;

  @override
  ConsumerState<CourtCameraUrlRow> createState() => _CourtCameraUrlRowState();
}

class _CourtCameraUrlRowState extends ConsumerState<CourtCameraUrlRow> {
  /// Latest field content. The text field itself is uncontrolled and seeded
  /// from the server value, so nothing ever rewrites it mid-build.
  String _draft = '';
  bool _isSaving = false;
  bool _isClearing = false;

  bool get _isBusy => _isSaving || _isClearing || widget.readOnly;

  Future<void> _save() async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final url = _draft.trim();
    if (url.isEmpty) {
      _showMessage(l10n.tournamentManagementCameraUrlRequired);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(tournamentCamerasProvider(widget.tournamentId).notifier)
          .setCourtPlaybackUrl(courtId: widget.courtId, playbackUrl: url);
      if (!mounted) return;
      setState(() => _draft = url);
      _showMessage(l10n.tournamentManagementCameraUrlSaved);
    } on Object catch (error) {
      if (!mounted) return;
      // Nothing was persisted, so the field keeps the organizer's text and the
      // surface never pretends the URL was accepted.
      _showMessage(
        ErrorParser.parse(
          error,
          l10n.tournamentManagementCameraUrlSaveFailed,
          l10n,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clear() async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementCameraClearUrl,
      message: l10n.tournamentManagementCameraClearUrlConfirm(widget.courtName),
      confirmLabel: l10n.tournamentManagementCameraClearUrl,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isClearing = true);
    try {
      await ref
          .read(tournamentCamerasProvider(widget.tournamentId).notifier)
          .setCourtPlaybackUrl(courtId: widget.courtId, playbackUrl: '');
      if (!mounted) return;
      setState(() => _draft = '');
      _showMessage(l10n.tournamentManagementCameraUrlCleared);
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        ErrorParser.parse(
          error,
          l10n.tournamentManagementCameraUrlSaveFailed,
          l10n,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final camerasAsync = ref.watch(tournamentCamerasProvider(widget.tournamentId));
    final camera = cameraForCourt(
      camerasAsync.asData?.value ?? const <TournamentCameraModel>[],
      widget.courtId,
    );
    final storedUrl = camera?.playbackUrl;
    final isReady = camera?.hasPlaybackUrl ?? false;
    final canClear = isReady && !_isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + wording, never colour alone: the badge reads the same in
        // greyscale, in dark mode and to a screen reader.
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                isReady ? Icons.videocam_rounded : Icons.videocam_off_outlined,
                size: 18,
                color: isReady ? colors.success : colors.textMuted,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                isReady
                    ? '${l10n.tournamentManagementCameraReady} · ${camera!.name}'
                    : l10n.tournamentManagementCameraNotReady,
                style: TextStyle(
                  color: isReady ? colors.textPrimary : colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(
          height: widget.dense ? AppTheme.spacingSM : AppTheme.spacingMD,
        ),
        AppTextFormField(
          // Re-seeds the field whenever the server value changes, which is the
          // only writer besides the organizer's own typing.
          key: ValueKey<String>(
            'court-camera-url-${widget.courtId}-$storedUrl',
          ),
          label: l10n.tournamentManagementCameraUrl,
          hint: l10n.tournamentManagementCameraUrlHint,
          initialValue: storedUrl ?? '',
          enabled: !_isBusy,
          keyboardType: TextInputType.url,
          onChanged: (value) => _draft = value,
          onSubmitted: (_) => _save(),
        ),
        SizedBox(
          height: kMinTouchTarget,
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: _isBusy ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(l10n.tournamentManagementSave),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              TextButton.icon(
                onPressed: canClear ? _clear : null,
                icon: _isClearing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_off_rounded),
                label: Text(l10n.tournamentManagementCameraClearUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
