import 'package:app_quanly_giaidau/domain/entities/region.dart';

/// Đơn vị hành chính v2: tỉnh/thành → phường/xã.
abstract class IRegionRepository {
  Future<List<Region>> getProvinces();
  Future<List<Region>> getWardsByProvince(String provinceCode);
}
