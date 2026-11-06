// Chuỗi giải do BTC quản lý, đối chiếu Backend `organizer/series`
// (`CreateSeriesDto` / `UpdateSeriesDto`) và Web `types/series.ts`.

/// Cấu hình luật tính điểm PSR (`rules` của chuỗi, `PsrPointConfigDto`).
class SeriesRules {
  const SeriesRules({
    required this.pointsByRank,
    required this.directEntryThreshold,
    required this.wildcardCount,
    required this.exclusionRule,
    required this.exclusionScope,
    required this.description,
  });

  /// Mặc định giống form tạo chuỗi trên Web.
  factory SeriesRules.defaults(String description) => SeriesRules(
    pointsByRank: const {1: 100, 2: 80, 3: 60, 5: 40, 9: 20, 17: 10},
    directEntryThreshold: 2,
    wildcardCount: 16,
    exclusionRule: true,
    exclusionScope: 'CATEGORY',
    description: description,
  );

  factory SeriesRules.fromJson(Object? json) {
    final map = json is Map ? json : const <String, dynamic>{};
    final points = <int, int>{};
    final rawPoints = map['pointsByRank'];
    if (rawPoints is Map) {
      rawPoints.forEach((rank, value) {
        final r = int.tryParse(rank.toString());
        final p = num.tryParse(value.toString())?.toInt();
        if (r != null && p != null) points[r] = p;
      });
    }
    return SeriesRules(
      pointsByRank: points,
      directEntryThreshold:
          num.tryParse('${map['directEntryThreshold']}')?.toInt() ?? 2,
      wildcardCount: num.tryParse('${map['wildcardCount']}')?.toInt() ?? 0,
      exclusionRule: map['exclusionRule'] == true,
      exclusionScope: map['exclusionScope'] == 'ALL' ? 'ALL' : 'CATEGORY',
      description: map['description']?.toString() ?? '',
    );
  }

  final Map<int, int> pointsByRank;
  final int directEntryThreshold;
  final int wildcardCount;
  final bool exclusionRule;

  /// `CATEGORY` hoặc `ALL`.
  final String exclusionScope;
  final String description;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pointsByRank': {
      for (final e in pointsByRank.entries) e.key.toString(): e.value,
    },
    'directEntryThreshold': directEntryThreshold,
    'wildcardCount': wildcardCount,
    'exclusionRule': exclusionRule,
    'exclusionScope': exclusionScope,
    'description': description,
  };
}

/// Một chuỗi giải như Backend trả về (bản ghi `tournament_series`).
class ManagedSeries {
  const ManagedSeries({
    required this.id,
    required this.slug,
    required this.name,
    required this.status,
    required this.visibility,
    required this.rules,
    this.description,
    this.bannerUrl,
    this.logoUrl,
    this.startDate,
    this.endDate,
    this.totalPrize,
  });

  factory ManagedSeries.fromJson(Map<String, dynamic> json) => ManagedSeries(
    id: json['id']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: _blankToNull(json['description']),
    bannerUrl: _blankToNull(json['bannerUrl']),
    logoUrl: _blankToNull(json['logoUrl']),
    status: json['status']?.toString() ?? 'DRAFT',
    visibility: json['visibility']?.toString() ?? 'PUBLIC',
    startDate: _date(json['startDate']),
    endDate: _date(json['endDate']),
    // `numeric` của Postgres về dạng chuỗi ("500000.00").
    totalPrize: num.tryParse('${json['totalPrize']}')?.toInt(),
    rules: SeriesRules.fromJson(json['rules']),
  );

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? bannerUrl;
  final String? logoUrl;

  /// `DRAFT`, `ACTIVE`, `COMPLETED`, `CANCELLED`.
  final String status;

  /// `PUBLIC` hoặc `PRIVATE`.
  final String visibility;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? totalPrize;
  final SeriesRules rules;
}

/// Dữ liệu form tạo/sửa chuỗi giải.
class SeriesInput {
  const SeriesInput({
    required this.name,
    required this.visibility,
    required this.rules,
    this.description = '',
    this.bannerUrl = '',
    this.logoUrl = '',
    this.startDate,
    this.endDate,
    this.totalPrize,
    this.status,
  });

  final String name;
  final String description;
  final String bannerUrl;
  final String logoUrl;
  final String visibility;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? totalPrize;
  final SeriesRules rules;

  /// Chỉ gửi khi sửa (chuỗi mới luôn là `DRAFT`).
  final String? status;

  /// Body `POST /organizer/series`: trường trống thì bỏ qua; `slug` bắt buộc
  /// phía Backend nên repository sinh ra rồi truyền vào.
  Map<String, dynamic> toCreateJson(String slug) => <String, dynamic>{
    'name': name,
    'slug': slug,
    if (description.isNotEmpty) 'description': description,
    if (bannerUrl.isNotEmpty) 'bannerUrl': bannerUrl,
    if (logoUrl.isNotEmpty) 'logoUrl': logoUrl,
    'visibility': visibility,
    if (startDate != null) 'startDate': startDate!.toUtc().toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
    if (totalPrize != null) 'totalPrize': totalPrize,
    'rules': rules.toJson(),
  };

  /// Body `PATCH /organizer/series/:id`: gửi đủ trường của form; trường bị xoá
  /// gửi `''`/`null` để Backend xoá giá trị cũ. Không gửi `slug`.
  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'name': name,
    'description': description,
    'bannerUrl': bannerUrl,
    'logoUrl': logoUrl,
    'visibility': visibility,
    'startDate': startDate?.toUtc().toIso8601String(),
    'endDate': endDate?.toUtc().toIso8601String(),
    'totalPrize': totalPrize,
    'rules': rules.toJson(),
    if (status != null) 'status': status,
  };
}

String? _blankToNull(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
