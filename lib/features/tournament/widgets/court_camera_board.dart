import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_create_flow.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_card.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_popup.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bảng camera dùng chung của giải: một thẻ thu gọn cho mỗi sân (tên và trạng
/// thái), thêm một thẻ "Chưa gắn sân" khi có camera chưa gắn sân. Bấm thẻ mở
/// popup sân ([CourtCameraPopup]).
///
/// Thay cho `TournamentCameraPanel`. Đọc và ghi vẫn đi qua
/// [tournamentCamerasProvider] và các repository camera có sẵn.
class CourtCameraBoard extends ConsumerStatefulWidget {
  const CourtCameraBoard({
    super.key,
    required this.tournamentId,
    this.readOnly = false,
  });

  final String tournamentId;
  final bool readOnly;

  @override
  ConsumerState<CourtCameraBoard> createState() => _CourtCameraBoardState();
}

class _CourtCameraBoardState extends ConsumerState<CourtCameraBoard> {
  late Future<List<TournamentCourtRef>> _courtsFuture = _loadCourts();

  Future<List<TournamentCourtRef>> _loadCourts() async {
    final venues = await ref
        .read(tournamentManagementRepositoryProvider)
        .getVenues(widget.tournamentId);
    return _flattenCourts(venues);
  }

  /// Sân không có id thì route camera không gọi tới được, nên bị bỏ.
  List<TournamentCourtRef> _flattenCourts(List<Map<String, dynamic>> venues) {
    final courts = <TournamentCourtRef>[];
    for (final venue in venues) {
      final rawCourts = venue['courts'];
      if (rawCourts is! List) continue;
      final venueName = tournamentManagementRecordName(venue);
      for (final rawCourt in rawCourts) {
        if (rawCourt is! Map) continue;
        final id = (rawCourt['id'] ?? rawCourt['courtId'] ?? '').toString();
        if (id.isEmpty) continue;
        courts.add(
          TournamentCourtRef(
            id: id,
            name: (rawCourt['name'] ?? rawCourt['courtName'] ?? '').toString(),
            venueName: venueName,
          ),
        );
      }
    }
    return courts;
  }

  Future<void> _refresh() => ref
      .read(tournamentCamerasProvider(widget.tournamentId).notifier)
      .refresh();

  void _openPopup(String? courtId, String courtName) => showCourtCameraPopup(
    context,
    tournamentId: widget.tournamentId,
    courtId: courtId,
    courtName: courtName,
    readOnly: widget.readOnly,
  );

  Future<void> _openAdd(List<TournamentCourtRef> courts) => runCreateCameraFlow(
    context: context,
    ref: ref,
    tournamentId: widget.tournamentId,
    courts: courts,
    refresh: _refresh,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<TournamentCourtRef>>(
      future: _courtsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TournamentManagementError(
            error: snapshot.error,
            onRetry: () => setState(() => _courtsFuture = _loadCourts()),
          );
        }
        if (!snapshot.hasData) {
          return const BoneListLoading(itemCount: 3, leadingAvatar: false);
        }
        return _buildBody(l10n, snapshot.data!);
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<TournamentCourtRef> courts) {
    final camerasAsync = ref.watch(
      tournamentCamerasProvider(widget.tournamentId),
    );
    return camerasAsync.when(
      loading: () => const BoneListLoading(itemCount: 3, leadingAvatar: false),
      error: (error, _) =>
          TournamentManagementError(error: error, onRetry: _refresh),
      data: (cameras) {
        final hasUnattached = cameras.any((camera) => camera.courtId == null);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LavishGroupHeader(
              l10n.tournamentCameraListTitle(cameras.length),
              trailing: widget.readOnly
                  ? null
                  : IconButton(
                      key: const ValueKey('camera-panel-add'),
                      tooltip: l10n.tournamentCameraAdd,
                      onPressed: () => _openAdd(courts),
                      icon: const Icon(Icons.add_rounded),
                    ),
            ),
            for (final court in courts)
              CourtCameraCard(
                key: ValueKey('court-camera-card-${court.id}'),
                title: court.name.isEmpty ? court.id : court.name,
                camera: cameraForCourt(cameras, court.id),
                onTap: () => _openPopup(
                  court.id,
                  court.name.isEmpty ? court.id : court.name,
                ),
              ),
            if (hasUnattached)
              CourtCameraCard(
                key: const ValueKey('court-camera-card-none'),
                title: l10n.tournamentCameraNoCourt,
                camera: null,
                onTap: () => _openPopup(null, l10n.tournamentCameraNoCourt),
              ),
          ],
        );
      },
    );
  }
}
