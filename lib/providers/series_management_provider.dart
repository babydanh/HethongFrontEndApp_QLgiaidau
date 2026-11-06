import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_series_management_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/managed_series.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_management_repository.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod 3 retries a failed provider while keeping it in loading state;
/// these screens show an error with a Retry button instead.
Duration? _noRetry(int retryCount, Object error) => null;

final seriesManagementRepositoryProvider = Provider<SeriesManagementRepository>(
  (ref) => ApiSeriesManagementRepository(ref.watch(dioClientProvider)),
);

/// Chuỗi giải do chính người dùng đăng nhập tạo. Khách (id rỗng) trả danh sách
/// rỗng: Backend bỏ qua `organizerId` rỗng và sẽ trả chuỗi của mọi người.
final mySeriesProvider = FutureProvider.autoDispose<List<ManagedSeries>>((
  ref,
) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile.id.isEmpty) return const [];
  return ref.watch(seriesManagementRepositoryProvider).listMine(profile.id);
}, retry: _noRetry);

/// Một chuỗi theo id, dùng cho màn sửa.
final managedSeriesProvider = FutureProvider.autoDispose
    .family<ManagedSeries, String>(
      (ref, id) => ref.watch(seriesManagementRepositoryProvider).getById(id),
      retry: _noRetry,
    );
