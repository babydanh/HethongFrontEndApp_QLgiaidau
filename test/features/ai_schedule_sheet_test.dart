import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/ai_schedule_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-WP-04-07/08 (task 4.5): sheet "AI xếp lịch" — ô lệnh chữ, nút Xem trước
/// chống bấm đúp, kế hoạch rỗng/lỗi/404 không phá màn gọi.
MatchModel _draft(String id) => MatchModel.fromJson({
  'id': id,
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
}, id);

AiScheduleSheetResult _result() =>
    AiScheduleSheetResult(drafts: [_draft('m-1')], skipped: 2, needsReview: true);

/// Mở sheet từ một nút; kết quả sheet trả về được ghi vào [popped].
Future<({List<AiScheduleSheetResult?> popped})> _open(
  WidgetTester tester,
  AiSchedulePreviewCallback onPreview,
) async {
  final popped = <AiScheduleSheetResult?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => popped.add(
                await AiScheduleSheet.show(
                  context,
                  onPreview: onPreview,
                  initialDay: DateTime(2026, 6, 1),
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
  return (popped: popped);
}

final _command = find.byKey(const ValueKey('ai-schedule-command'));
final _preview = find.byKey(const ValueKey('ai-schedule-preview'));

bool _previewEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_preview).onPressed != null;

void main() {
  testWidgets('preview stays disabled while the command is empty or blank', (
    tester,
  ) async {
    await _open(tester, (command, day) async => _result());

    expect(_previewEnabled(tester), isFalse);
    await tester.enterText(_command, '   ');
    await tester.pump();
    expect(_previewEnabled(tester), isFalse);
    await tester.enterText(_command, 'vòng 1 từ 8h');
    await tester.pump();
    expect(_previewEnabled(tester), isTrue);
  });

  testWidgets('a successful preview hands the trimmed command in and returns the drafts', (
    tester,
  ) async {
    final calls = <({String command, DateTime day})>[];
    final harness = await _open(tester, (command, day) async {
      calls.add((command: command, day: day));
      return _result();
    });

    await tester.enterText(_command, '  vòng 1 từ 8h  ');
    await tester.pump();
    await tester.tap(_preview);
    await tester.pumpAndSettle();

    expect(calls.single.command, 'vòng 1 từ 8h');
    expect(calls.single.day, DateTime(2026, 6, 1));
    final popped = harness.popped.single!;
    expect(popped.drafts.single.id, 'm-1');
    expect(popped.skipped, 2);
    expect(popped.needsReview, isTrue);
    expect(popped.unavailable, isFalse);
  });

  testWidgets('a second tap while the preview is running does not call the server again', (
    tester,
  ) async {
    final pending = Completer<AiScheduleSheetResult>();
    var calls = 0;
    final harness = await _open(tester, (command, day) {
      calls++;
      return pending.future;
    });

    await tester.enterText(_command, 'vòng 1');
    await tester.pump();
    await tester.tap(_preview);
    await tester.pump();
    await tester.tap(_preview, warnIfMissed: false);
    await tester.pump();

    expect(calls, 1);
    pending.complete(_result());
    await tester.pumpAndSettle();
    expect(harness.popped, hasLength(1));
  });

  testWidgets('an empty plan shows a friendly message and keeps the sheet open', (
    tester,
  ) async {
    final harness = await _open(
      tester,
      (command, day) async => const AiScheduleSheetResult(drafts: []),
    );

    await tester.enterText(_command, 'vòng 9');
    await tester.pump();
    await tester.tap(_preview);
    await tester.pumpAndSettle();

    expect(find.textContaining('AI chưa xếp được trận nào'), findsOneWidget);
    expect(harness.popped, isEmpty);
    expect(_previewEnabled(tester), isTrue);
  });

  testWidgets('a server error shows the server message and the sheet can retry', (
    tester,
  ) async {
    final harness = await _open(tester, (command, day) async {
      throw DioException(
        requestOptions: RequestOptions(path: '/ai'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/ai'),
          statusCode: 400,
          data: {'message': 'Không có trận phù hợp trong phạm vi đã chọn'},
        ),
        type: DioExceptionType.badResponse,
      );
    });

    await tester.enterText(_command, 'vòng 1');
    await tester.pump();
    await tester.tap(_preview);
    await tester.pumpAndSettle();

    expect(
      find.text('Không có trận phù hợp trong phạm vi đã chọn'),
      findsOneWidget,
    );
    expect(harness.popped, isEmpty);
    expect(_previewEnabled(tester), isTrue);
  });

  testWidgets('a timeout shows the generic message and the sheet can retry', (
    tester,
  ) async {
    final harness = await _open(tester, (command, day) async {
      throw DioException(
        requestOptions: RequestOptions(path: '/ai'),
        type: DioExceptionType.receiveTimeout,
      );
    });

    await tester.enterText(_command, 'vòng 1');
    await tester.pump();
    await tester.tap(_preview);
    await tester.pumpAndSettle();

    expect(harness.popped, isEmpty);
    expect(_previewEnabled(tester), isTrue);
    expect(find.byKey(const ValueKey('ai-schedule-error')), findsOneWidget);
  });

  testWidgets('a 404 from the AI route closes the sheet reporting unavailable', (
    tester,
  ) async {
    final harness = await _open(
      tester,
      (command, day) async => throw const AiScheduleUnavailableException(),
    );

    await tester.enterText(_command, 'vòng 1');
    await tester.pump();
    await tester.tap(_preview);
    await tester.pumpAndSettle();

    expect(harness.popped.single!.unavailable, isTrue);
    expect(harness.popped.single!.drafts, isEmpty);
  });
}
