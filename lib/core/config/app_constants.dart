class AppConstants {
  // ─── App Info ───
  static const String appName = 'SportO';
  static const String appTagline = 'Chơi cùng nhau';
  static const String appVersion = '1.0.0';
  static const String appDomain = 'https://sporto.asia';

  // ─── Brand Assets ───
  static const String logoIconSvg = 'assets/images/sporto_v1.svg';
  static const String logoFullSvg = 'assets/images/sporto_v1_with_text.svg';
  static const String logoFullPng = 'assets/images/sporto_v1_with_text.png';
  static const String appIconPng = 'assets/logos/icon.png';
  static const String defaultFallbackImage = 'assets/images/sporto_v1_with_text.png';
  static const String remoteLogoFullSvg = 'https://sporto.asia/sporto_v1_with_text.svg';
  static const String remoteLogoIconSvg = 'https://sporto.asia/sporto_v1.svg';

  // ─── Sports ───
  static const String sportPickleball = 'pickleball';
  static const String sportBadminton = 'badminton';
  static const String sportTennis = 'tennis';
  static const String sportTableTennis = 'table_tennis';
  static const String sportFootball = 'football';

  static const Map<String, String> sportNames = {
    sportFootball: 'Football',
    sportPickleball: 'Pickleball',
    sportBadminton: 'Cầu lông',
    sportTennis: 'Tennis',
    sportTableTennis: 'Bóng bàn',
  };

  static const Map<String, String> sportIcons = {
    sportFootball: '⚽',
    sportPickleball: 'assets/icons/racket.png',
    sportBadminton: '🏸',
    sportTennis: '🎾',
    sportTableTennis: '🏓',
  };

  // ─── Tag BQT (P2C.4/P2C.5) ───
  static const int memberTagMax = 3;
  static const int memberTagMaxLength = 15;
  static const String memberTagMenu = 'Gán tag';
  static const String memberTagAssignTitle = 'Gán tag cho thành viên';
  static const String memberTagAssignDesc =
      'Tag hiển thị cạnh tên trong danh sách thành viên (tối đa 3 tag).';
  static const String memberTagAddHint = 'Nhập tag mới...';
  static const String memberTagAdd = 'Thêm';
  static const String memberTagSave = 'Lưu tag';
  static const String memberTagSaving = 'Đang lưu...';
  static const String memberTagMaxReached = 'Đã đạt tối đa 3 tag';
  static const String memberTagEmpty =
      'Chưa có tag nào. Thêm tag bên dưới để bắt đầu.';
  static const String memberTagTooLong = 'Mỗi tag tối đa 15 ký tự.';
  static const String memberTagInvalid =
      'Tag chỉ được chứa chữ cái, số, khoảng trắng, gạch dưới (_) và gạch ngang (-).';
  static const String memberTagDuplicate = 'Tag này đã tồn tại.';
  static const String memberTagRemove = 'Xoá tag';
  static const String memberTagSaveError =
      'Không thể lưu tag. Vui lòng thử lại.';
  static const List<String> memberTagSuggestions = [
    'Cây hài',
    'Kèo thơm',
    'MVP tuần',
    'Đang lên form',
    'Kèo khó',
  ];
  static String memberTagCounter(int used, int max) =>
      'Đã dùng $used/$max tag.';

  // ─── Formats ───
  static const String formatSingles = 'singles';
  static const String formatDoubles = 'doubles';
  static const String formatMixedDoubles = 'mixed_doubles';

  static const Map<String, String> formatNames = {
    formatSingles: 'Đánh đơn',
    formatDoubles: 'Đánh đôi',
    formatMixedDoubles: 'Đôi nam nữ',
  };

  // ─── Categories (Hạng mục) ───
  static const String categoryMenSingles = 'men_singles';
  static const String categoryWomenSingles = 'women_singles';
  static const String categoryMenDoubles = 'men_doubles';
  static const String categoryWomenDoubles = 'women_doubles';
  static const String categoryMixedDoubles = 'mixed_doubles';

  static const Map<String, String> categoryNames = {
    categoryMenSingles: 'Đơn nam',
    categoryWomenSingles: 'Đơn nữ',
    categoryMenDoubles: 'Đôi nam',
    categoryWomenDoubles: 'Đôi nữ',
    categoryMixedDoubles: 'Đôi nam nữ',
  };

  // ─── Bracket Types ───
  static const String bracketSingleElimination = 'single_elimination';
  static const String bracketDoubleElimination = 'double_elimination';
  static const String bracketRoundRobin = 'round_robin';
  static const String bracketGroupStageKnockout = 'group_stage_knockout';

  static const Map<String, String> bracketTypeNames = {
    bracketSingleElimination: 'Đấu loại trực tiếp',
    bracketDoubleElimination: 'Đấu loại kép',
    bracketRoundRobin: 'Vòng tròn',
    bracketGroupStageKnockout: 'Vòng bảng + Loại trực tiếp',
  };

  static const Map<String, String> bracketTypeDescriptions = {
    bracketSingleElimination: 'Loại ngay khi thua, tối ưu thời gian',
    bracketDoubleElimination: 'Có nhánh thắng - nhánh thua, tăng cơ hội',
    bracketRoundRobin: 'Tất cả gặp nhau, tích điểm, công bằng cao',
    bracketGroupStageKnockout:
        'Chia bảng đấu vòng tròn, chọn đội đi tiếp đánh loại trực tiếp',
  };

  static const Map<String, String> bracketTypeDetails = {
    bracketSingleElimination:
        'Thể thức đấu loại trực tiếp (Knockout). Bất kỳ đội/người chơi nào thua một trận sẽ bị loại ngay khỏi giải đấu. Ưu điểm: Diễn ra nhanh chóng, kịch tính cao. Nhược điểm: Ít cơ hội sửa sai.',
    bracketDoubleElimination:
        'Thể thức đấu loại kép. Các đội thua trận đầu sẽ rơi xuống "Nhánh thua" thay vì bị loại ngay. Chỉ bị loại hoàn toàn khi thua trận thứ 2. Đội vô địch Nhánh thắng sẽ gặp đội vô địch Nhánh thua ở trận Chung kết tổng.',
    bracketRoundRobin:
        'Thể thức đấu vòng tròn (League). Tất cả các đội đều sẽ thi đấu với nhau. Thứ hạng được quyết định bằng điểm số (Thắng 3đ, Hòa 1đ, Thua 0đ). Nếu điểm bằng nhau sẽ xét hiệu số. Công bằng nhất nhưng tốn nhiều thời gian nhất.',
    bracketGroupStageKnockout:
        'Kết hợp vòng bảng Round Robin và vòng loại trực tiếp (Knockout). Các đội được chia vào các bảng thi đấu vòng tròn tính điểm, sau đó các đội đứng đầu mỗi bảng sẽ đi tiếp vào vòng loại trực tiếp để tranh chức vô địch.',
  };

  // ─── Tournament Status ───
  static const String statusDraft = 'draft';
  static const String statusUpcoming = 'upcoming';
  static const String statusRegistration = 'registration';
  static const String statusRegistrationClosed = 'registration_closed';
  static const String statusDrawing = 'drawing';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  static const Map<String, String> statusNames = {
    statusDraft: 'Nháp',
    statusUpcoming: 'Sắp diễn ra',
    statusRegistration: 'Đang mở đăng ký',
    statusRegistrationClosed: 'Đã đóng đăng ký',
    statusDrawing: 'Bốc thăm',
    statusInProgress: 'Đang thi đấu',
    statusCompleted: 'Đã kết thúc',
    statusCancelled: 'Đã hủy',
  };

  // ─── Match Status ───
  static const String matchScheduled = 'scheduled';
  static const String matchLive = 'live';
  static const String matchCompleted = 'completed';
  static const String matchWalkover = 'walkover';

  // ─── User Roles ───
  static const String roleAdmin = 'admin';
  static const String roleReferee = 'referee';
  static const String roleViewer = 'viewer';

  static const Map<String, String> roleNames = {
    roleAdmin: 'Ban tổ chức',
    roleReferee: 'Trọng tài',
    roleViewer: 'Người xem',
  };

  // ─── Token Prefixes ───
  static const String tokenPrefixAdmin = 'ADM';
  static const String tokenPrefixReferee = 'REF';
  static const String tokenPrefixViewer = 'VWR';

  // ─── Max Teams ───
  static const List<int> maxTeamOptions = [4, 8, 16, 32, 64, 128];

  // ─── Scoring ───
  static const int pointsForWin = 3;
  static const int pointsForDraw = 1;
  static const int pointsForLoss = 0;

  // ─── Collection Names ───
  static const String collectionTournaments = 'tournaments';
  static const String collectionTeams = 'teams';
  static const String collectionMatches = 'matches';
  static const String collectionStandings = 'standings';
  static const String collectionTokens = 'tokens';

  // ─── Shared UI Strings ───
  static const String textPenaltyRules = 'Luật thẻ phạt';
  static const String textRecordPenalty = 'Ghi nhận Thẻ phạt';
  static const String textOffendingTeam = '1. Đội vi phạm:';
  static const String textPenaltyType = '2. Loại thẻ:';
  static const String textReasonRequired = '3. Lý do (Bắt buộc):';
  static const String textCancel = 'Hủy';
  static const String textConfirm = 'Xác nhận';
  static const String textClose = 'Đóng';
}
