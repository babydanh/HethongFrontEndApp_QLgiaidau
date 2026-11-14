import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/football_team/screens/football_teams_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api_adapter.dart';

const _mine = 'GET /football-teams/mine';
const _categories = 'GET /categories';

Map<String, dynamic> _row({
  required String id,
  required String name,
  String status = 'ACTIVE',
  int elo = 1000,
  List<Map<String, dynamic>> members = const [],
}) => {
  'team': {
    'id': id,
    'name': name,
    'categoryId': 'cat-fb',
    'status': status,
    'members': members,
  },
  'membership': {'role': 'CAPTAIN'},
  'rank': {'eloPoints': elo},
};

FakeReply _teams(List<Map<String, dynamic>> rows) =>
    FakeReply(200, {'data': rows});

const _footballCategory = FakeReply(200, {
  'data': [
    {'id': 'cat-tennis', 'name': 'Tennis', 'slug': 'tennis'},
    {'id': 'cat-fb', 'name': 'Bóng đá', 'slug': 'bong-da'},
  ],
});

/// Khung xương tải chạy hoạt ảnh vô hạn nên không dùng pumpAndSettle;
/// runAsync cho phép future giả của Dio hoàn tất.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<FakeApiAdapter> _pump(
  WidgetTester tester,
  Map<String, FakeReply> routes, {
  String? initialTeamId,
}) async {
  final adapter = FakeApiAdapter(routes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioClientProvider.overrideWithValue(fakeDioClient(adapter))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        // AppTheme tải font qua mạng (flutter_test chặn); màn chỉ cần màu.
        theme: ThemeData.light(),
        home: FootballTeamsScreen(initialTeamId: initialTeamId),
      ),
    ),
  );
  await _settle(tester);
  return adapter;
}

String _nameFieldText(WidgetTester tester) => tester
    .widget<TextField>(find.widgetWithText(TextField, 'Tên đội'))
    .controller!
    .text;

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  testWidgets(
    'chỉ liệt kê đội ACTIVE kèm ELO và số thành viên đang hoạt động',
    (tester) async {
      await _pump(tester, {
        _mine: _teams([
          _row(
            id: 't1',
            name: 'Sao Mai',
            elo: 1250,
            members: [
              {'userId': 'u1', 'role': 'CAPTAIN', 'status': 'ACTIVE'},
              {'userId': 'u2', 'role': 'PLAYER', 'status': 'INVITED'},
            ],
          ),
          _row(id: 't2', name: 'Đã giải thể', status: 'DISBANDED'),
        ]),
        _categories: _footballCategory,
      });

      expect(find.text('Đội đang hoạt động 1/3'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Sao Mai'),
        ),
        findsOneWidget,
      );
      expect(find.text('ELO 1250 · 1 thành viên'), findsOneWidget);
      expect(find.text('Đã giải thể'), findsNothing);
    },
  );

  testWidgets('tự chọn đội đầu tiên và điền tên vào ô sửa tên', (tester) async {
    await _pump(tester, {
      _mine: _teams([
        _row(id: 't1', name: 'Sao Mai'),
        _row(id: 't2', name: 'Bình Minh'),
      ]),
      _categories: _footballCategory,
    });

    expect(_nameFieldText(tester), 'Sao Mai');
  });

  testWidgets('initialTeamId chọn đúng đội được yêu cầu', (tester) async {
    await _pump(tester, {
      _mine: _teams([
        _row(id: 't1', name: 'Sao Mai'),
        _row(id: 't2', name: 'Bình Minh'),
      ]),
      _categories: _footballCategory,
    }, initialTeamId: 't2');

    expect(_nameFieldText(tester), 'Bình Minh');
  });

  testWidgets('chạm đội khác đổi đội đang chọn', (tester) async {
    await _pump(tester, {
      _mine: _teams([
        _row(id: 't1', name: 'Sao Mai'),
        _row(id: 't2', name: 'Bình Minh'),
      ]),
      _categories: _footballCategory,
    });

    await tester.tap(find.text('Bình Minh').first);
    await tester.pump();

    expect(_nameFieldText(tester), 'Bình Minh');
  });

  testWidgets('chưa có đội nào thì ẩn khối thông tin đội', (tester) async {
    await _pump(tester, {_mine: _teams([]), _categories: _footballCategory});

    expect(find.text('Đội đang hoạt động 0/3'), findsOneWidget);
    expect(find.text('Thông tin đội'), findsNothing);
    expect(find.text('Mời thành viên'), findsNothing);
  });

  testWidgets('tên đội mới trống thì bấm Tạo không gọi API', (tester) async {
    final adapter = await _pump(tester, {
      _mine: _teams([]),
      _categories: _footballCategory,
    });

    await tester.tap(find.text('Tạo'));
    await _settle(tester);

    expect(adapter.postsTo('/football-teams'), isEmpty);
  });

  testWidgets('tạo đội gửi tên đã cắt khoảng trắng cùng categoryId bóng đá', (
    tester,
  ) async {
    final adapter = await _pump(tester, {
      _mine: _teams([]),
      _categories: _footballCategory,
      'POST /football-teams': FakeReply(200, {
        'data': _row(id: 'new', name: 'Đội Mới'),
      }),
    });

    await tester.enterText(
      find.widgetWithText(TextField, 'Tên đội mới'),
      '  Đội Mới  ',
    );
    await tester.tap(find.text('Tạo'));
    await _settle(tester);

    final posts = adapter.postsTo('/football-teams').toList();
    expect(posts, hasLength(1));
    expect(posts.single.body, {'name': 'Đội Mới', 'categoryId': 'cat-fb'});
    expect(find.text('Đội đang hoạt động 1/3'), findsOneWidget);
    expect(_nameFieldText(tester), 'Đội Mới');
  });

  testWidgets('không có danh mục bóng đá thì không tạo được đội', (
    tester,
  ) async {
    final adapter = await _pump(tester, {
      _mine: _teams([]),
      _categories: const FakeReply(200, {
        'data': [
          {'id': 'cat-tennis', 'name': 'Tennis', 'slug': 'tennis'},
        ],
      }),
    });

    await tester.enterText(
      find.widgetWithText(TextField, 'Tên đội mới'),
      'Đội Mới',
    );
    await tester.tap(find.text('Tạo'));
    await _settle(tester);

    expect(adapter.postsTo('/football-teams'), isEmpty);
  });

  testWidgets(
    'thành viên đang chờ mời hiện nhãn chờ và nút hủy, không có chọn vai trò',
    (tester) async {
      await _pump(tester, {
        _mine: _teams([
          _row(
            id: 't1',
            name: 'Sao Mai',
            members: [
              {'userId': 'u-pending', 'role': 'PLAYER', 'status': 'INVITED'},
            ],
          ),
        ]),
        _categories: _footballCategory,
      });

      expect(find.text('u-pending'), findsOneWidget);
      expect(find.text('Đang mời - chờ xác nhận'), findsOneWidget);
      expect(find.byTooltip('Hủy lời mời'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    },
  );

  testWidgets('đội trưởng không có nút xóa, thành viên thường có', (
    tester,
  ) async {
    await _pump(tester, {
      _mine: _teams([
        _row(
          id: 't1',
          name: 'Sao Mai',
          members: [
            {'userId': 'u-cap', 'role': 'CAPTAIN', 'status': 'ACTIVE'},
            {'userId': 'u-player', 'role': 'PLAYER', 'status': 'ACTIVE'},
          ],
        ),
      ]),
      _categories: _footballCategory,
    });

    expect(find.byType(DropdownButton<String>), findsNWidgets(2));
    expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
  });

  testWidgets('tìm thành viên dưới 2 ký tự không gọi API', (tester) async {
    final adapter = await _pump(tester, {
      _mine: _teams([_row(id: 't1', name: 'Sao Mai')]),
      _categories: _footballCategory,
    });

    await tester.enterText(
      find.widgetWithText(TextField, 'Tên hoặc email'),
      'a',
    );
    await tester.tap(find.byIcon(Icons.search));
    await _settle(tester);

    expect(
      adapter.requests.where((r) => r.path.contains('member-candidates')),
      isEmpty,
    );
  });

  testWidgets(
    'mời ứng viên gửi lời mời, báo thành công và bỏ ứng viên khỏi danh sách',
    (tester) async {
      final adapter = await _pump(tester, {
        _mine: _teams([_row(id: 't1', name: 'Sao Mai')]),
        _categories: _footballCategory,
        'GET /football-teams/t1/member-candidates': const FakeReply(200, {
          'data': [
            {'id': 'u9', 'fullName': 'Nguyễn Văn A'},
          ],
        }),
        'POST /football-teams/t1/invites': const FakeReply(200, {'data': {}}),
      });

      await tester.enterText(
        find.widgetWithText(TextField, 'Tên hoặc email'),
        'Nguyễn',
      );
      await tester.tap(find.byIcon(Icons.search));
      await _settle(tester);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);

      await tester.tap(find.text('Mời'));
      await _settle(tester);

      expect(adapter.postsTo('/football-teams/t1/invites').single.body, {
        'userId': 'u9',
      });
      expect(find.text('Đã gửi lời mời.'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsNothing);
    },
  );

  testWidgets('lưu tên đội gửi PATCH với tên mới', (tester) async {
    final adapter = await _pump(tester, {
      _mine: _teams([_row(id: 't1', name: 'Sao Mai')]),
      _categories: _footballCategory,
      'PATCH /football-teams/t1': FakeReply(200, {
        'data': _row(id: 't1', name: 'Sao Mai 2'),
      }),
    });

    await tester.enterText(
      find.widgetWithText(TextField, 'Tên đội'),
      'Sao Mai 2',
    );
    await tester.tap(find.text('Lưu'));
    await _settle(tester);

    final patches = adapter.requests.where((r) => r.method == 'PATCH').toList();
    expect(patches, hasLength(1));
    expect(patches.single.body, {'name': 'Sao Mai 2'});
    expect(find.text('Sao Mai 2'), findsWidgets);
  });

  testWidgets('tải danh sách lỗi thì báo bằng thanh thông báo', (tester) async {
    await _pump(tester, {
      _mine: const FakeReply(403, {'message': 'Không có quyền'}),
      _categories: _footballCategory,
    });

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Đội đang hoạt động 0/3'), findsOneWidget);
  });
}
