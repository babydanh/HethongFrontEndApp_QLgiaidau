import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/province_selection_screen.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

void main() {
  Widget buildTestWidget({
    String? selectedProvinceCode,
    void Function(Map<String, dynamic>?)? onPopResult,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result =
                      await Navigator.of(context).push<Map<String, dynamic>>(
                    MaterialPageRoute(
                      builder: (_) => ProvinceSelectionScreen(
                        selectedProvinceCode: selectedProvinceCode,
                      ),
                    ),
                  );
                  onPopResult?.call(result);
                },
                child: const Text('Open Picker'),
              ),
            ),
          );
        },
      ),
    );
  }

  group('ProvinceSelectionScreen Tests', () {
    testWidgets('renders search field with "Chọn tỉnh" and "Huỷ" button',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn tỉnh'), findsOneWidget);
      expect(find.text('Huỷ'), findsOneWidget);
      expect(find.text('Hà Nội'), findsOneWidget);
      expect(find.text('Hà Giang'), findsOneWidget);
    });

    testWidgets('tapping "Huỷ" returns {"action": "clear"}', (tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(buildTestWidget(
        onPopResult: (res) => result = res,
      ));
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['action'], 'clear');
    });

    testWidgets('filtering works with non-diacritic search', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'da nang');
      await tester.pumpAndSettle();

      expect(find.text('Đà Nẵng'), findsOneWidget);
      expect(find.text('Hà Nội'), findsNothing);
    });

    testWidgets('tapping a province returns {"action": "select", "code": code}',
        (tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(buildTestWidget(
        onPopResult: (res) => result = res,
      ));
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hà Nội'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['action'], 'select');
      expect(result!['code'], '01');
    });
  });
}
