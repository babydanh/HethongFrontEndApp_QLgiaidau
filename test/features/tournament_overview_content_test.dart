import 'dart:async';

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

Tournament _multiDivisionTournament({num entryFee = 200001}) =>
    Tournament.fromJson({
      'name': 'Overview content regression',
      'sport': 'badminton',
      'format': 'SINGLES',
      'bracketType': 'single_elimination',
      'status': 'in_progress',
      'creatorId': 'creator-1',
      'maxTeams': 16,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'registrationStartDate': '2099-01-01T00:00:00.000Z',
      'registrationEndDate': '2099-01-15T00:00:00.000Z',
      'startDate': '2099-02-01T00:00:00.000Z',
      'entryFee': entryFee,
      'divisions': [
        {
          'id': 'division-men',
          'name': 'Regression Men Division',
          'matchType': 'SINGLES',
          'maxParticipants': 16,
        },
        {
          'id': 'division-women',
          'name': 'Regression Women Division',
          'matchType': 'SINGLES',
          'maxParticipants': 16,
        },
      ],
    }, 'tournament-1');

Tournament _organizerTournament({Map<String, dynamic>? contactInfo}) =>
    Tournament.fromJson({
      'contactInfo': ?contactInfo,
      'name': 'Organizer placement regression',
      'sport': 'pickleball',
      'category': {'name': 'Pickleball', 'slug': 'pickleball'},
      'format': 'SINGLES',
      'bracketType': 'single_elimination',
      'status': 'in_progress',
      'creator': {'id': 'creator-1', 'fullName': 'Organizer Name'},
      'maxTeams': 16,
      'venue': {
        'name': 'Central Pickleball Hall',
        'locationAddress': 'District 1, Ho Chi Minh City',
      },
      'city': 'Ho Chi Minh City',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'registrationStartDate': '2026-09-01T00:00:00.000Z',
      'registrationEndDate': '2026-09-29T00:00:00.000Z',
      'startDate': '2026-10-01T00:00:00.000Z',
      'divisions': [
        {
          'id': 'division-men',
          'name': 'Regression Men Division',
          'matchType': 'SINGLES',
          'maxParticipants': 16,
        },
      ],
    }, 'tournament-2');

void main() {
  testWidgets(
    'overview omits division cards while keeping roadmap and fee details',
    (tester) async {
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
                tournament: _multiDivisionTournament(),
                teamCount: 0,
                resolveImageUrl: (_) => '',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('NỘI DUNG THI ĐẤU'), findsNothing);
      expect(find.text('Regression Men Division'), findsNothing);
      expect(find.text('Regression Women Division'), findsNothing);
      expect(find.text('Mở đăng ký'), findsOneWidget);
      expect(find.text('Khai mạc thi đấu'), findsOneWidget);
      expect(find.text('Lệ phí giải'), findsOneWidget);
      expect(find.text('200.001 đ'), findsOneWidget);
      expect(find.text('Thanh toán trực tiếp / QR'), findsOneWidget);
      expect(find.text('BAN TỔ CHỨC GIẢI ĐẤU'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('free entry fee is labeled once in the overview', (tester) async {
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
              tournament: _multiDivisionTournament(entryFee: 0),
              teamCount: 0,
              resolveImageUrl: (_) => '',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Miễn phí'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'organizer details remain without the management banner or top pickleball badge',
    (tester) async {
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
                tournament: _organizerTournament(
                  contactInfo: {'hidden': false},
                ),
                teamCount: 0,
                resolveImageUrl: (_) => '',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Organizer Name'), findsOneWidget);
      expect(find.text('BAN TỔ CHỨC GIẢI ĐẤU'), findsOneWidget);
      expect(find.text('Ban tổ chức giải đấu'), findsOneWidget);
      expect(find.text('Bạn là Ban tổ chức'), findsNothing);
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Image ||
              widget.image is! AssetImage ||
              widget.width == null) {
            return false;
          }
          final image = widget.image as AssetImage;
          return image.assetName == 'assets/icons/pickleball.png' &&
              widget.width! < 18;
        }),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('founder block is hidden by default like the Web detail page', (
    tester,
  ) async {
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
              tournament: _organizerTournament(),
              teamCount: 0,
              resolveImageUrl: (_) => '',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Organizer Name'), findsNothing);
    expect(find.text('BAN TỔ CHỨC GIẢI ĐẤU'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  Future<void> pumpFounderToggle(
    WidgetTester tester, {
    Map<String, dynamic>? contactInfo,
    Future<void> Function(bool hidden)? onToggle,
  }) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
              tournament: _organizerTournament(contactInfo: contactInfo),
              teamCount: 0,
              resolveImageUrl: (_) => '',
              onToggleFounderHidden: onToggle,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('manager sees the hidden founder row with an eye-off toggle', (
    tester,
  ) async {
    bool? requested;
    await pumpFounderToggle(
      tester,
      onToggle: (hidden) async => requested = hidden,
    );

    expect(find.text('Organizer Name'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tournament-founder-eye')));
    await tester.pump();

    expect(requested, isFalse);
  });

  testWidgets('manager toggle hides again when the founder is public', (
    tester,
  ) async {
    bool? requested;
    await pumpFounderToggle(
      tester,
      contactInfo: {'hidden': false},
      onToggle: (hidden) async => requested = hidden,
    );

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tournament-founder-eye')));
    await tester.pump();

    expect(requested, isTrue);
  });

  testWidgets('founder toggle ignores a second tap while saving', (
    tester,
  ) async {
    var calls = 0;
    final saving = Completer<void>();
    await pumpFounderToggle(
      tester,
      onToggle: (_) {
        calls++;
        return saving.future;
      },
    );

    final eye = find.byKey(const ValueKey('tournament-founder-eye'));
    await tester.tap(eye);
    await tester.pump();
    await tester.tap(eye);
    await tester.pump();

    expect(calls, 1);
    saving.complete();
    await tester.pump();
  });

  testWidgets('public viewer gets no founder toggle', (tester) async {
    await pumpFounderToggle(tester, contactInfo: {'hidden': false});

    expect(find.text('Organizer Name'), findsOneWidget);
    expect(find.byKey(const ValueKey('tournament-founder-eye')), findsNothing);
  });

  testWidgets('long countdown wraps without overflow on phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
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
              tournament: _multiDivisionTournament(),
              teamCount: 0,
              resolveImageUrl: (_) => '',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Hạn đăng ký còn:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('sport card is centered and location appears below', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
              tournament: _organizerTournament(),
              teamCount: 0,
              resolveImageUrl: (_) => '',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final sportCard = find.byKey(
      const ValueKey('tournament-overview-sport-card'),
    );
    final locationCard = find.byKey(
      const ValueKey('tournament-overview-location-card'),
    );
    expect(sportCard, findsOneWidget);
    expect(locationCard, findsOneWidget);

    final overviewRect = tester.getRect(find.byType(OverviewTab));
    final sportRect = tester.getRect(sportCard);
    final locationRect = tester.getRect(locationCard);
    expect(sportRect.center.dx, closeTo(overviewRect.center.dx, 1));
    expect(locationRect.width, closeTo(overviewRect.width - 32, 1));
    expect(locationRect.top, greaterThan(sportRect.bottom));
    expect(find.text('Pickleball'), findsOneWidget);
    expect(find.text('Central Pickleball Hall'), findsOneWidget);
    // The subtitle is the full venue address (same as the Web), not its last comma segment.
    expect(find.text('District 1, Ho Chi Minh City'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
