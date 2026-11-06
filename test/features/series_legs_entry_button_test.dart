import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_detail_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _TestAuth extends AuthNotifier {
  _TestAuth(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;
}

/// `GET /series/:slug` answers `{series, organizer, legs}` inside the envelope.
DioClient _client() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'series': {
                'id': 's-1',
                'slug': 'cup',
                'name': 'Chuỗi Cup',
                'status': 'ACTIVE',
                'organizerId': 'owner-1',
              },
              'organizer': {'id': 'owner-1'},
              'legs': [
                {'id': 'l-1', 'name': 'Chặng Một', 'status': 'UPCOMING'},
              ],
            },
          },
        ),
      ),
    ),
  );
  return DioClient(tokenManager: _NoTokenManager(), dio: dio);
}

Future<void> _pump(
  WidgetTester tester, {
  required AuthState auth,
  required String userId,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/series/cup',
    routes: [
      GoRoute(
        path: '/series/:slug',
        builder: (_, state) =>
            SeriesDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/organizer/series/:id/manage',
        builder: (_, state) =>
            Scaffold(body: Text('manage ${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(_client()),
        authProvider.overrideWith(() => _TestAuth(auth)),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(id: userId, fullName: 'Tester'),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

const _manage = 'Manage legs';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'TC-SERIESLEGS-24: the series owner sees the button and opens it',
    (tester) async {
      await _pump(
        tester,
        auth: const AuthState(
          status: AuthStatus.authenticated,
          role: UserRole.organizer,
        ),
        userId: 'owner-1',
      );

      expect(find.text('Chuỗi Cup'), findsOneWidget);
      await tester.tap(find.text(_manage));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      expect(find.text('manage s-1'), findsOneWidget);
    },
  );

  testWidgets('TC-SERIESLEGS-25: an admin sees the button on any series', (
    tester,
  ) async {
    await _pump(
      tester,
      auth: const AuthState(
        status: AuthStatus.authenticated,
        role: UserRole.admin,
      ),
      userId: 'someone-else',
    );

    expect(find.text(_manage), findsOneWidget);
  });

  testWidgets('TC-SERIESLEGS-26: another organizer does not see the button', (
    tester,
  ) async {
    await _pump(
      tester,
      auth: const AuthState(
        status: AuthStatus.authenticated,
        role: UserRole.organizer,
      ),
      userId: 'someone-else',
    );

    expect(find.text('Chuỗi Cup'), findsOneWidget);
    expect(find.text(_manage), findsNothing);
  });

  testWidgets('TC-SERIESLEGS-27: a guest does not see the button', (
    tester,
  ) async {
    await _pump(tester, auth: const AuthState(), userId: '');

    expect(find.text('Chuỗi Cup'), findsOneWidget);
    expect(find.text(_manage), findsNothing);
  });
}
