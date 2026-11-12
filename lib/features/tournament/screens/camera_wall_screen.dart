import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_wall_tile.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/camera_preview_provider.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_match_livestreams_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chiều rộng từ đây trở lên là máy tính bảng: lưới được phép tới 4×4.
const _tabletBreakpoint = 600.0;
const _phoneMaxLayout = 2;
const _tabletMaxLayout = 4;

/// Mở tường camera toàn màn hình.
Future<void> showCameraWall(
  BuildContext context, {
  required String tournamentId,
  required String? divisionId,
  required Map<String, String> courtNames,
  required String Function(MatchModel match) matchLabelOf,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => CameraWallScreen(
      tournamentId: tournamentId,
      divisionId: divisionId,
      courtNames: courtNames,
      matchLabelOf: matchLabelOf,
    ),
  ),
);

/// Tường camera: lưới 1×1 / 2×2 (điện thoại) tới 4×4 (máy tính bảng), chia
/// trang, chạm đôi một ô để phóng 1×1. Chỉ các ô của trang hiện tại được dựng,
/// nên ô ngoài trang không giữ trình phát.
class CameraWallScreen extends ConsumerStatefulWidget {
  const CameraWallScreen({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    required this.courtNames,
    required this.matchLabelOf,
    this.playerBuilder = defaultCameraPlayer,
  });

  final String tournamentId;
  final String? divisionId;

  /// Tên sân theo `courtId` (camera chỉ mang id).
  final Map<String, String> courtNames;
  final String Function(MatchModel match) matchLabelOf;
  final CameraPlayerBuilder playerBuilder;

  @override
  ConsumerState<CameraWallScreen> createState() => _CameraWallScreenState();
}

class _CameraWallScreenState extends ConsumerState<CameraWallScreen> {
  int _layout = 2;
  int _page = 1;
  String? _zoomedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cameras =
        ref
            .watch(tournamentCamerasProvider(widget.tournamentId))
            .asData
            ?.value ??
        const <TournamentCameraModel>[];
    final matches =
        ref
            .watch(
              managedMatchesWithDivisionProvider((
                tournamentId: widget.tournamentId,
                divisionId: widget.divisionId,
              )),
            )
            .asData
            ?.value ??
        const <MatchModel>[];
    final streams =
        ref
            .watch(tournamentMatchLivestreamsProvider(widget.tournamentId))
            .asData
            ?.value ??
        const {};
    final previewOff = ref.watch(cameraPreviewOffProvider);
    final zoomed = cameras.where((c) => c.id == _zoomedId).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxLayout = constraints.maxWidth >= _tabletBreakpoint
                ? _tabletMaxLayout
                : _phoneMaxLayout;
            final layout = zoomed != null ? 1 : _layout.clamp(1, maxLayout);
            final wall = wallPage(
              zoomed != null ? [zoomed] : cameras,
              layout,
              zoomed != null ? 1 : _page,
            );
            return Column(
              children: [
                _TopBar(
                  layout: layout,
                  maxLayout: maxLayout,
                  zoomed: zoomed != null,
                  onLayout: (value) => setState(() {
                    _layout = value;
                    _zoomedId = null;
                    _page = 1;
                  }),
                ),
                Expanded(
                  child: cameras.isEmpty
                      ? Center(
                          child: Text(
                            l10n.camWallEmpty,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      : _Grid(
                          layout: layout,
                          cameras: wall.items,
                          tileBuilder: (camera) => CameraWallTile(
                            key: ValueKey('wall-tile-${camera.id}'),
                            onDoubleTap: () => setState(
                              () => _zoomedId = _zoomedId == camera.id
                                  ? null
                                  : camera.id,
                            ),
                            camera: camera,
                            courtName: widget.courtNames[camera.courtId],
                            matchLine: cameraMatchLabel(
                              camera: camera,
                              matches: matches,
                              livestreams: streams,
                              labelOf: widget.matchLabelOf,
                              noMatchLabel: l10n.camWallNoMatch,
                            ),
                            previewOn: !previewOff.contains(camera.id),
                            onPreviewChanged: (_) => ref
                                .read(cameraPreviewOffProvider.notifier)
                                .toggle(camera.id),
                            onRetry: () => ref
                                .read(
                                  tournamentCamerasProvider(
                                    widget.tournamentId,
                                  ).notifier,
                                )
                                .refresh(),
                            playerBuilder: widget.playerBuilder,
                          ),
                        ),
                ),
                if (zoomed == null && wall.pageCount > 1)
                  _Pager(
                    page: wall.page,
                    pageCount: wall.pageCount,
                    onPage: (value) => setState(() => _page = value),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.layout,
    required this.maxLayout,
    required this.zoomed,
    required this.onLayout,
  });

  final int layout;
  final int maxLayout;
  final bool zoomed;
  final ValueChanged<int> onLayout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.camWallClose,
          constraints: const BoxConstraints.tightFor(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
          ),
          color: Colors.white,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        Expanded(
          child: Text(
            zoomed ? l10n.camWallZoomHint : l10n.camWallTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (var size = 1; size <= maxLayout; size++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              label: Text('$size×$size'),
              tooltip: l10n.camWallLayout(size),
              selected: !zoomed && layout == size,
              onSelected: (_) => onLayout(size),
            ),
          ),
      ],
    );
  }
}

/// Lưới n×n chiếm vừa khít vùng còn lại (không cuộn), ô thiếu để trống.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.layout,
    required this.cameras,
    required this.tileBuilder,
  });

  final int layout;
  final List<TournamentCameraModel> cameras;
  final Widget Function(TournamentCameraModel camera) tileBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          for (var row = 0; row < layout; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < layout; col++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: row * layout + col < cameras.length
                            ? tileBuilder(cameras[row * layout + col])
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.pageCount,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.camWallPrev,
          color: Colors.white,
          onPressed: page > 1 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          l10n.camWallPage(page, pageCount),
          style: const TextStyle(color: Colors.white),
        ),
        IconButton(
          tooltip: l10n.camWallNext,
          color: Colors.white,
          onPressed: page < pageCount ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
