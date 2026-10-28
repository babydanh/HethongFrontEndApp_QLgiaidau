import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

// Fake contact data only.
const _phone = '0900000000';
const _email = 'contact@example.test';

Tournament _tournament(Map<String, dynamic>? contactInfo) =>
    Tournament.fromJson({
      'contactInfo': ?contactInfo,
      'name': 'Contact block regression',
      'sport': 'pickleball',
      'category': {'name': 'Pickleball', 'slug': 'pickleball'},
      'format': 'SINGLES',
      'bracketType': 'single_elimination',
      'status': 'in_progress',
      'creator': {'id': 'creator-1', 'fullName': 'Organizer Name'},
      'maxTeams': 16,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'registrationStartDate': '2026-09-01T00:00:00.000Z',
      'registrationEndDate': '2026-09-29T00:00:00.000Z',
      'startDate': '2026-10-01T00:00:00.000Z',
    }, 'tournament-contact');

Future<void> _pump(
  WidgetTester tester,
  Map<String, dynamic>? contactInfo, {
  bool manager = false,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(_UnauthenticatedNotifier.new)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: OverviewTab(
            tournament: _tournament(contactInfo),
            teamCount: 0,
            resolveImageUrl: (_) => '',
            onToggleFounderHidden: manager ? (_) async {} : null,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('MANUAL shows name and phone, no email, for viewers', (
    tester,
  ) async {
    await _pump(tester, {
      'displayMode': 'MANUAL',
      'organizerName': 'Ban to chuc A',
      'phone': _phone,
      'email': _email,
    });

    expect(find.text('LIÊN HỆ'), findsOneWidget);
    expect(find.textContaining('Ban to chuc A'), findsOneWidget);
    expect(find.textContaining(_phone), findsOneWidget);
    expect(find.textContaining(_email), findsNothing);
  });

  testWidgets('PROFILE made public shows phone and email', (tester) async {
    await _pump(tester, {
      'displayMode': 'PROFILE',
      'hidden': false,
      'phone': _phone,
      'email': _email,
    });

    expect(find.text('LIÊN HỆ'), findsOneWidget);
    expect(find.textContaining(_phone), findsOneWidget);
    expect(find.textContaining(_email), findsOneWidget);
  });

  testWidgets('PROFILE hidden: viewers get no block and no number at all', (
    tester,
  ) async {
    await _pump(tester, {
      'displayMode': 'PROFILE',
      'hidden': true,
      'phone': _phone,
      'email': _email,
    });

    expect(find.text('LIÊN HỆ'), findsNothing);
    expect(find.textContaining(_phone), findsNothing);
    expect(find.textContaining(_email), findsNothing);
  });

  testWidgets('a manager sees hidden contact with the hint line', (
    tester,
  ) async {
    await _pump(tester, {
      'displayMode': 'PROFILE',
      'hidden': true,
      'phone': _phone,
    }, manager: true);

    expect(find.text('LIÊN HỆ'), findsOneWidget);
    expect(find.textContaining(_phone), findsOneWidget);
    expect(find.text('Đang ẩn với người xem'), findsOneWidget);
  });

  testWidgets('null contactInfo draws no block and does not throw', (
    tester,
  ) async {
    await _pump(tester, null);
    expect(find.text('LIÊN HỆ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long email wraps at 320 dp without overflow', (tester) async {
    await _pump(tester, {
      'hidden': false,
      'phone': _phone,
      'email': 'a.very.long.contact.address.for.overflow.checks@example.test',
    }, width: 320);

    expect(find.text('LIÊN HỆ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing founder block and eye toggle are untouched', (
    tester,
  ) async {
    await _pump(tester, {'hidden': false, 'phone': _phone}, manager: true);

    expect(find.text('BAN TỔ CHỨC GIẢI ĐẤU'), findsOneWidget);
    expect(find.text('Organizer Name'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tournament-founder-eye')),
      findsOneWidget,
    );
  });
}
