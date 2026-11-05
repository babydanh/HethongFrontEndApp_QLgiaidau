// Đổi VĐV giữa các cặp / gỡ VĐV khỏi cặp (nội dung đôi), đối chiếu Web
// `PairDragProvider` và Backend `POST /tournaments/:id/pairing/move`,
// `POST /tournaments/:id/pairing/:participantId/remove-member`.

/// Khoá thành viên Backend dùng để phát hiện dữ liệu đã đổi (409):
/// `account:<userId>` hoặc `guest:<tên>|<email viết thường>`
/// (`memberKey` của Backend, `expectedKey` của Web).
String pairMemberKey({
  String? userId,
  required String fullName,
  String? email,
}) {
  if (userId != null && userId.isNotEmpty) return 'account:$userId';
  return 'guest:${fullName.trim()}|${(email ?? '').trim().toLowerCase()}';
}

/// Ô đích của một lần chuyển: một ô của một hồ sơ, hoặc khay chờ ghép.
class PairMoveTarget {
  const PairMoveTarget.slot(String this.participantId, int this.slot)
    : tray = false;
  const PairMoveTarget.tray() : participantId = null, slot = null, tray = true;

  final String? participantId;
  final int? slot;
  final bool tray;

  Map<String, dynamic> toJson() => tray
      ? const <String, dynamic>{'tray': true}
      : <String, dynamic>{'participantId': participantId, 'slot': slot};
}

/// Body của `POST /tournaments/:id/pairing/move`.
class PairMoveRequest {
  const PairMoveRequest({
    required this.divisionId,
    required this.sourceParticipantId,
    required this.sourceSlot,
    required this.target,
    required this.expectedSource,
    this.expectedTarget,
  });

  final String divisionId;
  final String sourceParticipantId;
  final int sourceSlot;
  final PairMoveTarget target;

  /// Khoá VĐV đang ở ô nguồn.
  final String expectedSource;

  /// Khoá VĐV đang ở ô đích; null khi ô đích trống hoặc đích là khay.
  final String? expectedTarget;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'divisionId': divisionId,
    'source': <String, dynamic>{
      'participantId': sourceParticipantId,
      'slot': sourceSlot,
    },
    'target': target.toJson(),
    'expected': <String, dynamic>{
      'source': expectedSource,
      'target': expectedTarget,
    },
  };
}

/// Kết quả `remove-member`: VĐV còn lại quay về hàng chờ ghép, VĐV bị gỡ bị loại.
class PairRemoveResult {
  const PairRemoveResult({
    required this.remainingParticipantId,
    required this.removedParticipantId,
  });

  final String remainingParticipantId;
  final String removedParticipantId;
}

abstract interface class PairMoveRepository {
  /// Trả id các hồ sơ bị đổi. Lệch khoá thì Backend trả 409 (DioException).
  Future<List<String>> movePairMember(
    String tournamentId,
    PairMoveRequest request,
  );

  Future<PairRemoveResult> removePairMember(
    String tournamentId, {
    required String participantId,
    required int slot,
    required String expectedKey,
  });
}
