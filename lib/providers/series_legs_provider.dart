import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_series_legs_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_legs_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final seriesLegsRepositoryProvider = Provider<SeriesLegsRepository>(
  (ref) => ApiSeriesLegsRepository(ref.watch(dioClientProvider)),
);

/// Một vòng kèm các giải đã gắn, để màn quản lý vẽ một lần.
class SeriesLegWithEvents {
  const SeriesLegWithEvents(this.leg, this.events);

  final SeriesLegRecord leg;
  final List<SeriesLegEvent> events;
}

/// Tải danh sách vòng rồi giải của từng vòng (song song). Lỗi ở bất kỳ bước
/// nào làm cả danh sách lỗi để người dùng bấm Thử lại, không hiện dữ liệu thiếu.
final seriesLegsOverviewProvider = FutureProvider.autoDispose
    .family<List<SeriesLegWithEvents>, String>((ref, seriesId) async {
      final repository = ref.watch(seriesLegsRepositoryProvider);
      final legs = await repository.getLegs(seriesId);
      return Future.wait(
        legs.map((leg) async {
          final events = await repository.getLegEvents(seriesId, leg.id);
          return SeriesLegWithEvents(leg, events);
        }),
      );
    });
