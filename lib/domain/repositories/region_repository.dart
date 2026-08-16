import 'package:app_quanly_giaidau/domain/entities/region.dart';

/// Đơn vị hành chính: tỉnh/thành → quận/huyện → phường/xã.
abstract class IRegionRepository {
  Future<List<Region>> getProvinces();
  Future<List<Region>> getDistricts(String provinceCode);
  Future<List<Region>> getWards(String districtCode);
}
