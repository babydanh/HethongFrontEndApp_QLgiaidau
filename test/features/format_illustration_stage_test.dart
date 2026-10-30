import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/format_illustration_scenes.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/format_illustration_stage.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _types = [
  'SINGLE_ELIMINATION',
  'DOUBLE_ELIMINATION',
  'ROUND_ROBIN',
  'GROUP_STAGE_KNOCKOUT',
  'SWISS',
];

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: AppTheme.darkTheme,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: app!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('sceneFor', () {
    test('mỗi thể thức có người chơi, và mọi vị trí nằm trong khung vẽ', () {
      for (final type in _types) {
        final scene = sceneFor(type);
        expect(scene.chips, isNotEmpty, reason: type);
        for (final time in [0.0, scene.duration / 2, scene.duration]) {
          for (final chip in scene.chips) {
            final frame = chip.at(time);
            expect(frame.pos.dx, inInclusiveRange(0, kSceneCanvas.width));
            expect(frame.pos.dy, inInclusiveRange(0, kSceneCanvas.height));
            expect(frame.opacity, inInclusiveRange(0, 1));
          }
        }
      }
    });

    test('đầu cảnh mọi người chơi hiện rõ; cuối cảnh có người được tô nổi', () {
      for (final type in _types) {
        final scene = sceneFor(type);
        expect(
          scene.chips.every((chip) => chip.at(0).opacity == 1),
          isTrue,
          reason: type,
        );
      }
      for (final type in [
        'SINGLE_ELIMINATION',
        'DOUBLE_ELIMINATION',
        'GROUP_STAGE_KNOCKOUT',
      ]) {
        final scene = sceneFor(type);
        final champion = scene.chips.where(
          (chip) => chip.at(scene.duration).win == 1,
        );
        expect(champion, hasLength(1), reason: type);
        expect(champion.single.at(scene.duration).scale, greaterThan(1));
      }
    });

    test(
      'loại trực tiếp 8 đội: hạt giống 1 đi tới chức vô địch, người thua mờ đi',
      () {
        final scene = sceneFor('SINGLE_ELIMINATION');
        final one = scene.chips.firstWhere((chip) => chip.label == '1');
        final eight = scene.chips.firstWhere((chip) => chip.label == '8');
        expect(one.at(scene.duration).pos.dx, greaterThan(250));
        expect(eight.at(scene.duration).opacity, lessThan(0.5));
        expect(eight.at(scene.duration).pos, eight.at(0).pos);
      },
    );

    test('đang chạy giữa hai mốc thì vị trí nằm giữa hai đầu', () {
      final scene = sceneFor('SINGLE_ELIMINATION');
      final one = scene.chips.firstWhere((chip) => chip.label == '1');
      final start = one.at(0).pos;
      final mid = one.at(1.4).pos;
      final afterRound = one.at(2.2).pos;
      expect(mid.dx, greaterThan(start.dx));
      expect(mid.dx, lessThan(afterRound.dx));
    });
  });

  group('FormatIllustrationStage', () {
    testWidgets(
      'chạy animation, bấm tạm dừng/phát đổi icon, gỡ ra không rò ticker',
      (tester) async {
        await tester.pumpWidget(
          _host(const FormatIllustrationStage(bracketType: 'SWISS')),
        );
        expect(
          find.byKey(const ValueKey('format-illustration-canvas')),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 2));

        final toggle = find.byKey(
          const ValueKey('format-illustration-play-pause'),
        );
        expect(
          find.descendant(
            of: toggle,
            matching: find.byIcon(Icons.pause_rounded),
          ),
          findsOneWidget,
        );
        await tester.tap(toggle);
        await tester.pump();
        expect(
          find.descendant(
            of: toggle,
            matching: find.byIcon(Icons.play_arrow_rounded),
          ),
          findsOneWidget,
        );
        await tester.tap(toggle);
        await tester.pump();
        expect(
          find.descendant(
            of: toggle,
            matching: find.byIcon(Icons.pause_rounded),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('format-illustration-replay')),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('giảm chuyển động: hiện khung cuối, không có nút phát', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FormatIllustrationStage(bracketType: 'ROUND_ROBIN'),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('format-illustration-canvas')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('format-illustration-play-pause')),
        findsNothing,
      );
    });
  });
}
