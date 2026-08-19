enum ReportTargetType { user, tournament, match, community }

enum ReportCategory {
  cheating,
  ruleViolation,
  abusiveBehavior,
  fakeInformation,
  paymentFraud,
  unsafeOrganization,
  other,
}

enum ReportStatus {
  submitted,
  triaged,
  underReview,
  escalated,
  resolved,
  rejected,
}

ReportTargetType reportTargetTypeFromApi(String? value) => switch (value) {
  'USER' => ReportTargetType.user,
  'TOURNAMENT' => ReportTargetType.tournament,
  'MATCH' => ReportTargetType.match,
  'COMMUNITY' => ReportTargetType.community,
  _ => ReportTargetType.user,
};

ReportCategory reportCategoryFromApi(String? value) => switch (value) {
  'CHEATING' => ReportCategory.cheating,
  'RULE_VIOLATION' => ReportCategory.ruleViolation,
  'ABUSIVE_BEHAVIOR' => ReportCategory.abusiveBehavior,
  'FAKE_INFORMATION' => ReportCategory.fakeInformation,
  'PAYMENT_FRAUD' => ReportCategory.paymentFraud,
  'UNSAFE_ORGANIZATION' => ReportCategory.unsafeOrganization,
  _ => ReportCategory.other,
};

ReportStatus reportStatusFromApi(String? value) => switch (value) {
  'TRIAGED' => ReportStatus.triaged,
  'UNDER_REVIEW' => ReportStatus.underReview,
  'ESCALATED' => ReportStatus.escalated,
  'RESOLVED' => ReportStatus.resolved,
  'REJECTED' => ReportStatus.rejected,
  _ => ReportStatus.submitted,
};

class ReportTargetSummary {
  final String id;
  final String name;
  final String? status;

  const ReportTargetSummary({
    required this.id,
    required this.name,
    this.status,
  });

  factory ReportTargetSummary.fromJson(Map<String, dynamic> json) {
    return ReportTargetSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }
}

class ViolationReport {
  final String id;
  final ReportTargetType targetType;
  final String targetId;
  final ReportCategory category;
  final String reason;
  final List<String> evidenceUrls;
  final ReportStatus status;
  final String? resolutionNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReportTargetSummary? target;

  const ViolationReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.category,
    required this.reason,
    required this.evidenceUrls,
    required this.status,
    this.resolutionNote,
    this.createdAt,
    this.updatedAt,
    this.target,
  });

  factory ViolationReport.fromJson(Map<String, dynamic> json) {
    final evidence = json['evidenceUrls'];
    final target = json['target'];
    return ViolationReport(
      id: json['id']?.toString() ?? '',
      targetType: reportTargetTypeFromApi(json['targetType']?.toString()),
      targetId: json['targetId']?.toString() ?? '',
      category: reportCategoryFromApi(json['category']?.toString()),
      reason: json['reason']?.toString() ?? '',
      evidenceUrls: evidence is List
          ? evidence.map((item) => item.toString()).toList(growable: false)
          : const [],
      status: reportStatusFromApi(json['status']?.toString()),
      resolutionNote: json['resolutionNote']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      target: target is Map
          ? ReportTargetSummary.fromJson(Map<String, dynamic>.from(target))
          : null,
    );
  }
}

class ViolationReportPage {
  final List<ViolationReport> items;
  final String? nextCursor;
  final int totalPages;

  const ViolationReportPage({
    required this.items,
    required this.nextCursor,
    required this.totalPages,
  });
}
