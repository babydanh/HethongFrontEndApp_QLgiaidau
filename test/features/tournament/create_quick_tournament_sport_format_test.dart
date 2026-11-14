import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api_adapter.dart';
import 'create_quick_tournament_harness.dart';

List<Map<String, dynamic>> _divisions(Harness h) =>
    (h.lastBody['divisions'] as List).cast<Map<String, dynamic>>();

Future<Harness> _submitAfter(
  WidgetTester tester,
  Future<void> Function() act,
  Harness h,
) async {
  await act();
  await enterName(tester, 'Giải thử nghiệm');
  await tapSubmit(tester);
  return h;
}

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen môn và nội dung thi đấu', () {
    testWidgets('liệt kê đủ bốn môn tạo được từ danh mục của máy chủ', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      for (final label in ['Pickleball', 'Cầu lông', 'Tennis', 'Bóng đá']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('bỏ qua danh mục không thuộc năm môn được phép', (
      tester,
    ) async {
      final routes = defaultRoutes()
        ..['GET /categories'] = const FakeReply(200, {
          'data': [
            {
              'id': 'c1',
              'name': 'Pickleball',
              'slug': 'pickleball',
              'isActive': true,
            },
            {
              'id': 'c9',
              'name': 'Bóng chuyền',
              'slug': 'volleyball',
              'isActive': true,
            },
          ],
        });
      await pumpCreateScreen(tester, routes: routes);
      expect(find.text('Pickleball'), findsOneWidget);
      expect(find.text('Bóng chuyền'), findsNothing);
    });

    testWidgets('mặc định là pickleball với nội dung Đôi linh hoạt', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải mặc định');
      await tapSubmit(tester);
      expect(h.lastBody['sport'], 'pickleball');
      expect(h.lastBody['format'], 'doubles');
      expect(_divisions(h).single['matchType'], 'DOUBLES');
      expect(_divisions(h).single['name'], vi.tournamentCategoryOpenDoubles);
    });

    testWidgets('chọn Tennis thì gửi sport tennis', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _submitAfter(tester, () async {
        await tester.tap(find.text('Tennis'));
        await tester.pump();
      }, h);
      expect(h.lastBody['sport'], 'tennis');
    });

    testWidgets('chọn Cầu lông thì gửi sport badminton', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _submitAfter(tester, () async {
        await tester.tap(find.text('Cầu lông'));
        await tester.pump();
      }, h);
      expect(h.lastBody['sport'], 'badminton');
    });

    testWidgets(
      'chỉ còn đôi nam nữ thì gửi genderRestriction MIXED ở cấp giải',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await tester.tap(find.byType(Checkbox).first); // bỏ Đôi linh hoạt
        await tester.pump();
        await enterName(tester, 'Giải hỗn hợp');
        await tapSubmit(tester);
        expect(h.lastBody['genderRestriction'], 'MIXED');
        expect(h.lastBody['format'], 'mixed_doubles');
      },
    );

    testWidgets(
      'tick thêm đôi hỗn hợp: 2 nội dung, mỗi nội dung một division',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await tester.tap(find.byType(Checkbox).at(1));
        await tester.pump();
        expect(find.text('Đã chọn 2 nội dung'), findsOneWidget);
        await enterName(tester, 'Giải hai nội dung');
        await tapSubmit(tester);
        final divisions = _divisions(h);
        expect(divisions, hasLength(2));
        expect(divisions.map((d) => d['matchType']), [
          'DOUBLES',
          'MIXED_DOUBLES',
        ]);
      },
    );

    testWidgets('bỏ tick nội dung cuối cùng thì chuyển sang nội dung mặc định '
        'khác thay vì để trống', (tester) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(find.text('Đã chọn 1 nội dung'), findsOneWidget);
      await enterName(tester, 'Giải một nội dung');
      await tapSubmit(tester);
      expect(_divisions(h).single['matchType'], 'MIXED_DOUBLES');
      expect(h.submitCount, 1);
    });

    testWidgets('nội dung đôi gửi doublesPairingMode ORGANIZER', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải đôi');
      await tapSubmit(tester);
      expect(h.lastBody['doublesPairingMode'], 'ORGANIZER');
    });

    testWidgets(
      'mọi division mang giờ bắt đầu trùng với giờ bắt đầu của giải',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await enterName(tester, 'Giải giờ');
        await tapSubmit(tester);
        expect(_divisions(h).single['startDate'], h.lastBody['startDate']);
        expect(
          _divisions(h).single['registrationEndDate'],
          h.lastBody['registrationEndDate'],
        );
      },
    );

    testWidgets('đổi môn đặt lại nội dung về mặc định của môn mới', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();
      expect(find.text('Đã chọn 2 nội dung'), findsOneWidget);
      await tester.tap(find.text('Tennis'));
      await tester.pump();
      expect(find.text('Đã chọn 1 nội dung'), findsOneWidget);
      await enterName(tester, 'Giải tennis');
      await tapSubmit(tester);
      expect(_divisions(h), hasLength(1));
    });

    testWidgets('bật Xếp hạng ELO trong cài đặt nâng cao thì gửi isRanked', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await openAdvanced(tester);
      await tester.tap(find.text(vi.tournamentCreateUnranked));
      await tester.pump();
      expect(find.text(vi.tournamentCreateRanked), findsOneWidget);
      await enterName(tester, 'Giải xếp hạng');
      await tapSubmit(tester);
      expect(h.lastBody['isRanked'], isTrue);
    });

    testWidgets('mặc định giải phong trào gửi isRanked false', (tester) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải phong trào');
      await tapSubmit(tester);
      expect(h.lastBody['isRanked'], isFalse);
    });
  });
}
