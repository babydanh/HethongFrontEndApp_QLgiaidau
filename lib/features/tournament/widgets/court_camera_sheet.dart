import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the camera sheet of one court. The playback URL is only ever shown
/// inside this sheet and stays masked until the organizer taps "Show".
Future<void> showCourtCameraSheet(
  BuildContext context, {
  required String tournamentId,
  required String courtId,
  required String courtName,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => CourtCameraSheet(
    tournamentId: tournamentId,
    courtId: courtId,
    courtName: courtName,
  ),
);

/// Edit sheet for the playback URL of a single court: masked field, save, and
/// detach (archives the camera). Messages are fixed localized strings; server
/// text is never surfaced because it may echo the URL.
class CourtCameraSheet extends ConsumerStatefulWidget {
  const CourtCameraSheet({
    super.key,
    required this.tournamentId,
    required this.courtId,
    required this.courtName,
  });

  final String tournamentId;
  final String courtId;
  final String courtName;

  @override
  ConsumerState<CourtCameraSheet> createState() => _CourtCameraSheetState();
}

class _CourtCameraSheetState extends ConsumerState<CourtCameraSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: _storedUrl ?? '',
  );
  bool _reveal = false;
  bool _busy = false;
  String? _error;

  String? get _storedUrl => cameraForCourt(
    ref.read(tournamentCamerasProvider(widget.tournamentId)).asData?.value ??
        const [],
    widget.courtId,
  )?.playbackUrl;

  bool get _hasCamera => (_storedUrl ?? '').isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _write(String url, String successMessage) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentCamerasProvider(widget.tournamentId).notifier)
          .setCourtPlaybackUrl(courtId: widget.courtId, playbackUrl: url);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.tournamentManagementCameraUrlSaveFailed;
      });
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = l10n.tournamentManagementCameraUrlRequired);
      return;
    }
    await _write(url, l10n.tournamentManagementCameraUrlSaved);
  }

  Future<void> _detach() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementCameraDetach,
      message: l10n.tournamentManagementCameraClearUrlConfirm(widget.courtName),
      confirmLabel: l10n.tournamentManagementCameraDetach,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _write('', l10n.tournamentManagementCameraUrlCleared);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tournamentManagementCourtCameraSheetTitle(widget.courtName),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('court-camera-sheet-url'),
            controller: _controller,
            enabled: !_busy,
            obscureText: !_reveal,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.tournamentManagementCameraUrl,
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(
                onPressed: () => setState(() => _reveal = !_reveal),
                child: Text(
                  _reveal
                      ? l10n.tournamentManagementCameraHideUrl
                      : l10n.tournamentManagementCameraShowUrl,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || !_hasCamera ? null : _detach,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: colors.error,
                  ),
                  child: Text(l10n.tournamentManagementCameraDetach),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.tournamentManagementSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
