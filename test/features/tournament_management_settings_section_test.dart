import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SettingsRepository implements ITournamentRepository {
  @override
  Future<Map<String, dynamic>> generateBracket(
    String tournamentId, {
    String? divisionId,
    required String seedingType,
    bool allowReset = false,
  }) => throw UnimplementedError();
  _SettingsRepository(this.tournament, {this.updateError});

  final Tournament tournament;
  final Object? updateError;
  Map<String, dynamic>? updatedPayload;

  @override
  Future<Tournament?> getById(String id, {String? inviteCode}) async =>
      tournament;

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    if (updateError != null) throw updateError!;
    updatedPayload = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ManagementRepository implements TournamentManagementRepository {
  String? regeneratedInviteFor;

  @override
  Future<List<String>> getGallery(String id) async => const [];

  @override
  Future<Map<String, dynamic>> regenerateInviteCode(String id) async {
    regeneratedInviteFor = id;
    return const {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament(Map<String, dynamic> overrides) {
  final json = <String, dynamic>{
    'name': 'City Pickleball Cup',
    'sport': 'pickleball',
    'format': 'singles',
    'bracketType': 'single_elimination',
    'status': 'REGISTRATION_OPEN',
    'visibility': 'PUBLIC',
    'tournamentConfig': {
      'hideFeaturedCardText': true,
      'registrationMode': 'OPEN',
      'registrationForm': [
        {'id': 'skill', 'label': 'Playing level'},
      ],
      'location': {'venueName': 'North Court', 'address': '12 Lake Road'},
      'mode': 'FREE',
    },
    'createdAt': '2026-01-01T00:00:00Z',
    'updatedAt': '2026-01-01T00:00:00Z',
  };
  json.addAll(overrides);
  return Tournament.fromJson(json, 'tournament-1');
}

Future<_SettingsRepository> _pumpSection(
  WidgetTester tester,
  TournamentManagementSection section, {
  Map<String, dynamic> overrides = const <String, dynamic>{},
  _ManagementRepository? managementRepository,
  Object? updateError,
}) async {
  final tournament = _tournament(overrides);
  final repository = _SettingsRepository(tournament, updateError: updateError);
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      // Mỗi lần pump là một cây mới, để State cũ không giữ giá trị lần trước.
      key: UniqueKey(),
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(repository),
        tournamentManagementRepositoryProvider.overrideWithValue(
          managementRepository ?? _ManagementRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TournamentManagementSectionScreen(
            tournament: tournament,
            section: section,
            opsWorkspaceRoute: '/organizer/ops/tournament-1',
            actionRouteBase: '/organizer/tournaments/tournament-1/manage',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
  tester.element(find.byType(TournamentManagementSectionScreen)),
)!;

Future<void> _tapSave(WidgetTester tester, AppLocalizations l10n) async {
  final saveButton = find.widgetWithText(
    FilledButton,
    l10n.tournamentManagementSave,
  );
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('information saves name, description and config only', (
    tester,
  ) async {
    final repository = await _pumpSection(
      tester,
      TournamentManagementSection.information,
    );
    final l10n = _l10n(tester);

    final toggle = find.byKey(const ValueKey('hide-featured-card-text'));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pump();
    await _tapSave(tester, l10n);

    expect(
      repository.updatedPayload?.keys,
      unorderedEquals(['name', 'description', 'tournamentConfig']),
    );
    expect(repository.updatedPayload?['tournamentConfig'], {
      'hideFeaturedCardText': false,
      'registrationMode': 'OPEN',
      'registrationForm': [
        {'id': 'skill', 'label': 'Playing level'},
      ],
      'location': {'venueName': 'North Court', 'address': '12 Lake Road'},
      'mode': 'FREE',
    });
  });

  testWidgets('registration saves visibility alone when only visibility changes', (
    tester,
  ) async {
    final repository = await _pumpSection(
      tester,
      TournamentManagementSection.registration,
    );
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('registration-public')));
    await tester.pumpAndSettle();
    await _tapSave(tester, l10n);

    expect(repository.updatedPayload, {'visibility': 'PRIVATE'});
  });

  testWidgets('changing the registration mode merges into the saved config', (
    tester,
  ) async {
    final repository = await _pumpSection(
      tester,
      TournamentManagementSection.registration,
    );
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.tournamentManagementRegistrationModeApproval));
    await tester.pumpAndSettle();
    await _tapSave(tester, l10n);

    expect(repository.updatedPayload?.keys, unorderedEquals(['tournamentConfig']));
    expect(repository.updatedPayload?['tournamentConfig'], {
      'hideFeaturedCardText': true,
      'registrationMode': 'APPROVAL',
      'registrationForm': [
        {'id': 'skill', 'label': 'Playing level'},
      ],
      'location': {'venueName': 'North Court', 'address': '12 Lake Road'},
      'mode': 'FREE',
    });
  });

  testWidgets('pairing switch appears only for doubles and saves the organizer choice', (
    tester,
  ) async {
    await _pumpSection(tester, TournamentManagementSection.registration);
    expect(find.byKey(const ValueKey('registration-pairing')), findsNothing);

    final repository = await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{'format': 'doubles'},
    );
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('registration-pairing')));
    await tester.pumpAndSettle();
    await _tapSave(tester, l10n);

    expect(repository.updatedPayload?['tournamentConfig'], {
      'hideFeaturedCardText': true,
      'registrationMode': 'OPEN',
      'registrationForm': [
        {'id': 'skill', 'label': 'Playing level'},
      ],
      'location': {'venueName': 'North Court', 'address': '12 Lake Road'},
      'mode': 'FREE',
      'doublesPairingMode': 'SELF',
    });
  });

  testWidgets('invite code row shows only for private or invite-only tournaments with a code', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{'inviteCode': 'ABC123'},
    );
    expect(find.text(_l10n(tester).tournamentManagementCopy), findsNothing);

    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{
        'visibility': 'PRIVATE',
        'inviteCode': 'ABC123',
      },
    );
    expect(find.text(_l10n(tester).tournamentManagementCopy), findsOneWidget);

    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{
        'inviteCode': 'ABC123',
        'tournamentConfig': {'registrationMode': 'INVITE_ONLY'},
      },
    );
    expect(find.text(_l10n(tester).tournamentManagementCopy), findsOneWidget);
  });

  testWidgets('copy puts the invite code on the clipboard and confirms it', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{
        'visibility': 'PRIVATE',
        'inviteCode': 'ABC123',
      },
    );
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.tournamentManagementCopy));
    await tester.pumpAndSettle();

    expect(copied, ['ABC123']);
    expect(find.text(l10n.tournamentManagementInviteCodeCopied), findsOneWidget);
  });

  testWidgets('registration regenerates the invite code after confirmation', (
    tester,
  ) async {
    final management = _ManagementRepository();
    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{
        'visibility': 'PRIVATE',
        'inviteCode': 'ABC123',
      },
      managementRepository: management,
    );
    final l10n = _l10n(tester);

    final regenerate = find.widgetWithText(
      OutlinedButton,
      l10n.tournamentManagementRegenerateInvite,
    );
    await tester.ensureVisible(regenerate);
    await tester.tap(regenerate);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementConfirm).last);
    await tester.pumpAndSettle();

    expect(management.regeneratedInviteFor, 'tournament-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation reports the Web messages in order and sends nothing', (
    tester,
  ) async {
    final cases = <(Map<String, dynamic>, String Function(AppLocalizations))>[
      (
        {
          'registrationStartDate': '2099-02-01T00:00:00Z',
          'registrationEndDate': '2099-01-01T00:00:00Z',
          'startDate': '2099-06-01T00:00:00Z',
          'endDate': '2099-07-01T00:00:00Z',
        },
        (l) => l.tournamentManagementRegistrationEndAfterStart,
      ),
      (
        {
          'registrationStartDate': '2019-01-01T00:00:00Z',
          'registrationEndDate': '2020-01-01T00:00:00Z',
          'startDate': '2099-06-01T00:00:00Z',
          'endDate': '2099-07-01T00:00:00Z',
        },
        (l) => l.tournamentManagementRegistrationDeadlineInFuture,
      ),
      (
        {
          'registrationStartDate': '2098-01-01T00:00:00Z',
          'registrationEndDate': '2099-01-01T00:00:00Z',
          'startDate': '2098-12-01T00:00:00Z',
          'endDate': '2099-07-01T00:00:00Z',
        },
        (l) => l.tournamentManagementStartAfterRegistration,
      ),
      (
        {
          'registrationStartDate': '2098-01-01T00:00:00Z',
          'registrationEndDate': '2099-01-01T00:00:00Z',
          'startDate': '2099-06-01T00:00:00Z',
          'endDate': '2099-05-01T00:00:00Z',
        },
        (l) => l.tournamentManagementEndAfterStart,
      ),
    ];

    for (final (overrides, messageOf) in cases) {
      final repository = await _pumpSection(
        tester,
        TournamentManagementSection.registration,
        overrides: overrides,
      );
      final l10n = _l10n(tester);
      await _tapSave(tester, l10n);

      expect(find.text(messageOf(l10n)), findsOneWidget);
      expect(repository.updatedPayload, isNull);
    }
  });

  testWidgets('closed registration only extends the deadline and sends it alone', (
    tester,
  ) async {
    final repository = await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{
        'status': 'REGISTRATION_CLOSED',
        'visibility': 'PRIVATE',
        'inviteCode': 'ABC123',
        'registrationStartDate': '2098-01-01T00:00:00Z',
        'registrationEndDate': '2099-01-01T10:30:00Z',
        'startDate': '2099-06-01T00:00:00Z',
        'endDate': '2099-07-01T00:00:00Z',
      },
    );
    final l10n = _l10n(tester);

    expect(find.text(l10n.tournamentManagementRegistrationClosedHint), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byKey(const ValueKey('registration-public'))).onChanged,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(const ValueKey('registration-opens'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(const ValueKey('tournament-opening'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, l10n.tournamentManagementRegenerateInvite),
      ).onPressed,
      isNull,
    );

    await _tapSave(tester, l10n);
    expect(find.text(l10n.tournamentManagementClosedDeadlineExtensionOnly), findsOneWidget);
    expect(repository.updatedPayload, isNull);

    await tester.ensureVisible(find.byKey(const ValueKey('registration-deadline')));
    await tester.tap(find.byKey(const ValueKey('registration-deadline')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tapSave(tester, l10n);

    expect(repository.updatedPayload?.keys, unorderedEquals(['registrationEndDate']));
    final extended = DateTime.parse(
      repository.updatedPayload!['registrationEndDate'] as String,
    ).toLocal();
    expect(extended.day, 15);
    expect(
      extended.hour,
      DateTime.parse('2099-01-01T10:30:00Z').toLocal().hour,
    );
  });

  testWidgets('locked registration disables every control and the save button', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      overrides: const <String, dynamic>{
        'visibility': 'PRIVATE',
        'inviteCode': 'ABC123',
        'isRegistrationLocked': true,
      },
    );
    final l10n = _l10n(tester);

    expect(find.text(l10n.tournamentManagementRegistrationLockedHint), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byKey(const ValueKey('registration-public'))).onChanged,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(const ValueKey('registration-deadline'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, l10n.tournamentManagementRegenerateInvite),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, l10n.tournamentManagementSave),
      ).onPressed,
      isNull,
    );
  });

  testWidgets('a failed save shows the server message verbatim', (tester) async {
    const message = 'Không thể đổi chế độ xét duyệt sau khi đã có người đăng ký.';
    final request = RequestOptions(path: '/tournaments/tournament-1');
    final error = DioException(
      requestOptions: request,
      response: Response<Map<String, dynamic>>(
        requestOptions: request,
        statusCode: 400,
        data: const {'message': message},
      ),
    );
    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      updateError: error,
    );
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.tournamentManagementRegistrationModeApproval));
    await tester.pumpAndSettle();
    await _tapSave(tester, l10n);

    expect(find.text(message), findsOneWidget);
  });

  testWidgets('registration save bar stays at the bottom, outside the list, above the keyboard', (
    tester,
  ) async {
    await _pumpSection(tester, TournamentManagementSection.registration);
    final saveButton = find.widgetWithText(
      FilledButton,
      _l10n(tester).tournamentManagementSave,
    );

    expect(
      find.descendant(of: find.byType(ListView), matching: saveButton),
      findsNothing,
    );
    expect(tester.getBottomLeft(saveButton).dy, greaterThan(1400 - 120));

    tester.view.viewInsets = const FakeViewPadding(bottom: 500);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.getBottomLeft(saveButton).dy, lessThanOrEqualTo(1400 - 500));
    expect(tester.takeException(), isNull);
  });
}
