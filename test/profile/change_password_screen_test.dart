import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
import 'package:app_quanly_giaidau/features/profile/screens/change_password_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeUserRepo implements IUserRepository {
  _FakeUserRepo({this.error});
  final Object? error;
  final calls = <List<String>>[];

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    calls.add([oldPassword, newPassword]);
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_FakeUserRepo repo, {ThemeData? theme}) {
  final router = GoRouter(
    initialLocation: '/change',
    routes: [
      GoRoute(
        path: '/change',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('PROFILE_PAGE')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [userRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      theme: theme ?? AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      routerConfig: router,
    ),
  );
}

Future<void> _fill(WidgetTester t, String cur, String next, String conf) async {
  final fields = find.byType(TextField);
  await t.enterText(fields.at(0), cur);
  await t.enterText(fields.at(1), next);
  await t.enterText(fields.at(2), conf);
  await t.pump();
}

bool _enabled(WidgetTester t) =>
    t.widget<LavishButton>(find.byType(LavishButton)).onPressed != null;

void main() {
  testWidgets('dung Lavish, nut tat khi chua hop le', (t) async {
    await t.pumpWidget(_app(_FakeUserRepo()));
    await t.pumpAndSettle();
    expect(find.byType(LavishScaffold), findsOneWidget);
    expect(find.byType(LavishTextField), findsNWidgets(3));
    expect(find.byType(LavishStickyBar), findsOneWidget);
    expect(_enabled(t), isFalse);

    await _fill(t, 'old', 'abc', 'abc');
    expect(_enabled(t), isFalse);
    await _fill(t, 'old', 'Abcdef1', 'Abcdef2');
    expect(_enabled(t), isFalse);
    await _fill(t, 'old', 'Abcdef1', 'Abcdef1');
    expect(_enabled(t), isTrue);
  });

  testWidgets('gui oldPassword/newPassword qua repo roi ve /profile', (t) async {
    final repo = _FakeUserRepo();
    await t.pumpWidget(_app(repo, theme: AppTheme.darkTheme));
    await t.pumpAndSettle();
    await _fill(t, 'Old123', 'Newpass1', 'Newpass1');
    await t.tap(find.byType(LavishButton));
    await t.pumpAndSettle();
    expect(repo.calls, [
      ['Old123', 'Newpass1'],
    ]);
    expect(find.text('PROFILE_PAGE'), findsOneWidget);
  });

  testWidgets('hien loi khi API loi va o lai man hinh', (t) async {
    final repo = _FakeUserRepo(error: Exception('Mật khẩu cũ sai'));
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    await _fill(t, 'Old123', 'Newpass1', 'Newpass1');
    await t.tap(find.byType(LavishButton));
    await t.pumpAndSettle();
    expect(repo.calls.length, 1);
    expect(find.textContaining('Mật khẩu cũ sai'), findsWidgets);
    expect(find.text('PROFILE_PAGE'), findsNothing);
    expect(_enabled(t), isTrue);
  });
}
