import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/utils/live_embed.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMLIVE-APP-01..05: nguồn "Live YouTube / Facebook" trong form tạo camera.
const _courts = [
  TournamentCourtRef(id: 'court-1', name: 'Court 1', venueName: 'Hall'),
];
const _ytLink = 'https://youtu.be/dQw4w9WgXcQ';

final _name = find.byKey(const ValueKey('camera-editor-name'));
final _submit = find.byKey(const ValueKey('camera-editor-submit'));
final _sourceLive = find.byKey(const ValueKey('camera-source-live'));
final _link = find.byKey(const ValueKey('camera-live-link'));
final _chip = find.byKey(const ValueKey('camera-live-chip'));
final _error = find.byKey(const ValueKey('camera-live-error'));
final _preview = find.byKey(const ValueKey('camera-live-preview'));

Future<void> _open(WidgetTester tester, CameraEditorSubmit onSubmit) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => CameraEditorSheet.show(
                context,
                courts: _courts,
                onSubmit: onSubmit,
                // WebView cần plugin nền tảng; test chỉ cần biết preview có dựng với URL đúng.
                previewBuilder: (context, embed) => Text(
                  embed.embedUrl!,
                  key: const ValueKey('camera-live-preview'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(_sourceLive);
  await tester.pumpAndSettle();
}

bool _submitEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_submit).onPressed != null;

void main() {
  testWidgets(
    'TC-CAMLIVE-APP-01 link YouTube hợp lệ: chip, preview, nút lưu mở',
    (tester) async {
      await _open(tester, (value) async {});
      expect(_submitEnabled(tester), isFalse);

      await tester.enterText(_link, _ytLink);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: _chip, matching: find.text('YouTube')),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(_preview).data,
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
      );
      expect(_error, findsNothing);
    },
  );

  testWidgets(
    'TC-CAMLIVE-APP-02 link kênh: lỗi dễ hiểu, không preview, khoá nút lưu',
    (tester) async {
      await _open(tester, (value) async {});
      await tester.enterText(_name, 'Camera sân 1');
      await tester.enterText(_link, 'https://www.youtube.com/@kenh');
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(_error).data,
        contains('channel or profile page'),
      );
      expect(_preview, findsNothing);
      expect(_chip, findsNothing);
      expect(_submitEnabled(tester), isFalse);
    },
  );

  testWidgets('TC-CAMLIVE-APP-03 nút Dán lấy link từ clipboard', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': _ytLink};
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
    await _open(tester, (value) async {});

    await tester.tap(find.byKey(const ValueKey('camera-live-paste')));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(_link).controller!.text, _ytLink);
    expect(_preview, findsOneWidget);
  });

  testWidgets(
    'TC-CAMLIVE-APP-04 lưu gửi mode PULL + link chuẩn hoá, bấm hai lần chỉ gửi một lần',
    (tester) async {
      final calls = <CameraEditorValue>[];
      final gate = Completer<void>();
      await _open(tester, (value) async {
        calls.add(value);
        await gate.future;
      });
      await tester.enterText(_name, 'Camera sân 1');
      await tester.enterText(_link, _ytLink);
      await tester.pumpAndSettle();

      await tester.tap(_submit);
      await tester.pump();
      await tester.tap(_submit, warnIfMissed: false);
      await tester.pump();

      expect(calls, hasLength(1));
      expect(calls.single.mode, 'PULL');
      expect(calls.single.name, 'Camera sân 1');
      expect(
        calls.single.playbackUrl,
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'TC-CAMLIVE-APP-05 đổi về nguồn camera: ô link biến mất, lưu vẫn là PUSH',
    (tester) async {
      final calls = <CameraEditorValue>[];
      await _open(tester, (value) async => calls.add(value));
      await tester.tap(find.byKey(const ValueKey('camera-source-push')));
      await tester.pumpAndSettle();
      expect(_link, findsNothing);

      await tester.enterText(_name, 'Camera sân 2');
      await tester.tap(_submit);
      await tester.pumpAndSettle();
      expect(calls.single.mode, 'PUSH');
      expect(calls.single.playbackUrl, isNull);
    },
  );

  test('LiveEmbed dùng chung kết quả với sheet', () {
    expect(LiveEmbed.parse(_ytLink).isOk, isTrue);
  });
}
