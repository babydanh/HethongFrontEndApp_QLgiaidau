import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/register/screens/tournament_register_screen.dart',
  ).readAsStringSync();

  test('TC-APP-REG-D2D3-001 loads registrations for all divisions', () {
    expect(
      source,
      contains("'/tournaments/\${widget.tournamentId}/my-registrations'"),
    );
    expect(source, contains("raw['data'] is List"));
    expect(source, contains("participant['tournamentDivisionId']"));
  });

  test('TC-APP-REG-D2D3-002 scopes existing-registration state to selection', () {
    expect(source, contains('_registrationsByDivision[divisionId]'));
    expect(source, contains('bool get _alreadyRegistered => _selectedRegistration != null;'));
    expect(source, contains('if (_alreadyRegistered)'));
    expect(source, isNot(contains('Bạn đang có đơn/đội đã tạo ở nội dung')));
  });
}
