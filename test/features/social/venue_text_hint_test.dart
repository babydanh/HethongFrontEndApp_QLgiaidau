import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/venue_text_hint.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  // TC-VENUE-TEXT-APP-03
  group('VenueTextHintBar', () {
    testWidgets('shows nothing when the fields look fine', (tester) async {
      await tester.pumpWidget(
        _app(
          VenueTextHintBar(
            name: 'Sân Mộc',
            address: '123 Nguyễn Văn A, P.5',
            onApply: (_, _) => fail('must not apply'),
          ),
        ),
      );
      expect(find.byType(Text), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('shows the message, no icon, and applies the replacement', (
      tester,
    ) async {
      String? appliedName;
      String? appliedAddress;
      await tester.pumpWidget(
        _app(
          VenueTextHintBar(
            name: 'Nhà thi đấu Phú Thọ, Q.11',
            address: '',
            onApply: (n, a) {
              appliedName = n;
              appliedAddress = a;
            },
          ),
        ),
      );

      expect(find.textContaining('cả địa chỉ'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Áp dụng'));
      expect(appliedName, 'Nhà thi đấu Phú Thọ');
      expect(appliedAddress, 'Q.11');
    });

    testWidgets('uses the amber warning colour', (tester) async {
      await tester.pumpWidget(
        _app(VenueTextHintBar(name: '', address: 'Sân 79', onApply: (_, _) {})),
      );
      final text = tester.widget<Text>(find.textContaining('tên sân'));
      expect(text.style?.color, const Color(0xFFF59E0B));
    });

    testWidgets('identical text shows the message without an apply button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          VenueTextHintBar(
            name: 'Sân Mộc',
            address: 'sân mộc',
            onApply: (_, _) => fail('must not apply'),
          ),
        ),
      );
      expect(find.textContaining('giống hệt'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('updates when the fields change', (tester) async {
      Widget bar(String address) => _app(
        VenueTextHintBar(name: 'Sân Mộc', address: address, onApply: (_, _) {}),
      );
      await tester.pumpWidget(bar('Sân Mộc'));
      expect(find.byType(TextButton), findsNothing);
      await tester.pumpWidget(bar('Sân Mộc, 12 Lê Lợi'));
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
