import 'package:app_quanly_giaidau/domain/entities/region.dart';

/// Đơn vị hành chính v2: tỉnh/thành → phường/xã.
abstract class IRegionRepository {
  Future<List<Region>> getProvinces();

  Future<List<Region>> getWardsByProvince(String provinceCode);

  /// Tìm kiếm kết hợp tỉnh/thành và phường/xã qua `GET /regions/search`.
  /// Ném [RegionSearchFailure] khi lỗi mạng để UI phân biệt rỗng/thất bại (retry).
  Future<List<Region>> searchRegions(String query, {int limit = 10});
}

/// Lỗi tìm kiếm khu vực hành chính (mạng/server), khác với "không có kết quả".
class RegionSearchFailure implements Exception {
  const RegionSearchFailure();
}
