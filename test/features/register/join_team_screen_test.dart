import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/register/screens/join_team_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_api_adapter.dart';

/// Adapter giữ response lại tới khi test mở cổng, để quan sát trạng thái "đang xử lý".
class _GatedAdapter extends FakeApiAdapter {
  _GatedAdapter(super.routes);

  final Completer<void> gate = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await gate.future;
    return super.fetch(options, requestStream, cancelFuture);
  }
}

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;
}

const _signedIn = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.viewer,
  tokenCode: 'SESSION',
);

const _tournamentId = 'tour-1';
const _participantId = 'part-9';

Future<void> _pump(
  WidgetTester tester,
  FakeApiAdapter adapter, {
  AuthState auth = _signedIn,
  String token = 'INVITE-123',
  List<String>? loginRedirects,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => JoinTeamScreen(
          tournamentId: _tournamentId,
          participantId: _participantId,
          token: token,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          loginRedirects?.add(state.uri.queryParameters['redirect'] ?? '');
          return const Scaffold(body: Text('LOGIN PAGE'));
        },
      ),
      GoRoute(
        path: '/intro/:id',
        builder: (_, state) =>
            Scaffold(body: Text('INTRO ${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(() => _FakeAuth(auth)),
        dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
  await tester.pump();
}

/// DioClient dùng I/O thật (SharedPreferences, interceptor), nên cho vài nhịp
/// thời gian thật rồi dựng lại khung hình thay vì pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  final l10n = lookupAppLocalizations(const Locale('vi'));
  // ErrorParser dịch theo ngôn ngữ nền tảng, không theo locale của MaterialApp.
  final parserL10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
  const joinPath = '/tournaments/$_tournamentId/join-team';
  const acceptPath = '/tournaments/participants/$_participantId/accept-partner';

  Finder confirmButton() =>
      find.widgetWithText(ElevatedButton, l10n.joinTeamConfirm);

  group('chưa đăng nhập', () {
    testWidgets(
      'chỉ hiện nút đăng nhập, không hiện nút xác nhận và không gọi API',
      (tester) async {
        final adapter = FakeApiAdapter({});
        await _pump(tester, adapter, auth: const AuthState());

        expect(find.text(l10n.joinTeamLogin), findsOneWidget);
        expect(find.text(l10n.joinTeamConfirm), findsNothing);
        expect(find.text(l10n.joinTeamInvitation), findsNothing);
        expect(adapter.requests, isEmpty);
      },
    );

    testWidgets('bấm đăng nhập mở /login kèm redirect quay lại đúng lời mời', (
      tester,
    ) async {
      final redirects = <String>[];
      await _pump(
        tester,
        FakeApiAdapter({}),
        auth: const AuthState(),
        loginRedirects: redirects,
      );

      await tester.tap(find.text(l10n.joinTeamLogin));
      await _settle(tester);

      expect(find.text('LOGIN PAGE'), findsOneWidget);
      final redirect = Uri.parse(redirects.single);
      expect(redirect.path, '/join-team');
      expect(redirect.queryParameters, {
        'tournamentId': _tournamentId,
        'pid': _participantId,
        'token': 'INVITE-123',
      });
    });

    testWidgets(
      'mã mời có ký tự đặc biệt vẫn giữ nguyên sau khi mã hoá redirect',
      (tester) async {
        final redirects = <String>[];
        await _pump(
          tester,
          FakeApiAdapter({}),
          auth: const AuthState(),
          token: 'a b&c=d/é',
          loginRedirects: redirects,
        );

        await tester.tap(find.text(l10n.joinTeamLogin));
        await _settle(tester);

        expect(
          Uri.parse(redirects.single).queryParameters['token'],
          'a b&c=d/é',
        );
      },
    );

    testWidgets(
      'trạng thái đang xác thực (validating) vẫn coi là chưa đăng nhập',
      (tester) async {
        await _pump(
          tester,
          FakeApiAdapter({}),
          auth: const AuthState(status: AuthStatus.validating),
        );

        expect(find.text(l10n.joinTeamLogin), findsOneWidget);
        expect(find.text(l10n.joinTeamConfirm), findsNothing);
      },
    );
  });

  group('đã đăng nhập', () {
    testWidgets('hiện lời mời, mô tả và nút xác nhận đang bật, chưa gọi API', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({});
      await _pump(tester, adapter);

      expect(find.text(l10n.joinTeamTitle), findsOneWidget);
      expect(find.text(l10n.joinTeamInvitation), findsOneWidget);
      expect(find.text(l10n.joinTeamDesc), findsOneWidget);
      expect(find.text(l10n.joinTeamLogin), findsNothing);
      expect(
        tester.widget<ElevatedButton>(confirmButton()).onPressed,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
    });

    testWidgets(
      'mã mời đúng: POST join-team kèm participantId và teamInviteToken rồi hiện thành công',
      (tester) async {
        final adapter = FakeApiAdapter({
          'POST $joinPath': const FakeReply(201, {}),
        });
        await _pump(tester, adapter);

        await tester.tap(confirmButton());
        await _settle(tester);

        expect(adapter.postsTo(joinPath).single.body, {
          'participantId': _participantId,
          'teamInviteToken': 'INVITE-123',
        });
        expect(adapter.postsTo(acceptPath), isEmpty);
        expect(find.text(l10n.joinTeamSuccess), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.text(l10n.joinTeamConfirm), findsNothing);
      },
    );

    testWidgets(
      'sau khi thành công, nút Xem giải đấu chuyển tới /intro/<tournamentId>',
      (tester) async {
        final adapter = FakeApiAdapter({
          'POST $joinPath': const FakeReply(201, {}),
        });
        await _pump(tester, adapter);

        await tester.tap(confirmButton());
        await _settle(tester);
        await tester.tap(find.text(l10n.joinTeamViewTournament));
        await _settle(tester);

        expect(find.text('INTRO $_tournamentId'), findsOneWidget);
      },
    );

    testWidgets(
      'không có mã mời (token rỗng): gọi accept-partner thay vì join-team',
      (tester) async {
        final adapter = FakeApiAdapter({
          'POST $acceptPath': const FakeReply(201, {}),
        });
        await _pump(tester, adapter, token: '');

        await tester.tap(confirmButton());
        await _settle(tester);

        expect(adapter.postsTo(acceptPath), hasLength(1));
        expect(adapter.postsTo(joinPath), isEmpty);
        expect(find.text(l10n.joinTeamSuccess), findsOneWidget);
      },
    );

    testWidgets(
      'trong lúc gửi: nút bị khoá, nhãn Đang xử lý, bấm thêm không gửi lần hai',
      (tester) async {
        final adapter = _GatedAdapter({
          'POST $joinPath': const FakeReply(201, {}),
        });
        await _pump(tester, adapter);

        await tester.tap(confirmButton());
        await tester.pump();

        expect(find.text(l10n.joinTeamProcessing), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final busy = find.widgetWithText(
          ElevatedButton,
          l10n.joinTeamProcessing,
        );
        expect(tester.widget<ElevatedButton>(busy).onPressed, isNull);
        await tester.tap(busy, warnIfMissed: false);
        await tester.pump();

        adapter.gate.complete();
        await _settle(tester);

        expect(adapter.postsTo(joinPath), hasLength(1));
        expect(find.text(l10n.joinTeamSuccess), findsOneWidget);
      },
    );

    testWidgets(
      'mã mời sai (400 Invalid invite code): báo lỗi đã dịch, ở lại màn và cho thử lại',
      (tester) async {
        final adapter = FakeApiAdapter({
          'POST $joinPath': const FakeReply(400, {
            'message': 'Invalid invite code',
          }),
        });
        await _pump(tester, adapter);

        await tester.tap(confirmButton());
        await _settle(tester);

        expect(
          find.text(parserL10n.errorParserInvalidInviteCode),
          findsOneWidget,
        );
        expect(find.text(l10n.joinTeamSuccess), findsNothing);
        expect(find.text(l10n.joinTeamInvitation), findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(confirmButton()).onPressed,
          isNotNull,
        );

        await tester.tap(confirmButton());
        await _settle(tester);
        expect(adapter.postsTo(joinPath), hasLength(2));
      },
    );

    testWidgets('mã mời hết hạn: hiện nguyên thông điệp máy chủ trả về', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        'POST $joinPath': const FakeReply(410, {
          'message': 'Lời mời đã hết hạn',
        }),
      });
      await _pump(tester, adapter);

      await tester.tap(confirmButton());
      await _settle(tester);

      expect(find.text('Lời mời đã hết hạn'), findsOneWidget);
      expect(find.text(l10n.joinTeamSuccess), findsNothing);
    });

    testWidgets('máy chủ trả message dạng danh sách: hiện phần tử đầu', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        'POST $joinPath': const FakeReply(400, {
          'message': ['teamInviteToken không hợp lệ', 'khác'],
        }),
      });
      await _pump(tester, adapter);

      await tester.tap(confirmButton());
      await _settle(tester);

      expect(find.text('teamInviteToken không hợp lệ'), findsOneWidget);
    });

    testWidgets('lỗi 403 không có message: hiện thông báo từ chối quyền', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        'POST $joinPath': const FakeReply(403, {}),
      });
      await _pump(tester, adapter);

      await tester.tap(confirmButton());
      await _settle(tester);

      expect(find.text(parserL10n.errorParserForbidden), findsOneWidget);
    });

    testWidgets('mất mạng: hiện lỗi kết nối và vẫn cho bấm lại', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        'POST $joinPath': const FakeReply.networkError(),
      });
      await _pump(tester, adapter);

      await tester.tap(confirmButton());
      await _settle(tester);

      expect(find.text(parserL10n.errorParserConnectionFailed), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(confirmButton()).onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'route chưa có (404): hiện lỗi máy chủ, không hiện thành công',
      (tester) async {
        final adapter = FakeApiAdapter({});
        await _pump(tester, adapter);

        await tester.tap(confirmButton());
        await _settle(tester);

        expect(find.text('not mocked'), findsOneWidget);
        expect(find.text(l10n.joinTeamSuccess), findsNothing);
      },
    );
  });
}
