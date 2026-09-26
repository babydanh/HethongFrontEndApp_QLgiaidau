import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/models/venue_suggestion.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/venue_search_repository.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'venue results fill existing fields and submit existing payload',
    (tester) async {
      _configureViewport(tester);
      final venues = _FakeVenueSearchRepository(
        suggestions: const [
          VenueSuggestion(
            id: 'venue-1',
            name: 'Sân Quận 10',
            locationAddress: 'Quận 10, Hồ Chí Minh',
          ),
        ],
      );
      final sessions = _FakeSocialSessionRepository();
      await tester.pumpWidget(_createApp(venues: venues, sessions: sessions));
      await tester.pump();

      final nameField = _field('Tên sân');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Sân Quận 10');
      await tester.pump(const Duration(milliseconds: 299));
      expect(venues.queries, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(venues.queries, ['Sân Quận 10']);
      expect(find.widgetWithText(ListTile, 'Sân Quận 10'), findsOneWidget);
      expect(find.text('Quận 10, Hồ Chí Minh'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Sân Quận 10'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_controllerFor(tester, 'Tên sân').text, 'Sân Quận 10');
      expect(_controllerFor(tester, 'Địa điểm').text, 'Quận 10, Hồ Chí Minh');
      expect(sessions.createdRequest, isNull);
      expect(venues.queries, hasLength(1));

      final courtPicker = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(courtPicker);
      await tester.tap(courtPicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Court 1').last);
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(ElevatedButton, 'Tạo kèo');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final request = sessions.createdRequest!;
      final payload = request.toJson();
      expect(payload['venueName'], 'Sân Quận 10');
      expect(payload['venueAddress'], 'Quận 10, Hồ Chí Minh');
      expect(payload['venueId'], 'venue-1');
      expect(payload['courtId'], 'court-1');
      expect(payload['genderRequirement'], 'ANY');
      expect(payload.containsKey('latitude'), isFalse);
      expect(sessions.createCalls, 1);
      expect(sessions.idempotencyKey, isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('venue and court controls fit a 360px viewport', (tester) async {
    _configureViewport(tester, width: 360);
    final venues = _FakeVenueSearchRepository(
      suggestions: const [
        VenueSuggestion(
          id: 'venue-1',
          name: 'Sân Quận 10',
          locationAddress: 'Quận 10, Hồ Chí Minh',
        ),
      ],
    );
    await tester.pumpWidget(
      _createApp(venues: venues, sessions: _FakeSocialSessionRepository()),
    );
    await tester.pump();

    final nameField = _field('Tên sân');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Sân Quận 10');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Sân Quận 10'));
    await tester.pumpAndSettle();

    final courtPicker = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(courtPicker);
    await tester.tap(courtPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Court 1').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('API failure leaves manual venue entry and submit available', (
    tester,
  ) async {
    _configureViewport(tester);
    final venues = _FakeVenueSearchRepository(fail: true);
    final sessions = _FakeSocialSessionRepository();
    await tester.pumpWidget(_createApp(venues: venues, sessions: sessions));
    await tester.pump();

    final nameField = _field('Tên sân');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Sân tự nhập');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(
      find.text('Không tải được gợi ý. Bạn vẫn có thể nhập địa điểm.'),
      findsOneWidget,
    );

    await tester.enterText(nameField, 'Sân tự nhập');
    final addressField = _field('Địa điểm');
    await tester.ensureVisible(addressField);
    await tester.enterText(addressField, 'Địa chỉ nhập thủ công');
    final submit = find.widgetWithText(ElevatedButton, 'Tạo kèo');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sessions.createdRequest?.venueName, 'Sân tự nhập');
    expect(sessions.createdRequest?.venueAddress, 'Địa chỉ nhập thủ công');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape dismisses suggestions without clearing typed text', (
    tester,
  ) async {
    _configureViewport(tester);
    final venues = _DeferredVenueSearchRepository();
    await tester.pumpWidget(
      _createApp(venues: venues, sessions: _FakeSocialSessionRepository()),
    );
    await tester.pump();

    final nameField = _field('Tên sân');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Sân Quận 10');
    await tester.pump(const Duration(milliseconds: 300));
    expect(venues.pending, contains('Sân Quận 10'));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    venues.pending['Sân Quận 10']!.complete(const [
      VenueSuggestion(
        id: 'venue-1',
        name: 'Sân Quận 10',
        locationAddress: 'Quận 10, Hồ Chí Minh',
      ),
    ]);
    await tester.pump();
    expect(_controllerFor(tester, 'Tên sân').text, 'Sân Quận 10');
    expect(find.text('Địa điểm gợi ý'), findsNothing);
  });

  testWidgets('empty response is localized in English', (tester) async {
    _configureViewport(tester);
    final venues = _FakeVenueSearchRepository();
    await tester.pumpWidget(
      _createApp(
        venues: venues,
        sessions: _FakeSocialSessionRepository(),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();

    final addressField = _field('Địa điểm');
    await tester.ensureVisible(addressField);
    await tester.enterText(addressField, 'Unknown venue');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('No matching venues'), findsOneWidget);
    expect(_controllerFor(tester, 'Địa điểm').text, 'Unknown venue');
  });

  testWidgets('late responses cannot replace newer query results', (
    tester,
  ) async {
    _configureViewport(tester);
    final venues = _DeferredVenueSearchRepository();
    await tester.pumpWidget(
      _createApp(venues: venues, sessions: _FakeSocialSessionRepository()),
    );
    await tester.pump();

    final nameField = _field('Tên sân');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Alpha');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(nameField, 'Beta');
    await tester.pump(const Duration(milliseconds: 300));

    venues.pending['Beta']!.complete(const [
      VenueSuggestion(
        id: 'venue-beta',
        name: 'Beta Courts',
        locationAddress: 'Beta district',
      ),
    ]);
    await tester.pump();
    venues.pending['Alpha']!.complete(const [
      VenueSuggestion(
        id: 'venue-alpha',
        name: 'Alpha Courts',
        locationAddress: 'Alpha district',
      ),
    ]);
    await tester.pump();

    expect(find.text('Beta Courts'), findsOneWidget);
    expect(find.text('Alpha Courts'), findsNothing);
  });
}

void _configureViewport(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _createApp({
  required IVenueSearchRepository venues,
  required _FakeSocialSessionRepository sessions,
  Locale locale = const Locale('vi'),
}) {
  return ProviderScope(
    overrides: [
      venueSearchRepositoryProvider.overrideWith((ref) => venues),
      socialSessionRepositoryProvider.overrideWith((ref) => sessions),
      userProfileProvider.overrideWith(
        (ref) async => const UserProfile(id: 'fixture-user'),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: CreateSocialScreen(clubId: '', clubName: ''),
      ),
    ),
  );
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

TextEditingController _controllerFor(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!;

class _FakeVenueSearchRepository implements IVenueSearchRepository {
  final List<VenueSuggestion> suggestions;
  final bool fail;
  final queries = <String>[];

  _FakeVenueSearchRepository({this.suggestions = const [], this.fail = false});

  @override
  Future<List<VenueSuggestion>> search(String query, {int limit = 8}) async {
    queries.add(query);
    if (fail) throw StateError('fixture search failed');
    return suggestions.take(limit).toList(growable: false);
  }

  @override
  Future<VenueDetails> getById(String venueId) async {
    final venue = suggestions.firstWhere((item) => item.id == venueId);
    return VenueDetails(
      venue: venue,
      courts: const [
        VenueCourtSuggestion(
          id: 'court-1',
          name: 'Court 1',
          status: 'AVAILABLE',
        ),
      ],
    );
  }
}

class _DeferredVenueSearchRepository implements IVenueSearchRepository {
  final pending = <String, Completer<List<VenueSuggestion>>>{};

  @override
  Future<List<VenueSuggestion>> search(String query, {int limit = 8}) {
    return (pending[query] ??= Completer<List<VenueSuggestion>>()).future;
  }

  @override
  Future<VenueDetails> getById(String venueId) async {
    throw StateError('venue detail is not available in this test');
  }
}

class _FakeSocialSessionRepository implements ISocialSessionRepository {
  CreateSocialSessionRequest? createdRequest;
  int createCalls = 0;
  String? idempotencyKey;

  @override
  Future<SocialSessionModel> create(
    CreateSocialSessionRequest request, {
    required String idempotencyKey,
  }) async {
    createdRequest = request;
    this.idempotencyKey = idempotencyKey;
    createCalls++;
    return SocialSessionModel(
      id: 'fixture-session',
      hostUserId: 'fixture-user',
      title: request.title,
      playFormat: request.playFormat,
      startAt: request.startAt,
      venueName: request.venueName,
      venueAddress: request.venueAddress,
      sport: request.sport,
      sportName: request.sport,
      venueId: request.venueId,
      courtId: request.courtId,
      genderRequirement: request.genderRequirement,
    );
  }

  @override
  Future<SocialSessionListResponse> listByDate({
    required String date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async => const SocialSessionListResponse(items: []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
