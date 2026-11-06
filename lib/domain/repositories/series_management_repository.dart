import 'package:app_quanly_giaidau/domain/entities/managed_series.dart';

/// Quản lý chuỗi giải của BTC, đối chiếu Backend `GET /series`,
/// `GET /series/:id`, `POST|PATCH|DELETE /organizer/series[/:id]`.
abstract class SeriesManagementRepository {
  /// Chuỗi do [organizerId] tạo (`GET /series?organizerId=`), mới nhất trước,
  /// tối đa 50 chuỗi (giới hạn trang của Backend, giống Web).
  Future<List<ManagedSeries>> listMine(String organizerId);

  /// `GET /series/:id`.
  Future<ManagedSeries> getById(String id);

  /// `POST /organizer/series`; chuỗi mới luôn ở trạng thái `DRAFT`.
  Future<ManagedSeries> create(SeriesInput input);

  /// `PATCH /organizer/series/:id`.
  Future<ManagedSeries> update(String id, SeriesInput input);

  /// `DELETE /organizer/series/:id` (xoá mềm).
  Future<void> delete(String id);
}
