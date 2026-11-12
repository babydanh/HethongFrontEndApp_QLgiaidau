import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_player.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_match_livestreams_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _defaultLayout = 2;

/// Tường camera toàn màn hình của BTC: lưới 1×1/2×2/3×3/4×4, chia trang.
///
/// Công tắc "Xem thử" chỉ gắn/gỡ trình phát trên máy này; không gọi Backend.
class CameraWallScreen extends ConsumerStatefulWidget {
  const CameraWallScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<CameraWallScreen> createState() => _CameraWallScreenState();
}

class _CameraWallScreenState extends ConsumerState<CameraWallScreen> {
  int _layout = _defaultLayout;
  int _page = 1;
  final Set<String> _previewOff = {};

  /// Đổi lưới nhưng giữ camera đầu trang hiện tại trong tầm nhìn.
  void _setLayout(List<TournamentCameraModel> cameras, int layout) {
    final current = cameraWallPage(cameras, _layout, _page);
    final anchor = current.items.firstOrNull;
    setState(() {
      _layout = layout;
      _page = anchor == null ? 1 : cameraWallPageOf(cameras, anchor.id, layout);
    });
  }

  void _zoomTo(List<TournamentCameraModel> cameras, String cameraId) {
    setState(() {
      _layout = 1;
      _page = cameraWallPageOf(cameras, cameraId, 1);
    });
  }

  void _setPreview(String cameraId, bool on) {
    setState(() {
      if (on) {
        _previewOff.remove(cameraId);
      } else {
        _previewOff.add(cameraId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final camerasAsync = ref.watch(
      tournamentCamerasProvider(widget.tournamentId),
    );
    final streams =
        ref
            .watch(tournamentMatchLivestreamsProvider(widget.tournamentId))
            .asData
            ?.value ??
        const <String, MatchLivestreamSummary>{};
    final matches =
        ref
            .watch(
              managedMatchesWithDivisionProvider((
                tournamentId: widget.tournamentId,
                divisionId: null,
              )),
            )
            .asData
            ?.value ??
        const <MatchModel>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tournamentManagementCameraWallTitle)),
      body: SafeArea(
        child: camerasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => TournamentManagementError(
            error: error,
            onRetry: () => ref
                .read(tournamentCamerasProvider(widget.tournamentId).notifier)
                .refresh(),
          ),
          data: (cameras) => _buildWall(l10n, cameras, streams, matches),
        ),
      ),
    );
  }

  Widget _buildWall(
    AppLocalizations l10n,
    List<TournamentCameraModel> cameras,
    Map<String, MatchLivestreamSummary> streams,
    List<MatchModel> matches,
  ) {
    final page = cameraWallPage(cameras, _layout, _page);
    return Column(
      children: [
        _Toolbar(
          layout: _layout,
          page: page.page,
          pageCount: page.pageCount,
          onLayout: (layout) => _setLayout(cameras, layout),
          onPage: (next) => setState(() => _page = next),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              children: [
                for (var row = 0; row < _layout; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < _layout; col++)
                          Expanded(
                            child: _slot(
                              page.items,
                              row * _layout + col,
                              cameras,
                              streams,
                              matches,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _slot(
    List<TournamentCameraModel> items,
    int index,
    List<TournamentCameraModel> cameras,
    Map<String, MatchLivestreamSummary> streams,
    List<MatchModel> matches,
  ) {
    if (index >= items.length) return const SizedBox.shrink();
    final camera = items[index];
    return Padding(
      padding: const EdgeInsets.all(2),
      child: _CameraTile(
        key: ValueKey('camera-wall-tile-${camera.id}'),
        camera: camera,
        label: cameraWallMatchLabel(camera, streams, matches),
        previewOn: !_previewOff.contains(camera.id),
        onPreview: (on) => _setPreview(camera.id, on),
        onZoom: () => _zoomTo(cameras, camera.id),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.layout,
    required this.page,
    required this.pageCount,
    required this.onLayout,
    required this.onPage,
  });

  final int layout;
  final int page;
  final int pageCount;
  final ValueChanged<int> onLayout;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final n in cameraWallLayouts)
                ButtonSegment<int>(
                  value: n,
                  label: Text(l10n.tournamentManagementCameraWallLayout(n)),
                ),
            ],
            selected: {layout},
            onSelectionChanged: (selection) => onLayout(selection.first),
          ),
          if (pageCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.tournamentManagementCameraWallPrevPage,
                  onPressed: page > 1 ? () => onPage(page - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(l10n.tournamentManagementCameraWallPage(page, pageCount)),
                IconButton(
                  tooltip: l10n.tournamentManagementCameraWallNextPage,
                  onPressed: page < pageCount ? () => onPage(page + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CameraTile extends StatelessWidget {
  const _CameraTile({
    super.key,
    required this.camera,
    required this.label,
    required this.previewOn,
    required this.onPreview,
    required this.onZoom,
  });

  final TournamentCameraModel camera;
  final CameraWallMatchLabel? label;
  final bool previewOn;
  final ValueChanged<bool> onPreview;
  final VoidCallback onZoom;

  /// Chạm đúp chỉ gắn lên tên, hình và dòng trận: gắn lên cả ô thì nó tranh
  /// cử chỉ với công tắc và nuốt lần chạm đầu.
  Widget _zoomable(Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onDoubleTap: onZoom,
    child: child,
  );

  String _matchText(AppLocalizations l10n) {
    final match = label;
    if (match == null) return l10n.tournamentManagementCameraWallNoMatch;
    String side(String name) => name.isEmpty ? l10n.matchNotDetermined : name;
    return '#${match.code} ${side(match.team1)} – ${side(match.team2)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    const smallText = TextStyle(fontSize: 11);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Column(
          children: [
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: _zoomable(
                      Text(
                        camera.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: smallText.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: l10n.tournamentManagementCameraWallPreview,
                    child: FittedBox(
                      child: Switch(value: previewOn, onChanged: onPreview),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _zoomable(
                shouldMountCameraPlayer(camera, previewOn)
                    ? _ScaledPlayer(camera: camera)
                    : _Placeholder(status: camera.status),
              ),
            ),
            _zoomable(
              SizedBox(
                height: 22,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _matchText(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: smallText.copyWith(color: colors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: context.colors.bgSurface,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CameraStatusBadge(status: status),
              const SizedBox(height: 4),
              Text(
                l10n.tournamentManagementCameraWallNoPicture,
                style: TextStyle(fontSize: 11, color: context.colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cỡ tối thiểu mà `LiveVideoPlayer` dàn được thanh điều khiển không tràn.
const double _playerMinWidth = 280;
const double _playerMinHeight = 240;

/// `LiveVideoPlayer` được thiết kế cho khung lớn; ô lưới 3×3/4×4 trên điện
/// thoại quá nhỏ nên dựng ở cỡ ảo đủ rộng rồi thu nhỏ vừa ô, cùng tỉ lệ ô.
class _ScaledPlayer extends StatelessWidget {
  const _ScaledPlayer({required this.camera});

  final TournamentCameraModel camera;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = [
          1.0,
          _playerMinWidth / width,
          _playerMinHeight / height,
        ].reduce((a, b) => a > b ? a : b);
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: width * scale,
              height: height * scale,
              child: IgnorePointer(
                child: LiveVideoPlayer(
                  url: camera.playbackUrl!,
                  label: camera.name,
                  showStreamStats: true,
                  fill: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
