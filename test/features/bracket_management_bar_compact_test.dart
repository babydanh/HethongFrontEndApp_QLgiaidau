import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_management_bar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// TC-BRACKET-MGMT-07: Create/Delete bracket buttons are compact (mini).
const _maxButtonHeight = 36.0;

Future<void> _pump(WidgetTester tester, {required bool hasBracket}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: BracketManagementBar(
            tournamentId: 't1',
            divisionId: 'd1',
            hasBracket: hasBracket,
            matchCount: 8,
            participantCount: 8,
            seedingType: 'RANDOM',
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('nút Xoá bracket gọn, cao tối đa 36dp', (tester) async {
    await _pump(tester, hasBracket: true);

    final size = tester.getSize(find.byKey(const Key('bracket-mgmt-delete')));
    expect(size.height, lessThanOrEqualTo(_maxButtonHeight));
  });

  testWidgets('nút Tạo bracket gọn, cao tối đa 36dp', (tester) async {
    await _pump(tester, hasBracket: false);

    final size = tester.getSize(find.byKey(const Key('bracket-mgmt-create')));
    expect(size.height, lessThanOrEqualTo(_maxButtonHeight));
  });
}
