import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_contact_form.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> latest;

  Future<void> pumpForm(
    WidgetTester tester,
    Map<String, dynamic> initial,
  ) async {
    latest = {...initial};
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentContactForm(
              initial: initial,
              onChanged: (value) => latest = value,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'TC-CONTACT-01: profile source shows phone and email, no organizer name',
    (tester) async {
      await pumpForm(tester, {
        'phone': '0900000001',
        'email': 'a@example.test',
      });

      expect(find.byKey(const ValueKey('info-contact-phone')), findsOneWidget);
      expect(find.byKey(const ValueKey('info-contact-email')), findsOneWidget);
      expect(find.byKey(const ValueKey('info-contact-name')), findsNothing);
    },
  );

  testWidgets(
    'TC-CONTACT-02: switching to manual asks for the organizer name and drops the email',
    (tester) async {
      await pumpForm(tester, {
        'phone': '0900000001',
        'email': 'a@example.test',
      });
      await tapText(tester, 'Nhập thông tin BTC');

      expect(find.byKey(const ValueKey('info-contact-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('info-contact-email')), findsNothing);
      expect(latest['displayMode'], 'MANUAL');
      expect(latest.containsKey('email'), isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('info-contact-name')),
        'Ban to chuc A',
      );
      await tester.pump();
      expect(latest['organizerName'], 'Ban to chuc A');
    },
  );

  testWidgets(
    'TC-CONTACT-03: adding a social link stores it under its type and lists it',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001'});

      await tester.enterText(
        find.byKey(const ValueKey('info-contact-link-value')),
        'https://facebook.com/example.test',
      );
      await tapText(tester, 'Thêm');

      expect(latest['facebook'], 'https://facebook.com/example.test');
      expect(
        find.byKey(const ValueKey('info-contact-link-remove-facebook')),
        findsOneWidget,
      );
    },
  );

  testWidgets('TC-CONTACT-04: a listed link can be removed', (tester) async {
    await pumpForm(tester, {'zalo': '0900000009', 'phone': '0900000001'});
    final remove = find.byKey(const ValueKey('info-contact-link-remove-zalo'));
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();

    expect(latest.containsKey('zalo'), isFalse);
    expect(latest['phone'], '0900000001');
    expect(remove, findsNothing);
  });

  testWidgets(
    'TC-CONTACT-05: an empty value, a missing custom label and phone/email labels are refused',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001'});

      await tapText(tester, 'Thêm');
      expect(find.text('Vui lòng nhập giá trị liên hệ.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('info-contact-link-value')),
        'value',
      );
      await tapText(tester, 'Khác (tự nhập nhãn)');
      await tapText(tester, 'Thêm');
      expect(find.text('Vui lòng nhập nhãn liên hệ.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('info-contact-link-label')),
        'Email',
      );
      await tapText(tester, 'Thêm');
      expect(
        find.text('Không được trùng với điện thoại hoặc email.'),
        findsOneWidget,
      );
      expect(latest, {'phone': '0900000001'});
    },
  );
}
