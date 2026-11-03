import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_contact_form.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> latest;

  Future<void> pumpForm(
    WidgetTester tester,
    Map<String, dynamic> initial, {
    String? profileName = 'danh',
  }) async {
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
              profileName: profileName,
              onChanged: (value) => latest = value,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  bool modeIsProfile(WidgetTester tester) => tester
      .widget<Switch>(
        find.descendant(
          of: find.byKey(const ValueKey('info-contact-mode')),
          matching: find.byType(Switch),
        ),
      )
      .value;

  testWidgets(
    'TC-CONTACT-01: profile source shows the account card, phone and email, no organizer name',
    (tester) async {
      await pumpForm(tester, {
        'phone': '0900000001',
        'email': 'a@example.test',
      });

      expect(modeIsProfile(tester), isTrue);
      expect(
        find.byKey(const ValueKey('info-contact-profile')),
        findsOneWidget,
      );
      expect(find.text('danh'), findsOneWidget);
      expect(find.byKey(const ValueKey('info-contact-phone')), findsOneWidget);
      expect(find.byKey(const ValueKey('info-contact-email')), findsOneWidget);
      expect(find.byKey(const ValueKey('info-contact-name')), findsNothing);
      // The old two-button source selector is gone.
      expect(find.byType(SegmentedButton<String>), findsNothing);
    },
  );

  testWidgets(
    'TC-CONTACT-02: turning the switch off asks for the organizer name and drops the email',
    (tester) async {
      await pumpForm(tester, {
        'phone': '0900000001',
        'email': 'a@example.test',
      });
      await tapKey(tester, 'info-contact-mode');

      expect(modeIsProfile(tester), isFalse);
      expect(find.byKey(const ValueKey('info-contact-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('info-contact-email')), findsNothing);
      expect(find.byKey(const ValueKey('info-contact-profile')), findsNothing);
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
    'TC-CONTACT-03: adding a social link with the tick stores it under its type and lists it',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001'});

      await tester.enterText(
        find.byKey(const ValueKey('info-contact-link-value')),
        'https://facebook.com/example.test',
      );
      await tapKey(tester, 'info-contact-link-add');

      expect(latest['facebook'], 'https://facebook.com/example.test');
      expect(
        find.byKey(const ValueKey('info-contact-link-remove-facebook')),
        findsOneWidget,
      );
      expect(find.text('https://facebook.com/example.test'), findsOneWidget);
    },
  );

  testWidgets('TC-CONTACT-04: a listed link can be removed', (tester) async {
    await pumpForm(tester, {'zalo': '0900000009', 'phone': '0900000001'});
    await tapKey(tester, 'info-contact-link-remove-zalo');

    expect(latest.containsKey('zalo'), isFalse);
    expect(latest['phone'], '0900000001');
    expect(
      find.byKey(const ValueKey('info-contact-link-remove-zalo')),
      findsNothing,
    );
  });

  testWidgets(
    'TC-CONTACT-05: an empty value, a missing custom label and phone/email labels are refused',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001'});

      await tapKey(tester, 'info-contact-link-add');
      expect(find.text('Vui lòng nhập giá trị liên hệ.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('info-contact-link-value')),
        'value',
      );
      await tapKey(tester, 'info-contact-link-type-custom');
      await tapKey(tester, 'info-contact-link-add');
      expect(find.text('Vui lòng nhập nhãn liên hệ.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('info-contact-link-label')),
        'Email',
      );
      await tapKey(tester, 'info-contact-link-add');
      expect(
        find.text('Không được trùng với điện thoại hoặc email.'),
        findsOneWidget,
      );
      expect(latest, {'phone': '0900000001'});
    },
  );

  testWidgets(
    'TC-CONTACT-06: picking another type changes the key the link is stored under',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001'});

      await tapKey(tester, 'info-contact-link-type-zalo');
      await tester.enterText(
        find.byKey(const ValueKey('info-contact-link-value')),
        '0900000009',
      );
      await tapKey(tester, 'info-contact-link-add');

      expect(latest['zalo'], '0900000009');
      expect(latest.containsKey('facebook'), isFalse);
    },
  );

  testWidgets(
    'TC-CONTACT-07: no "no links" notice and no separate add button',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001'});

      expect(find.text('Chưa có liên kết nào.'), findsNothing);
      expect(find.text('Thêm'), findsNothing);
    },
  );

  testWidgets(
    'TC-CONTACT-09: the popup keeps the hidden flag untouched and has no founder switch',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001', 'hidden': false});

      expect(
        find.byKey(const ValueKey('info-contact-show-founder')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('info-contact-phone')),
        '0900000002',
      );
      await tester.pump();
      expect(latest['hidden'], false);
      expect(latest['phone'], '0900000002');
    },
  );

  testWidgets('TC-CONTACT-10: manual source has no account card', (
    tester,
  ) async {
    await pumpForm(tester, {
      'displayMode': 'MANUAL',
      'organizerName': 'Ban to chuc A',
      'phone': '0900000001',
    });

    expect(modeIsProfile(tester), isFalse);
    expect(find.byKey(const ValueKey('info-contact-profile')), findsNothing);
  });

  testWidgets(
    'TC-CONTACT-11: a single-word account name shows its initial; a hidden founder says so',
    (tester) async {
      await pumpForm(tester, {'phone': '0900000001'}, profileName: 'odi695');

      expect(find.text('odi695'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
      expect(find.text('Đang ẩn với người xem'), findsOneWidget);
    },
  );
}
