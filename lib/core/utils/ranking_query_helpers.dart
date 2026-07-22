// Helper xây dựng query parameters cho API ranking.
//
// Chỉ gửi params có giá trị, omit những param rỗng/null/"all".
// Backend API: GET /rankings nhận page, limit, categoryId, matchType,
// genderRestriction, scope, provinceCode.
// Backend KHÔNG hỗ trợ search param (search chỉ dùng local).
library;

/// Xây dựng map query parameters sạch cho GET /rankings.
///
/// Omit:
/// - `categoryId` nếu là null, empty, hoặc 'all'
/// - `matchType` nếu null hoặc empty
/// - `genderRestriction` nếu null hoặc empty
/// - `provinceCode` nếu null hoặc empty
///
/// Luôn gửi: scope=PUBLIC, page (mặc định 1), limit (mặc định 100).
Map<String, dynamic> buildRankingQueryParams({
  String? categoryId,
  String? matchType,
  String? genderRestriction,
  String? provinceCode,
  int page = 1,
  int limit = 100,
}) {
  final params = <String, dynamic>{
    'scope': 'PUBLIC',
    'page': page,
    'limit': limit,
  };

  final cleanCategoryId = categoryId?.trim();
  final cleanMatchType = matchType?.trim();
  final cleanGenderRestriction = genderRestriction?.trim();
  final cleanProvinceCode = provinceCode?.trim();

  if (cleanCategoryId != null &&
      cleanCategoryId.isNotEmpty &&
      cleanCategoryId != 'all') {
    params['categoryId'] = cleanCategoryId;
  }
  if (cleanMatchType != null && cleanMatchType.isNotEmpty) {
    params['matchType'] = cleanMatchType;
  }
  if (cleanGenderRestriction != null && cleanGenderRestriction.isNotEmpty) {
    params['genderRestriction'] = cleanGenderRestriction;
  }
  if (cleanProvinceCode != null && cleanProvinceCode.isNotEmpty) {
    params['provinceCode'] = cleanProvinceCode;
  }

  return params;
}
