import 'dart:async';

import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_session_create_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _clubId = 'club-1';

class _CreateCall {
  final String communityId;
  final String? name;
  final String? description;
  final String registrationMode;
  final bool isRanked;
  final int maxParticipants;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isRecurring;
  final String recurringFrequency;
  final int recurringDayOfWeek;
  final List<int> recurringDaysOfWeek;
  final String recurringTimeOfDay;
  final int recurringAdvanceDays;

  const _CreateCall({
    required this.communityId,
    required this.name,
    required this.description,
    required this.registrationMode,
    required this.isRanked,
    required this.maxParticipants,
    required this.startAt,
    required this.endAt,
    required this.isRecurring,
    required this.recurringFrequency,
    required this.recurringDayOfWeek,
    required this.recurringDaysOfWeek,
    required this.recurringTimeOfDay,
    required this.recurringAdvanceDays,
  });
}

class _FakeRepo extends Fake implements ApiClubMatchSessionRepository {
  final List<_CreateCall> creates = [];
  int lists = 0;
  Object? createError;
  Completer<void>? gate;

  @override
  Future<List<ClubMatchSessionModel>> list(String communityId) async {
    lists++;
    return const [];
  }

  @override
  Future<ClubMatchSessionModel> create({
    required String communityId,
    String? name,
    String? description,
    required String registrationMode,
    required bool isRanked,
    int maxParticipants = 16,
    DateTime? startAt,
    DateTime? endAt,
    bool isRecurring = false,
    String recurringFrequency = 'WEEKLY',
    int recurringDayOfWeek = 6,
    List<int> recurringDaysOfWeek = const [6],
    String recurringTimeOfDay = '18:00',
    int recurringAdvanceDays = 3,
  }) async {
    creates.add(
      _CreateCall(
        communityId: communityId,
        name: name,
        description: description,
        registrationMode: registrationMode,
        isRanked: isRanked,
        maxParticipants: maxParticipants,
        startAt: startAt,
        endAt: endAt,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
        recurringDayOfWeek: recurringDayOfWeek,
        recurringDaysOfWeek: recurringDaysOfWeek,
        recurringTimeOfDay: recurringTimeOfDay,
        recurringAdvanceDays: recurringAdvanceDays,
      ),
    );
    if (gate != null) await gate!.future;
    if (createError != null) throw createError!;
    return ClubMatchSessionModel.fromJson({
      'id': 's1',
      'communityId': communityId,
    });
  }
}

/// Màn tạo được mở bằng push để kiểm kết quả pop (true khi tạo xong).
class _Host extends StatefulWidget {
  final ValueChanged<Object?> onResult;
  const _Host({required this.onResult});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<Object?>(
            MaterialPageRoute(
              builder: (_) =>
                  const ClubMatchSessionCreateScreen(communityId: _clubId),
            ),
          );
          widget.onResult(result ?? 'null');
        },
        child: const Text('open'),
      ),
    ),
  );
}

/// BUG-SESSCREATE-01: SwitchListTile của mục lặp nằm trong FormSection có nền
/// (DecoratedBox) nên Flutter báo "ListTile background color or ink splashes
/// may be invisible". Chỉ bỏ qua đúng cảnh báo này, mọi lỗi khác vẫn làm hỏng ca.
void _ignoreListTileInkWarning() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<List<Object?>> _pump(WidgetTester tester, _FakeRepo repo) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _ignoreListTileInkWarning();
  final results = <Object?>[];
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (_, _) => null,
      overrides: [clubMatchSessionRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _Host(onResult: results.add),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) =>
    _tapText(tester, 'Tạo buổi giao lưu');

/// Mở dropdown đang hiển thị [current] rồi chọn [target] trong menu.
Future<void> _pick(WidgetTester tester, String current, String target) async {
  await tester.ensureVisible(find.text(current));
  await tester.pumpAndSettle();
  await tester.tap(find.text(current));
  await tester.pumpAndSettle();
  await tester.tap(find.text(target).last);
  await tester.pumpAndSettle();
}

Finder _fieldByLabel(String label) =>
    find.widgetWithText(TextFormField, label).first;

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_fieldByLabel(label));
  await tester.pumpAndSettle();
  await tester.enterText(_fieldByLabel(label), text);
  await tester.pump();
}

Future<void> _pickDateToday(WidgetTester tester) async {
  await _tapText(tester, 'Chọn ngày');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

const _durationError = 'Nhập từ 30 đến 720 phút';
const _participantsError = 'Nhập từ 2 đến 128 người';

void main() {
  testWidgets('shows the form sections with defaults and no recurring fields', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo());

    expect(find.text('Tạo buổi giao lưu CLB'), findsWidgets);
    expect(find.text('Thông tin buổi giao lưu'), findsOneWidget);
    expect(find.text('Tên buổi giao lưu'), findsOneWidget);
    expect(find.text('Chọn ngày'), findsOneWidget);
    expect(find.text('Chọn giờ'), findsOneWidget);
    expect(
      find.text('Áp dụng cộng/trừ ELO cho các trận hợp lệ'),
      findsOneWidget,
    );
    expect(find.text('Chu kỳ'), findsNothing);
    expect(find.text(_durationError), findsNothing);
  });

  testWidgets(
    'creating with defaults sends the default payload and pops true',
    (tester) async {
      final repo = _FakeRepo();
      final results = await _pump(tester, repo);
      await _submit(tester);

      final call = repo.creates.single;
      expect(call.communityId, _clubId);
      expect(call.registrationMode, 'MIXED');
      expect(call.isRanked, isTrue);
      expect(call.maxParticipants, 16);
      expect(call.startAt, isNull);
      expect(call.endAt, isNull);
      expect(call.isRecurring, isFalse);
      expect(results, [true]);
      expect(repo.lists, greaterThanOrEqualTo(1)); // danh sách được tải lại
    },
  );

  testWidgets('name and description are trimmed before sending', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    await _enter(tester, 'Tên buổi giao lưu', '  Giao lưu tối T6  ');
    await _enter(tester, 'Mô tả', '  Mang vợt riêng \n');
    await _submit(tester);

    expect(repo.creates.single.name, 'Giao lưu tối T6');
    expect(repo.creates.single.description, 'Mang vợt riêng');
  });

  testWidgets('an empty name is allowed and sent as empty text', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    await _submit(tester);

    expect(repo.creates, hasLength(1));
    expect(repo.creates.single.name, '');
  });

  testWidgets('ranked switch explains and sends the unranked choice', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(
      find.text('Trận giao lưu tự do, không tính điểm ELO'),
      findsOneWidget,
    );
    expect(find.text('Áp dụng cộng/trừ ELO cho các trận hợp lệ'), findsNothing);

    await _submit(tester);
    expect(repo.creates.single.isRanked, isFalse);
  });

  group('schedule', () {
    testWidgets('picking only a date shows it and defaults to 08:00', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _pickDateToday(tester);

      final now = DateTime.now();
      final dd = now.day.toString().padLeft(2, '0');
      final mm = now.month.toString().padLeft(2, '0');
      expect(find.text('$dd/$mm/${now.year}'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);

      await _submit(tester);
      final start = repo.creates.single.startAt!;
      expect([start.hour, start.minute], [8, 0]);
      expect(
        [start.year, start.month, start.day],
        [now.year, now.month, now.day],
      );
    });

    testWidgets('default 60 minute duration sets endAt one hour after start', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _pickDateToday(tester);
      await _submit(tester);

      final call = repo.creates.single;
      expect(
        call.endAt!.difference(call.startAt!),
        const Duration(minutes: 60),
      );
    });

    testWidgets('each preset duration sets the matching endAt', (tester) async {
      for (final (label, minutes) in [('1h30', 90), ('2h', 120), ('3h', 180)]) {
        final repo = _FakeRepo();
        await _pump(tester, repo);
        await _pickDateToday(tester);
        await _tapText(tester, label);
        await _submit(tester);

        final call = repo.creates.single;
        expect(
          call.endAt!.difference(call.startAt!),
          Duration(minutes: minutes),
          reason: label,
        );
      }
    });

    testWidgets('a duration without a date sends no endAt', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _tapText(tester, '2h');
      await _submit(tester);

      expect(repo.creates.single.startAt, isNull);
      expect(repo.creates.single.endAt, isNull);
    });

    testWidgets('picking a time with no date uses today and shows HH:mm', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _tapText(tester, 'Chọn giờ');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn giờ'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d\d:\d\d$').hasMatch(w.data ?? ''),
        ),
        findsOneWidget,
      );
      await _submit(tester);
      final now = DateTime.now();
      final start = repo.creates.single.startAt!;
      expect(
        [start.year, start.month, start.day],
        [now.year, now.month, now.day],
      );
    });

    testWidgets('cancelling the date picker leaves the date unset', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _tapText(tester, 'Chọn ngày');
      await tester.tapAt(const Offset(5, 5)); // chạm nền mờ: đóng không chọn
      await tester.pumpAndSettle();

      expect(find.text('Chọn ngày'), findsOneWidget);
      await _submit(tester);
      expect(repo.creates.single.startAt, isNull);
    });
  });

  group('custom duration', () {
    testWidgets('Tự nhập shows the minutes field and hides it for a preset', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo());
      expect(find.widgetWithText(TextFormField, 'Số phút'), findsNothing);

      await _tapText(tester, 'Tự nhập'); // chip thời lượng (đầu tiên)
      expect(find.widgetWithText(TextFormField, 'Số phút'), findsOneWidget);
    });

    testWidgets('empty custom duration blocks submit with the range message', (
      tester,
    ) async {
      final repo = _FakeRepo();
      final results = await _pump(tester, repo);
      await _tapText(tester, 'Tự nhập');
      await _submit(tester);

      expect(find.text(_durationError), findsOneWidget);
      expect(repo.creates, isEmpty);
      expect(results, isEmpty);
    });

    testWidgets('rejects 29 and 721 minutes, accepts the 30 and 720 limits', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _tapText(tester, 'Tự nhập');

      for (final bad in ['29', '721', '0']) {
        await _enter(tester, 'Số phút', bad);
        await _submit(tester);
        expect(find.text(_durationError), findsOneWidget, reason: bad);
      }
      expect(repo.creates, isEmpty);

      await _enter(tester, 'Số phút', '30');
      await _submit(tester);
      expect(repo.creates, hasLength(1));
    });

    testWidgets('720 minutes is accepted', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _pickDateToday(tester);
      await _tapText(tester, 'Tự nhập');
      await _enter(tester, 'Số phút', '720');
      await _submit(tester);

      final call = repo.creates.single;
      expect(
        call.endAt!.difference(call.startAt!),
        const Duration(minutes: 720),
      );
    });

    testWidgets('a typed duration drives endAt', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _pickDateToday(tester);
      await _tapText(tester, 'Tự nhập');
      await _enter(tester, 'Số phút', '45');
      await _submit(tester);

      final call = repo.creates.single;
      expect(
        call.endAt!.difference(call.startAt!),
        const Duration(minutes: 45),
      );
    });

    testWidgets('non-digit characters are filtered out of the field', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo());
      await _tapText(tester, 'Tự nhập');
      await _enter(tester, 'Số phút', 'a1b2-.');

      final field = tester.widget<TextFormField>(_fieldByLabel('Số phút'));
      expect(field.controller!.text, '12');
    });

    testWidgets('choosing a preset after a custom value clears the field', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _pickDateToday(tester);
      await _tapText(tester, 'Tự nhập');
      await _enter(tester, 'Số phút', '45');
      await _tapText(tester, '2h');

      expect(find.widgetWithText(TextFormField, 'Số phút'), findsNothing);
      await _submit(tester);
      final call = repo.creates.single;
      expect(
        call.endAt!.difference(call.startAt!),
        const Duration(minutes: 120),
      );
    });
  });

  group('participants', () {
    testWidgets('presets 8, 32 and 64 are sent', (tester) async {
      for (final n in [8, 32, 64]) {
        final repo = _FakeRepo();
        await _pump(tester, repo);
        await _tapText(tester, '$n');
        await _submit(tester);
        expect(repo.creates.single.maxParticipants, n);
      }
    });

    testWidgets('custom count validates 2..128 and sends the typed value', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      // Chip "Tự nhập" của mục số người nằm sau chip của thời lượng.
      await tester.ensureVisible(find.text('Tự nhập').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tự nhập').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Số người'), findsOneWidget);

      await _submit(tester);
      expect(find.text(_participantsError), findsOneWidget);

      for (final bad in ['1', '129']) {
        await _enter(tester, 'Số người', bad);
        await _submit(tester);
        expect(find.text(_participantsError), findsOneWidget, reason: bad);
      }
      expect(repo.creates, isEmpty);

      await _enter(tester, 'Số người', '128');
      await _submit(tester);
      expect(repo.creates.single.maxParticipants, 128);
    });

    testWidgets('the lower bound of 2 participants is accepted', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await tester.ensureVisible(find.text('Tự nhập').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tự nhập').last);
      await tester.pumpAndSettle();
      await _enter(tester, 'Số người', '2');
      await _submit(tester);

      expect(repo.creates.single.maxParticipants, 2);
    });
  });

  group('recurring schedule', () {
    Future<void> enableRecurring(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Tự động tạo buổi mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tự động tạo buổi mới'));
      await tester.pumpAndSettle();
    }

    testWidgets('turning it on reveals frequency, weekday, time, advance', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo());
      await enableRecurring(tester);

      expect(find.text('Hàng tuần'), findsOneWidget);
      expect(find.text('Thứ 7'), findsOneWidget);
      expect(find.text('Giờ mở buổi'), findsOneWidget);
      expect(find.text('Trước 3 ngày'), findsOneWidget);
    });

    testWidgets('submitting with the defaults sends Saturday 18:00, 3 days', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await enableRecurring(tester);
      await _submit(tester);

      final call = repo.creates.single;
      expect(call.isRecurring, isTrue);
      expect(call.recurringFrequency, 'WEEKLY');
      expect(call.recurringDayOfWeek, 6);
      expect(call.recurringDaysOfWeek, [6]);
      expect(call.recurringTimeOfDay, '18:00');
      expect(call.recurringAdvanceDays, 3);
    });

    testWidgets('weekday choice updates both day fields', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await enableRecurring(tester);
      await _pick(tester, 'Thứ 7', 'Thứ 2');
      await _submit(tester);

      expect(repo.creates.single.recurringDayOfWeek, 1);
      expect(repo.creates.single.recurringDaysOfWeek, [1]);
    });

    testWidgets('Sunday is sent as day 0', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await enableRecurring(tester);
      await _pick(tester, 'Thứ 7', 'Chủ nhật');
      await _submit(tester);

      expect(repo.creates.single.recurringDayOfWeek, 0);
      expect(repo.creates.single.recurringDaysOfWeek, [0]);
    });

    testWidgets('daily and monthly hide the weekday, biweekly keeps it', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo());
      await enableRecurring(tester);

      await _pick(tester, 'Hàng tuần', 'Mỗi ngày');
      expect(find.text('Thứ trong tuần'), findsNothing);

      await _pick(tester, 'Mỗi ngày', 'Hàng tháng');
      expect(find.text('Thứ trong tuần'), findsNothing);

      await _pick(tester, 'Hàng tháng', '2 tuần/lần');
      expect(find.text('Thứ trong tuần'), findsOneWidget);
    });

    testWidgets('frequency choice is sent', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await enableRecurring(tester);
      await _pick(tester, 'Hàng tuần', 'Hàng tháng');
      await _submit(tester);

      expect(repo.creates.single.recurringFrequency, 'MONTHLY');
    });

    testWidgets('advance days: same day is 0 and 5 days before is 5', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await enableRecurring(tester);
      await _pick(tester, 'Trước 3 ngày', 'Trong ngày');
      await _submit(tester);
      expect(repo.creates.single.recurringAdvanceDays, 0);

      final repo2 = _FakeRepo();
      await _pump(tester, repo2);
      await enableRecurring(tester);
      await _pick(tester, 'Trước 3 ngày', 'Trước 5 ngày');
      await _submit(tester);
      expect(repo2.creates.single.recurringAdvanceDays, 5);
    });

    testWidgets('turning it off again hides the fields and sends false', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await enableRecurring(tester);
      await enableRecurring(tester);

      expect(find.text('Chu kỳ'), findsNothing);
      await _submit(tester);
      expect(repo.creates.single.isRecurring, isFalse);
    });

    testWidgets('keeping the time picker open choice sends the picked time', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await enableRecurring(tester);
      await _tapText(tester, 'Giờ mở buổi');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await _submit(tester);

      expect(repo.creates.single.recurringTimeOfDay, '18:00');
    });
  });

  group('submitting and errors', () {
    testWidgets('a failed create shows the error, stays and can retry', (
      tester,
    ) async {
      final repo = _FakeRepo()..createError = Exception('boom');
      final results = await _pump(tester, repo);
      await _submit(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(ClubMatchSessionCreateScreen), findsOneWidget);
      expect(results, isEmpty);

      repo.createError = null;
      await tester.pump(const Duration(seconds: 7)); // thanh báo lỗi tự tắt
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(repo.creates, hasLength(2));
      expect(results, [true]);
    });

    testWidgets('while creating the buttons are disabled and label changes', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _FakeRepo()..gate = gate;
      final results = await _pump(tester, repo);
      await tester.ensureVisible(find.text('Tạo buổi giao lưu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo buổi giao lưu'));
      await tester.pump();

      expect(find.text('Đang tạo...'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Hủy bỏ'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.close_rounded),
            )
            .onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();
      expect(results, [true]);
    });

    testWidgets('a second tap during creation does not create twice', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _FakeRepo()..gate = gate;
      await _pump(tester, repo);
      await tester.tap(find.text('Tạo buổi giao lưu'));
      await tester.pump();
      await tester.tap(find.text('Đang tạo...'), warnIfMissed: false);
      await tester.pump();

      expect(repo.creates, hasLength(1));
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('after a failure the create button is enabled again', (
      tester,
    ) async {
      final repo = _FakeRepo()..createError = Exception('boom');
      await _pump(tester, repo);
      await _submit(tester);

      expect(find.text('Đang tạo...'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('validation failure shows no snackbar and sends nothing', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(tester, repo);
      await _tapText(tester, 'Tự nhập');
      await _submit(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(repo.creates, isEmpty);
    });
  });

  group('leaving', () {
    testWidgets('the Hủy bỏ button closes without creating', (tester) async {
      final repo = _FakeRepo();
      final results = await _pump(tester, repo);
      await _tapText(tester, 'Hủy bỏ');

      expect(find.byType(ClubMatchSessionCreateScreen), findsNothing);
      expect(results, ['null']);
      expect(repo.creates, isEmpty);
    });

    testWidgets('the close icon in the app bar closes without creating', (
      tester,
    ) async {
      final repo = _FakeRepo();
      final results = await _pump(tester, repo);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ClubMatchSessionCreateScreen), findsNothing);
      expect(results, ['null']);
      expect(repo.creates, isEmpty);
    });
  });
}
