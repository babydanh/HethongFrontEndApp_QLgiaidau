import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/features/community/screens/create_club_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_api_adapter.dart';

const _categories = FakeReply(200, {
  'data': [
    {
      'id': 'cat-pickle',
      'name': 'Pickleball',
      'slug': 'pickleball',
      'isActive': true,
    },
  ],
});

Future<void> _pump(WidgetTester tester, FakeApiAdapter adapter) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CreateClubScreen()),
      GoRoute(
        path: '/club/:id',
        builder: (_, state) =>
            Scaffold(body: Text('club-page-${state.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [dioProvider.overrideWithValue(fakeDioClient(adapter).dio)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextFormField).first, name);
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton).last);
  // runAsync cho phép future giả của Dio hoàn tất (SharedPreferences, adapter).
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () => dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test',
    ),
  );

  testWidgets('rejects a name shorter than 3 characters and sends nothing', (
    tester,
  ) async {
    final adapter = FakeApiAdapter({'GET /categories': _categories});
    await _pump(tester, adapter);
    await _enterName(tester, 'ab');
    await _submit(tester);

    expect(find.text('Tên phải ít nhất 3 ký tự'), findsOneWidget);
    expect(adapter.postsTo('/communities'), isEmpty);
  });

  testWidgets('rejects a blank name made only of spaces', (tester) async {
    final adapter = FakeApiAdapter({'GET /categories': _categories});
    await _pump(tester, adapter);
    await _enterName(tester, '     ');
    await _submit(tester);

    expect(find.text('Tên phải ít nhất 3 ký tự'), findsOneWidget);
    expect(adapter.postsTo('/communities'), isEmpty);
  });

  testWidgets('join questions appear only for approval mode', (tester) async {
    await _pump(tester, FakeApiAdapter({}));
    expect(find.text('Câu hỏi xin vào (tối đa 5)'), findsNothing);

    await tester.tap(find.text('Xét duyệt'));
    await tester.pump();
    expect(find.text('Câu hỏi xin vào (tối đa 5)'), findsOneWidget);

    await tester.tap(find.text('Tự do'));
    await tester.pump();
    expect(find.text('Câu hỏi xin vào (tối đa 5)'), findsNothing);
  });

  testWidgets('adds and removes join questions, ignoring blank ones', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter({}));
    await tester.tap(find.text('Xét duyệt'));
    await tester.pump();

    final questionField = find.byType(TextField).last;
    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);

    await tester.enterText(questionField, 'Bạn chơi trình nào?');
    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pump();
    expect(find.text('Bạn chơi trình nào?'), findsOneWidget);
    expect(tester.widget<TextField>(questionField).controller!.text, isEmpty);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Bạn chơi trình nào?'), findsNothing);
  });

  testWidgets('hides the question input once 5 questions were added', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter({}));
    await tester.tap(find.text('Xét duyệt'));
    await tester.pump();

    for (var i = 1; i <= 5; i++) {
      await tester.enterText(find.byType(TextField).last, 'Câu hỏi $i');
      await tester.tap(find.byIcon(Icons.add_circle_rounded));
      await tester.pump();
    }
    expect(find.byType(ListTile), findsNWidgets(5));
    expect(find.byIcon(Icons.add_circle_rounded), findsNothing);
  });

  testWidgets('valid form posts the club with its category and opens it', (
    tester,
  ) async {
    final adapter = FakeApiAdapter({
      'GET /categories': _categories,
      'POST /communities': const FakeReply(201, {
        'data': {'id': 'club-new', 'status': 'PENDING'},
      }),
    });
    await _pump(tester, adapter);
    await _enterName(tester, '  CLB Pickleball Quận 7  ');
    await tester.tap(find.text('Xét duyệt'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Bạn ở quận nào?');
    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pump();
    await _submit(tester);

    final body = adapter.postsTo('/communities').single.body!;
    expect(body['name'], 'CLB Pickleball Quận 7');
    expect(body['categoryIds'], ['cat-pickle']);
    expect(body['joinMode'], 'APPROVAL');
    expect(body['visibility'], 'PUBLIC');
    expect(body['joinQuestions'], ['Bạn ở quận nào?']);
    expect(find.text('club-page-club-new'), findsOneWidget);
  });

  testWidgets('does not post when the chosen sport has no category', (
    tester,
  ) async {
    final adapter = FakeApiAdapter({
      'GET /categories': const FakeReply(200, {'data': []}),
    });
    await _pump(tester, adapter);
    await _enterName(tester, 'CLB Không Môn');
    await _submit(tester);

    expect(find.textContaining('Không tìm thấy môn thể thao'), findsOneWidget);
    expect(adapter.postsTo('/communities'), isEmpty);
    expect(find.byType(CreateClubScreen), findsOneWidget);
  });

  testWidgets('server failure shows the error and stays on the form', (
    tester,
  ) async {
    final adapter = FakeApiAdapter({
      'GET /categories': _categories,
      'POST /communities': const FakeReply(500, {'message': 'boom'}),
    });
    await _pump(tester, adapter);
    await _enterName(tester, 'CLB Lỗi Máy Chủ');
    await _submit(tester);

    expect(adapter.postsTo('/communities'), hasLength(1));
    expect(find.textContaining('Lỗi:'), findsOneWidget);
    expect(find.byType(CreateClubScreen), findsOneWidget);
    expect(find.textContaining('club-page-'), findsNothing);
  });
}
