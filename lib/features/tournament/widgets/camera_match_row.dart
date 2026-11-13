import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_recording_player_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_stream_toggle.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/tournament_match_livestreams_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const _startValue = 'start';
const _stopValue = 'stop';
const _recordingsValue = 'recordings';
const _courtPrefix = 'court:';
const _cameraPrefix = 'camera:';
const _liveTone = Color(0xFFE11D48);

/// Một trận ở tab Camera: một dòng chính (tên hai bên + chip mã trận, sân,
/// giờ), nút ▶ xem live và menu ⋯ gom Bắt đầu / Dừng / Bản ghi / chuyển sân /
/// chọn camera. Không có viền hộp: các dòng ngăn nhau bằng đường kẻ mảnh do
/// nơi chứa vẽ.
class CameraMatchRow extends ConsumerStatefulWidget {
  const CameraMatchRow({
    super.key,
    required this.tournamentId,
    required this.match,
    required this.label,
    required this.hasCamera,
    required this.readOnly,
    this.isBusy = false,
    this.isSelected = false,
    this.showCourtChip = true,
    this.draggable = false,
    this.courts = const [],
    this.cameras = const [],
    this.onSelected,
    this.onAssign,
    this.onPickCamera,
  });

  final String tournamentId;
  final MatchModel match;
  final String label;

  /// Trận có camera: gán riêng hoặc sân của trận có URL camera.
  final bool hasCamera;
  final bool readOnly;
  final bool isBusy;
  final bool isSelected;
  final bool showCourtChip;

  /// Kéo giữ để thả vào thẻ sân.
  final bool draggable;
  final List<TournamentCourtRef> courts;
  final List<TournamentCameraModel> cameras;
  final VoidCallback? onSelected;
  final ValueChanged<TournamentCourtRef>? onAssign;
  final ValueChanged<TournamentCameraModel>? onPickCamera;

  @override
  ConsumerState<CameraMatchRow> createState() => _CameraMatchRowState();
}

class _CameraMatchRowState extends ConsumerState<CameraMatchRow> {
  bool _toggling = false;

  Future<void> _toggle(bool isLive) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    await toggleMatchStream(
      context,
      ref,
      tournamentId: widget.tournamentId,
      matchId: widget.match.id,
      isLive: isLive,
    );
    if (mounted) setState(() => _toggling = false);
  }

  void _onMenu(String value, bool isLive) {
    if (value == _startValue || value == _stopValue) {
      _toggle(isLive);
    } else if (value == _recordingsValue) {
      showMatchRecordingPlayerSheet(context, matchId: widget.match.id);
    } else if (value.startsWith(_courtPrefix)) {
      final id = value.substring(_courtPrefix.length);
      final court = widget.courts.where((c) => c.id == id).firstOrNull;
      if (court != null) widget.onAssign?.call(court);
    } else if (value.startsWith(_cameraPrefix)) {
      final id = value.substring(_cameraPrefix.length);
      final camera = widget.cameras.where((c) => c.id == id).firstOrNull;
      if (camera != null) widget.onPickCamera?.call(camera);
    }
  }

  List<PopupMenuEntry<String>> _menuItems(
    AppLocalizations l10n,
    bool isLive,
    bool hasCamera,
  ) {
    final items = <PopupMenuEntry<String>>[];
    if (!widget.readOnly) {
      items.add(
        isLive
            ? PopupMenuItem(
                value: _stopValue,
                child: Text(l10n.tournamentManagementCameraStreamStop),
              )
            : PopupMenuItem(
                value: _startValue,
                enabled: hasCamera,
                child: Text(
                  hasCamera
                      ? l10n.tournamentManagementCameraStreamStart
                      : '${l10n.tournamentManagementCameraStreamStart} · '
                            '${l10n.tournamentManagementCameraStreamNeedsCamera}',
                ),
              ),
      );
    }
    items.add(
      PopupMenuItem(
        value: _recordingsValue,
        child: Text(l10n.camMatchRecordings),
      ),
    );
    if (!widget.readOnly && widget.onAssign != null) {
      items.add(const PopupMenuDivider());
      for (final court in widget.courts) {
        items.add(
          PopupMenuItem(
            value: '$_courtPrefix${court.id}',
            child: Text(
              l10n.camMatchMoveCourt(
                court.name.isEmpty ? court.id : court.name,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    if (!widget.readOnly && widget.onPickCamera != null) {
      items.add(const PopupMenuDivider());
      for (final camera in widget.cameras) {
        items.add(
          PopupMenuItem(
            value: '$_cameraPrefix${camera.id}',
            child: Text(
              l10n.camMatchUseCamera(
                camera.name.isEmpty ? camera.id : camera.name,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final summary = ref.watch(
      tournamentMatchLivestreamsProvider(
        widget.tournamentId,
      ).select((rows) => rows.asData?.value[widget.match.id]),
    );
    final isLive = summary?.isLive ?? false;
    final hasCamera = widget.hasCamera || (summary?.hasCamera ?? false);
    final match = widget.match;
    final courtName = match.courtName?.trim() ?? '';
    final time = match.scheduledTime;
    final code = match.matchCode?.trim() ?? '';
    final chips = <String>[
      if (code.isNotEmpty) code,
      if (widget.showCourtChip)
        courtName.isEmpty
            ? l10n.tournamentManagementCameraUnassigned
            : courtName,
      if (time != null) DateFormat('HH:mm').format(time.toLocal()),
    ];

    final row = Container(
      constraints: const BoxConstraints(minHeight: kMinTouchTarget),
      padding: const EdgeInsets.only(left: AppTheme.spacingSM),
      color: widget.isSelected
          ? AppTheme.primary.withValues(alpha: 0.09)
          : null,
      child: Row(
        children: [
          if (widget.draggable && !widget.readOnly) ...[
            const ExcludeSemantics(child: Icon(Icons.drag_indicator_rounded)),
            const SizedBox(width: AppTheme.spacingXS),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [for (final chip in chips) _Chip(text: chip)],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.isBusy || _toggling)
            const SizedBox.square(
              dimension: kMinTouchTarget,
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            Semantics(
              label: l10n.tournamentManagementCameraStreamWatchLiveAria(
                widget.label,
              ),
              excludeSemantics: true,
              child: IconButton(
                tooltip: l10n.tournamentManagementCameraStreamWatchLive,
                constraints: const BoxConstraints.tightFor(
                  width: kMinTouchTarget,
                  height: kMinTouchTarget,
                ),
                onPressed: () => context.push('/live/${match.id}'),
                color: isLive ? _liveTone : null,
                icon: const Icon(Icons.play_circle_outline_rounded),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.camMatchMore,
              onSelected: (value) => _onMenu(value, isLive),
              itemBuilder: (_) => _menuItems(l10n, isLive, hasCamera),
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ],
      ),
    );

    final tappable = widget.onSelected == null
        ? row
        : InkWell(onTap: widget.onSelected, child: row);
    if (!widget.draggable || widget.readOnly) return tappable;

    return LongPressDraggable<CourtMatchDragData>(
      data: CourtMatchDragData(matchId: match.id, matchLabel: widget.label),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 240, height: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.primary, width: 1.5),
              boxShadow: const [
                BoxShadow(blurRadius: 12, color: Colors.black26),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.38, child: row),
      child: tappable,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.textMuted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.textSecondary, fontSize: 11),
      ),
    );
  }
}
