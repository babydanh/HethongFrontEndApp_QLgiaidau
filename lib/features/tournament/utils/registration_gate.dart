enum RegistrationGateCode {
  open,
  checking,
  notOpen,
  notStarted,
  expired,
  divisionRequired,
  alreadyRegistered,
  waitlist,
}

class RegistrationGateResult {
  const RegistrationGateResult({
    required this.code,
    required this.label,
    this.message,
  });

  final RegistrationGateCode code;
  final String label;
  final String? message;

  bool get canContinue =>
      code == RegistrationGateCode.open ||
      code == RegistrationGateCode.waitlist;
}

RegistrationGateResult evaluateRegistrationGate({
  required String status,
  required String? registrationMode,
  required DateTime? registrationStartDate,
  required DateTime? registrationEndDate,
  required DateTime now,
  required bool identityCheckPending,
  required bool alreadyRegistered,
  required bool divisionSelectionRequired,
  required bool divisionFull,
}) {
  final normalizedStatus = status.trim().toUpperCase();
  if (normalizedStatus != 'REGISTRATION_OPEN' &&
      normalizedStatus != 'UPCOMING') {
    return const RegistrationGateResult(
      code: RegistrationGateCode.notOpen,
      label: 'Đăng ký chưa mở',
      message: 'Giải đấu chưa mở đăng ký.',
    );
  }

  if (registrationStartDate != null && now.isBefore(registrationStartDate)) {
    return const RegistrationGateResult(
      code: RegistrationGateCode.notStarted,
      label: 'Đăng ký chưa mở',
      message: 'Chưa đến thời gian đăng ký.',
    );
  }

  if (registrationEndDate != null && now.isAfter(registrationEndDate)) {
    return const RegistrationGateResult(
      code: RegistrationGateCode.expired,
      label: 'Đã hết hạn đăng ký',
      message: 'Đã hết hạn đăng ký.',
    );
  }

  if (identityCheckPending) {
    return const RegistrationGateResult(
      code: RegistrationGateCode.checking,
      label: 'Đang kiểm tra đăng ký',
      message: 'Đang kiểm tra trạng thái đăng ký. Vui lòng chờ một chút.',
    );
  }

  if (alreadyRegistered) {
    return const RegistrationGateResult(
      code: RegistrationGateCode.alreadyRegistered,
      label: 'Đã đăng ký',
      message: 'Bạn đã đăng ký giải này.',
    );
  }

  if (divisionSelectionRequired) {
    return const RegistrationGateResult(
      code: RegistrationGateCode.divisionRequired,
      label: 'Chọn nội dung thi đấu',
      message: 'Vui lòng chọn nội dung thi đấu trước khi đăng ký.',
    );
  }

  if (divisionFull) {
    return const RegistrationGateResult(
      code: RegistrationGateCode.waitlist,
      label: 'Đăng ký hàng chờ',
      message: 'Nội dung đã đủ đội. Đăng ký mới sẽ vào hàng chờ.',
    );
  }

  final mode = registrationMode?.trim().toUpperCase();
  if (mode == 'APPROVAL') {
    return const RegistrationGateResult(
      code: RegistrationGateCode.open,
      label: 'Gửi yêu cầu tham gia',
    );
  }
  if (mode == 'INVITE_ONLY') {
    return const RegistrationGateResult(
      code: RegistrationGateCode.open,
      label: 'Nhập mã mời để đăng ký',
    );
  }
  return const RegistrationGateResult(
    code: RegistrationGateCode.open,
    label: 'Đăng ký',
  );
}
