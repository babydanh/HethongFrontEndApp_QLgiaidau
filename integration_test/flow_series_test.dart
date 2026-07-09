import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-SERIES-001: Xem danh sach chuoi giai dau
  testWidgets('TC-FLUTTER-SERIES-001: Xem danh sach chuoi giai dau',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to series screen
      final seriesNav = find.text('Chuỗi giải');
      if (seriesNav.evaluate().isNotEmpty) {
        await tester.tap(seriesNav.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Alternative navigation
      final seriesTab = find.text('Series');
      if (seriesTab.evaluate().isNotEmpty) {
        await tester.tap(seriesTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'series_list');
    } catch (e) {
      await screenshotOnFailure(tester, 'SERIES-001');
      rethrow;
    }
  });
}
