import 'dart:async';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/create_public_quick_tournament_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_api_adapter.dart';

/// Shared harness for the CreatePublicQuickTournamentScreen widget tests.
///
/// The screen posts through `dioClientProvider` (there is no repository in the
/// submit path), so the tests swap the Dio adapter and read the recorded body.

const submitRoute = 'POST /tournaments/lite';

const _categories = FakeReply(200, {
  'data': [
    {'id': 'c1', 'name': 'Pickleball', 'slug': 'pickleball', 'isActive': true},
    {'id': 'c2', 'name': 'Cầu lông', 'slug': 'badminton', 'isActive': true},
    {'id': 'c3', 'name': 'Tennis', 'slug': 'tennis', 'isActive': true},
    {'id': 'c4', 'name': 'Bóng đá', 'slug': 'football', 'isActive': true},
  ],
});

const _provinces = FakeReply(200, {
  'data': [
    {'code': '79', 'name': 'TP. Hồ Chí Minh'},
    {'code': '01', 'name': 'Hà Nội'},
  ],
});

const _wards = FakeReply(200, {
  'data': [
    {'code': '9001', 'name': 'Phường Bến Nghé', 'provinceCode': '79'},
  ],
});

const createdReply = FakeReply(201, {
  'data': {'id': 'new-1', 'name': 'Giải mùa hè', 'status': 'DRAFT'},
});

/// Adapter that can hold the submit request open to observe the busy state.
class GatedAdapter extends FakeApiAdapter {
  GatedAdapter(super.routes);

  Completer<void>? gate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final pending = gate;
    if (pending != null && options.method == 'POST') await pending.future;
    return super.fetch(options, requestStream, cancelFuture);
  }
}

class Harness {
  Harness(this.adapter);

  final GatedAdapter adapter;

  Map<String, dynamic> get lastBody =>
      adapter.postsTo('/tournaments/lite').last.body!;
  int get submitCount => adapter.postsTo('/tournaments/lite').length;
}

Map<String, FakeReply> defaultRoutes({
  bool allowEntryFees = true,
  FakeReply submit = createdReply,
}) => {
  'GET /categories': _categories,
  'GET /regions/provinces': _provinces,
  'GET /regions/wards': _wards,
  'GET /tournaments/fees': FakeReply(200, {
    'data': {'allowEntryFees': allowEntryFees},
  }),
  submitRoute: submit,
};

void setUpEnv() =>
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');

/// Lets the fake Dio futures complete (real async) and rebuilds the tree.
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<Harness> pumpCreateScreen(
  WidgetTester tester, {
  Map<String, FakeReply>? routes,
  List<String> roles = const ['ORGANIZER'],
  Size size = const Size(800, 5200),
  ISocialLocationRepository? locationRepository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final adapter = GatedAdapter(routes ?? defaultRoutes());
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const CreatePublicQuickTournamentScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME PAGE')),
      ),
      GoRoute(
        path: '/lite-manage/:id',
        builder: (_, state) =>
            Scaffold(body: Text('MANAGE ${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
        if (locationRepository != null)
          socialLocationRepositoryProvider.overrideWithValue(
            locationRepository,
          ),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(id: 'u1', fullName: 'BTC', roles: roles),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        // AppTheme loads fonts over the network; the screen only needs colours.
        theme: ThemeData.light(),
      ),
    ),
  );
  await settle(tester);
  return Harness(adapter);
}

AppLocalizations get vi => lookupAppLocalizations(const Locale('vi'));

Finder get nameField => find.byType(TextFormField).first;

Finder get submitButton => find.widgetWithText(FilledButton, 'Tạo giải đấu');

Future<void> enterName(WidgetTester tester, String value) async {
  await tester.enterText(nameField, value);
  await tester.pump();
}

Future<void> tapSubmit(WidgetTester tester, {bool wait = true}) async {
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pump();
  if (wait) await settle(tester);
}

bool submitEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

/// Opens the collapsed "Cài đặt nâng cao" block.
Future<void> openAdvanced(WidgetTester tester) async {
  await tester.tap(find.text('Cài đặt nâng cao'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// The max-teams "Khác" field.
Finder get maxTeamsField => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'Khác',
);

Future<void> enterMaxTeams(WidgetTester tester, String value) async {
  await tester.enterText(maxTeamsField, value);
  await tester.pump();
}

List<Map<String, dynamic>> divisionsOf(Harness h) =>
    (h.lastBody['divisions'] as List).cast<Map<String, dynamic>>();
