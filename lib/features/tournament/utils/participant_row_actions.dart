/// Lý do gửi kèm khi loại VĐV khỏi giải từ danh sách VĐV (đúng chuỗi Web
/// `handleKickParticipant` trong useManageState.ts).
const kickDefaultReason = 'Loại khỏi giải theo điều lệ';

/// Web `RegistrationTab.renderActionsCell`: chỉ loại được hồ sơ đã duyệt
/// (`COMPLETE`) hoặc đang chờ đồng đội, khi giải chưa kết thúc/huỷ.
bool canKickParticipant(String teamStatus, String tournamentStatus) {
  final status = teamStatus.toUpperCase();
  return (status == 'COMPLETE' || status == 'PENDING_PARTNER') &&
      !const {
        'COMPLETED',
        'CANCELLED',
      }.contains(tournamentStatus.toUpperCase());
}

/// Web `LivestreamTab.handleCreateCamera`: camera PUSH vừa tạo thì mở luôn
/// popup QR (popup tự tạo stream key); PULL không có key.
bool shouldOpenStreamKeyAfterCreate(String cameraMode) =>
    cameraMode.toUpperCase() == 'PUSH';
