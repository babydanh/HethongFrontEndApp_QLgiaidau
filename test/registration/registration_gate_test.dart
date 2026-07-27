import 'package:app_quanly_giaidau/features/tournament/utils/registration_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);

  RegistrationGateResult evaluate({
    String status = 'REGISTRATION_OPEN',
    String? registrationMode = 'OPEN',
    DateTime? registrationStartDate,
    DateTime? registrationEndDate,
    bool identityCheckPending = false,
    bool alreadyRegistered = false,
    bool divisionSelectionRequired = false,
    bool divisionFull = false,
  }) {
    return evaluateRegistrationGate(
      status: status,
      registrationMode: registrationMode,
      registrationStartDate: registrationStartDate,
      registrationEndDate: registrationEndDate,
      now: now,
      identityCheckPending: identityCheckPending,
      alreadyRegistered: alreadyRegistered,
      divisionSelectionRequired: divisionSelectionRequired,
      divisionFull: divisionFull,
    );
  }

  test('chỉ REGISTRATION_OPEN và UPCOMING được tiếp tục', () {
    expect(evaluate().canContinue, isTrue);
    expect(evaluate(status: 'UPCOMING').canContinue, isTrue);
    expect(evaluate(status: 'DRAFT').code, RegistrationGateCode.notOpen);
    expect(evaluate(status: 'COMPLETED').code, RegistrationGateCode.notOpen);
  });

  test('chặn khi chưa đến ngày đăng ký hoặc đã hết hạn', () {
    expect(
      evaluate(registrationStartDate: now.add(const Duration(minutes: 1))).code,
      RegistrationGateCode.notStarted,
    );
    expect(
      evaluate(
        registrationEndDate: now.subtract(const Duration(minutes: 1)),
      ).code,
      RegistrationGateCode.expired,
    );
  });

  test('chờ xác minh identity trước khi kết luận chưa đăng ký', () {
    expect(
      evaluate(identityCheckPending: true).code,
      RegistrationGateCode.checking,
    );
  });

  test('chặn đăng ký trùng theo kết quả userId source-backed', () {
    expect(
      evaluate(alreadyRegistered: true).code,
      RegistrationGateCode.alreadyRegistered,
    );
  });

  test('yêu cầu chọn division trước khi route', () {
    expect(
      evaluate(divisionSelectionRequired: true).code,
      RegistrationGateCode.divisionRequired,
    );
  });

  test('division đầy vẫn cho đăng ký vào hàng chờ', () {
    final result = evaluate(divisionFull: true);
    expect(result.code, RegistrationGateCode.waitlist);
    expect(result.canContinue, isTrue);
    expect(result.label, 'Đăng ký hàng chờ');
  });

  test('giữ label theo registration mode', () {
    expect(
      evaluate(registrationMode: 'APPROVAL').label,
      'Gửi yêu cầu tham gia',
    );
    expect(
      evaluate(registrationMode: 'INVITE_ONLY').label,
      'Nhập mã mời để đăng ký',
    );
  });
}
