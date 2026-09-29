import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget coverage for the approved Social create/edit sport catalog.
///
/// The sport section is driven by `categoriesProvider` (active categories
/// only), renders shared sport icons and blocks submission when none is active.
/// It keeps legacy inactive sports read-only; the two inline locality fields
/// and the city/ward lists behind them are covered by
/// `social_region_picker_test.dart`.
void main() {
  group('Social create/edit active sport catalog', () {
    testWidgets(
      'new form offers the provider catalog instead of the previous fixed list',
      (tester) async {
        await _pumpSocialForm(
          tester,
          categories: [
            _category('cat-badminton', 'Cầu lông', 'cau-long'),
            _category('cat-volleyball', 'Bóng chuyền', 'bong-chuyen'),
            _category('cat-table-tennis', 'Bóng bàn', 'bong-ban'),
          ],
        );

        expect(textCI('Môn thể thao'), findsOneWidget);
        expect(find.text('Cầu lông'), findsOneWidget);
        expect(find.text('Bóng chuyền'), findsOneWidget);
        expect(find.text('Bóng bàn'), findsOneWidget);
        // Previously hard-coded options that this catalog does not contain.
        expect(find.text('Pickleball'), findsNothing);
        expect(find.text('Tennis'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('an inactive category is never offered for a new session', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        categories: [
          _category('cat-badminton', 'Cầu lông', 'cau-long'),
          _category('cat-retired-tennis', 'Tennis', 'tennis', isActive: false),
          _category(
            'cat-retired-pickleball',
            'Pickleball',
            'pickleball',
            isActive: false,
          ),
        ],
      );

      expect(find.text('Cầu lông'), findsOneWidget);
      expect(find.text('Tennis'), findsNothing);
      expect(find.text('Pickleball'), findsNothing);
      // The remaining active choice still keeps the create path open.
      expect(_submitAction(tester).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sport cards use the shared icon source for every category', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        categories: [
          _category('cat-badminton', 'Cầu lông', 'cau-long'),
          _category('cat-pickleball', 'Pickleball', 'pickleball'),
          _category('cat-unknown', 'Thể thao mới', 'the-thao-moi'),
        ],
      );

      expect(_cardAsset(tester, 'Cầu lông'), 'assets/icons/badminton.svg');
      expect(_cardAsset(tester, 'Pickleball'), 'assets/icons/pickleball.png');
      expect(_cardAsset(tester, 'Thể thao mới'), 'assets/icons/ball_icon.svg');
      expect(tester.takeException(), isNull);
    });

    testWidgets('venue name and address precede the inline locality fields', (
      tester,
    ) async {
      await _pumpSocialForm(tester, categories: _activeCatalog);

      // Both locality fields are on the form itself: no opener, no sheet.
      final areaControl = textCI('Tỉnh / thành');
      expect(areaControl, findsOneWidget);
      expect(textCI('Phường / xã'), findsOneWidget);
      expect(
        tester.getTopLeft(_venueNameField()).dy,
        lessThan(tester.getTopLeft(areaControl).dy),
      );
      expect(
        tester.getTopLeft(_addressField()).dy,
        lessThan(tester.getTopLeft(areaControl).dy),
      );
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sport card icons render unfiltered like the home filter', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        categories: [
          _category('cat-badminton', 'Cầu lông', 'cau-long'),
          _category('cat-table-tennis', 'Bóng bàn', 'bong-ban'),
        ],
      );

      // The home filter's `SportChoiceTile` draws the shared sport asset as-is.
      // Any color filter above it here would repaint the original glyph.
      expect(_colorFiltersAbove(tester, 'Cầu lông'), isEmpty);
      expect(_colorFiltersAbove(tester, 'Bóng bàn'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retrying a failed catalog lookup shows the active catalog', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        categories: _activeCatalog,
        categoriesFailures: 1,
      );

      expect(textCI('Không tải được danh sách môn thể thao.'), findsOneWidget);
      expect(_submitAction(tester).onPressed, isNull);

      await tester.tap(_sportRetry());
      await _pumpUi(tester);

      expect(find.text('Cầu lông'), findsOneWidget);
      expect(find.text('Bóng bàn'), findsOneWidget);
      expect(_submitAction(tester).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'an empty active catalog explains the state and keeps create disabled',
      (tester) async {
        await _pumpSocialForm(tester, categories: const []);

        expect(textCI('Môn thể thao'), findsOneWidget);
        expect(
          textCI('Hiện chưa có môn thể thao nào được bật.'),
          findsOneWidget,
        );
        expect(_sportRetry(), findsOneWidget);
        expect(find.text('Pickleball'), findsNothing);
        expect(find.text('Tennis'), findsNothing);
        expect(_submitAction(tester).onPressed, isNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a catalog lookup failure explains the state and keeps the manual venue usable',
      (tester) async {
        await _pumpSocialForm(
          tester,
          categories: const [],
          categoriesFailures: 1,
        );

        expect(textCI('Môn thể thao'), findsOneWidget);
        expect(
          textCI('Không tải được danh sách môn thể thao.'),
          findsOneWidget,
        );
        expect(_sportRetry(), findsOneWidget);
        // No silent substitution of the previous static sport list.
        expect(find.text('Pickleball'), findsNothing);
        expect(find.text('Tennis'), findsNothing);
        expect(_submitAction(tester).onPressed, isNull);

        // The manual venue and address stay editable while sports are broken.
        await tester.enterText(_venueNameField(), 'Sân 22 Cộng Hòa');
        await tester.enterText(_addressField(), '202 Hoàng Văn Thụ, Quận 3');
        await _pumpUi(tester);
        expect(_fieldText(tester, _venueNameField()), 'Sân 22 Cộng Hòa');
        expect(
          _fieldText(tester, _addressField()),
          '202 Hoàng Văn Thụ, Quận 3',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a legacy inactive sport stays read-only through an unrelated edit',
      (tester) async {
        final repository = _RecordingSocialSessionRepository();
        await _pumpSocialForm(
          tester,
          categories: [
            _category('cat-badminton', 'Cầu lông', 'cau-long'),
            _category('cat-table-tennis', 'Bóng bàn', 'bong-ban'),
          ],
          initialSession: _legacySession,
          socialRepository: repository,
        );

        expect(textCI('Môn thể thao'), findsOneWidget);
        // The session's own sport is still shown, and the active catalog stays
        // available next to it.
        expect(find.text('Bóng chuyền'), findsOneWidget);
        expect(find.text('Bóng bàn'), findsOneWidget);
        expect(_proposedTitle(tester, ['Bóng chuyền']), isNotNull);

        // Tapping the read-only legacy entry must not swap the sport.
        await tester.tap(find.text('Bóng chuyền'));
        await _pumpUi(tester);
        expect(_proposedTitle(tester, ['Bóng chuyền']), isNotNull);

        // An unrelated edit (play format) keeps the legacy sport in place.
        await tester.tap(textCI('Đánh đôi'));
        await _pumpUi(tester);
        expect(find.text('Bóng chuyền'), findsOneWidget);
        expect(_proposedTitle(tester, ['Bóng chuyền']), isNotNull);
        expect(_submitAction(tester, editing: true).onPressed, isNotNull);

        // Saving that unrelated edit must send the legacy sport unchanged.
        await _submit(tester, editing: true);
        expect(repository.updates, hasLength(1));
        expect(repository.updates.single.sessionId, 'session-legacy');
        expect(
          repository.updates.single.fields['sport'],
          'bong-chuyen-retired',
        );
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'choosing an active sport explicitly replaces the legacy sport',
      (tester) async {
        final repository = _RecordingSocialSessionRepository();
        await _pumpSocialForm(
          tester,
          categories: [
            _category('cat-badminton', 'Cầu lông', 'cau-long'),
            _category('cat-table-tennis', 'Bóng bàn', 'bong-ban'),
          ],
          initialSession: _legacySession,
          socialRepository: repository,
        );

        await tester.tap(find.text('Bóng bàn'));
        await _pumpUi(tester);

        expect(_proposedTitle(tester, ['Bóng bàn']), isNotNull);
        expect(_proposedTitle(tester, ['Bóng chuyền']), isNull);

        await _submit(tester, editing: true);
        expect(repository.updates, hasLength(1));
        expect(repository.updates.single.fields['sport'], 'bong-ban');
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Social create linked and standalone copy', () {
    testWidgets('the club card links truthfully without an invite promise', (
      tester,
    ) async {
      await _pumpSocialForm(tester, categories: _activeCatalog);

      expect(
        find.text('Buổi này thuộc câu lạc bộ CLB Cầu Lông Sài Gòn.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Buổi được gắn với câu lạc bộ; thành viên không được tự động '
          'thông báo, mời hoặc thêm vào danh sách tham gia.',
        ),
        findsOneWidget,
      );
      expect(find.text('Xóa CLB'), findsOneWidget);
      // The non-interactive "Thay đổi" affordance is gone.
      expect(find.text('Thay đổi'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a club-linked create uses the club wording throughout', (
      tester,
    ) async {
      await _pumpSocialForm(tester, categories: _activeCatalog);

      expect(_headerText(tester), 'Tạo buổi giao lưu');
      expect(_submitLabel(tester), 'Tạo buổi giao lưu');
      expect(textCI('Buổi giao lưu'), findsOneWidget);
      expect(_inputLabels(tester), contains('Tên buổi giao lưu'));
      expect(_labelContaining(tester, 'phí'), 'Phí tham gia buổi giao lưu');

      await tester.tap(find.text('Xóa CLB'));
      await _pumpUi(tester);

      expect(find.text('Xóa CLB'), findsNothing);
      expect(_headerText(tester), 'Tạo kèo');
      expect(_submitLabel(tester), 'Tạo kèo');
      expect(textCI('Kèo'), findsOneWidget);
      expect(_inputLabels(tester), contains('Tên kèo'));
      expect(_labelContaining(tester, 'phí'), 'Phí tham gia kèo');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'English club and region copy render without overflow at 360 px',
      (tester) async {
        await _pumpSocialForm(
          tester,
          categories: _activeCatalog,
          locale: const Locale('en'),
          size: const Size(360, 844),
        );

        expect(_headerText(tester), 'Create club social session');
        expect(find.text('Club session'), findsOneWidget);
        expect(find.text('Sport'), findsOneWidget);

        // Both locality fields are on the form itself, in English copy.
        expect(find.text('Province / City'), findsOneWidget);
        expect(find.text('Select a province'), findsOneWidget);
        expect(find.text('Ward / Commune'), findsOneWidget);
        expect(find.text('Select a province first'), findsOneWidget);

        await _openAreaPicker(tester);

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('City/Province'), findsOneWidget);
        expect(
          find.text(
            'Area options are currently unavailable. You can still enter the address manually.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Could not load areas. You can still enter the address manually.',
          ),
          findsNothing,
        );
        expect(_areaRetry(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a club-linked create keeps the club association and the chosen sport',
      (tester) async {
        final repository = _RecordingSocialSessionRepository();
        await _pumpSocialForm(
          tester,
          categories: _activeCatalog,
          socialRepository: repository,
        );

        await tester.enterText(_venueNameField(), 'Sân 22 Cộng Hòa');
        await tester.enterText(_addressField(), '202 Hoàng Văn Thụ, Quận 3');
        await _pumpUi(tester);
        await _submit(tester);

        expect(repository.creates, hasLength(1));
        expect(repository.creates.single.communityId, 'club-1');
        expect(repository.creates.single.sport, 'cau-long');
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('unlinking the club sends the session without a club', (
      tester,
    ) async {
      final repository = _RecordingSocialSessionRepository();
      await _pumpSocialForm(
        tester,
        categories: _activeCatalog,
        socialRepository: repository,
      );

      await tester.tap(find.text('Xóa CLB'));
      await _pumpUi(tester);
      await tester.enterText(_venueNameField(), 'Sân 22 Cộng Hòa');
      await tester.enterText(_addressField(), '202 Hoàng Văn Thụ, Quận 3');
      await _pumpUi(tester);
      await _submit(tester);

      expect(repository.creates, hasLength(1));
      expect(repository.creates.single.communityId, isNull);
      expect(repository.creates.single.sport, 'cau-long');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a create route without a club uses the open wording only', (
      tester,
    ) async {
      final repository = _RecordingSocialSessionRepository();
      await _pumpSocialForm(
        tester,
        categories: _activeCatalog,
        socialRepository: repository,
        clubId: '',
        clubName: '',
      );

      expect(find.text('Xóa CLB'), findsNothing);
      expect(find.textContaining('tự động'), findsNothing);
      expect(_headerText(tester), 'Tạo kèo');
      expect(_submitLabel(tester), 'Tạo kèo');
      expect(textCI('Kèo'), findsOneWidget);
      expect(_inputLabels(tester), contains('Tên kèo'));
      expect(_labelContaining(tester, 'phí'), 'Phí tham gia kèo');

      await tester.enterText(_venueNameField(), 'Sân 22 Cộng Hòa');
      await tester.enterText(_addressField(), '202 Hoàng Văn Thụ, Quận 3');
      await _pumpUi(tester);
      await _submit(tester);

      expect(repository.creates, hasLength(1));
      expect(repository.creates.single.communityId, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a club-linked edit uses the club wording until unlinked', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        categories: _activeCatalog,
        initialSession: _legacySession,
      );

      expect(_headerText(tester), 'Cập nhật buổi giao lưu');
      expect(_submitLabel(tester, editing: true), 'Cập nhật buổi giao lưu');
      expect(textCI('Buổi giao lưu'), findsOneWidget);
      expect(_inputLabels(tester), contains('Tên buổi giao lưu'));
      expect(_labelContaining(tester, 'phí'), 'Phí tham gia buổi giao lưu');

      await tester.tap(find.text('Xóa CLB'));
      await _pumpUi(tester);

      expect(_submitLabel(tester, editing: true), 'Cập nhật kèo');
      expect(textCI('Kèo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Social create form layout', () {
    for (final width in [360.0, 390.0]) {
      testWidgets(
        'the form has no horizontal overflow at ${width.toInt()} px',
        (tester) async {
          await _pumpSocialForm(
            tester,
            size: Size(width, 844),
            categories: [
              _category('cat-badminton', 'Cầu lông', 'cau-long'),
              _category('cat-volleyball', 'Bóng chuyền', 'bong-chuyen'),
              _category('cat-table-tennis', 'Bóng bàn', 'bong-ban'),
              _category('cat-tennis', 'Quần vợt', 'quan-vot'),
            ],
          );
          expect(tester.takeException(), isNull);

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -2000),
          );
          await _pumpUi(tester);

          expect(_submitLabel(tester), isNotEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}

CategoryModel _category(
  String id,
  String name,
  String slug, {
  bool isActive = true,
}) => CategoryModel(
  id: id,
  name: name,
  slug: slug,
  description: '',
  isActive: isActive,
);

/// Active catalog shared by the club/standalone wording cases.
final _activeCatalog = <CategoryModel>[
  CategoryModel(
    id: 'cat-badminton',
    name: 'Cầu lông',
    slug: 'cau-long',
    description: '',
    isActive: true,
  ),
  CategoryModel(
    id: 'cat-table-tennis',
    name: 'Bóng bàn',
    slug: 'bong-ban',
    description: '',
    isActive: true,
  ),
];

/// Deterministic frame advance that also flushes the fake repository futures.
/// `pumpAndSettle` is avoided because a progress indicator would keep the
/// scheduler permanently busy.
Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

/// Taps the "Province / City" field, which is what opens the city list.
Future<void> _openAreaPicker(WidgetTester tester) async {
  final field = _fieldWithCopy('province / city');
  await tester.ensureVisible(field);
  await _pumpUi(tester);
  await tester.tap(field);
  await _pumpUi(tester);
}

Future<void> _pumpSocialForm(
  WidgetTester tester, {
  required List<CategoryModel> categories,
  int categoriesFailures = 0,
  SocialSessionModel? initialSession,
  ISocialSessionRepository? socialRepository,
  String clubId = 'club-1',
  String clubName = 'CLB Cầu Lông Sài Gòn',
  Locale locale = const Locale('vi'),
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final form = CreateSocialScreen(
    clubId: clubId,
    clubName: clubName,
    initialSession: initialSession,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async {
          if (categoriesFailures > 0) {
            categoriesFailures--;
            throw StateError('synthetic catalog failure');
          }
          return categories;
        }),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'host-1',
            fullName: 'Nguyễn Minh Anh',
            email: 'host@example.com',
          ),
        ),
        communityRepositoryProvider.overrideWith(
          (ref) => _SilentCommunityRepository(),
        ),
        regionRepositoryProvider.overrideWith(
          (ref) => _SilentRegionRepository(),
        ),
        socialSessionRepositoryProvider.overrideWith(
          (ref) => socialRepository ?? _RecordingSocialSessionRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        // instead of removing the only route.
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => Scaffold(body: form))),
                child: const Text('open-social-form'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _pumpUi(tester);
  await tester.tap(find.text('open-social-form'));
  await _pumpUi(tester);
}

/// Flushes the save chain: repository call, provider refreshes, the route pop
/// transition and the success message.
Future<void> _pumpSubmit(WidgetTester tester) async {
  for (var step = 0; step < 5; step++) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Taps the create/update control and flushes the resulting save chain.
Future<void> _submit(WidgetTester tester, {bool editing = false}) async {
  await tester.tap(find.byWidget(_submitAction(tester, editing: editing)));
  await _pumpSubmit(tester);
}

/// A text input whose label or hint contains [copy]. The copy lives on the
/// surrounding [InputDecorator]; the edit control is that decorator's
/// descendant.
Finder _fieldWithCopy(String copy) {
  final decorator = find.byWidgetPredicate(
    (widget) =>
        widget is InputDecorator &&
        '${widget.decoration.labelText ?? ''} '
                '${widget.decoration.hintText ?? ''}'
            .toLowerCase()
            .contains(copy),
    description: 'text field mentioning "$copy"',
  );
  return find.descendant(of: decorator, matching: find.byType(EditableText));
}

Finder _venueNameField() => _fieldWithCopy('tên sân');

Finder _addressField() => _fieldWithCopy('địa');

String _fieldText(WidgetTester tester, Finder field) {
  expect(
    field,
    findsOneWidget,
    reason: 'The expected manual input field must stay available',
  );
  return tester.widget<EditableText>(field).controller.text;
}

/// The persistent create/update control. It is matched on the create/update
/// verb rather than on the full label, because the approved wording differs
/// between club-linked and standalone contexts, and on the button class so the
/// lookup does not pin the control's implementation.
ButtonStyleButton _submitAction(WidgetTester tester, {bool editing = false}) {
  final verb = editing ? 'cập nhật' : 'tạo';
  final finder = find.ancestor(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data ?? widget.textSpan?.toPlainText() ?? '')
              .toLowerCase()
              .contains(verb),
    ),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );
  expect(
    finder,
    findsOneWidget,
    reason: 'The "$verb" submit control is missing',
  );
  return tester.widget<ButtonStyleButton>(finder);
}

/// The wording currently shown on the create/update control.
String _submitLabel(WidgetTester tester, {bool editing = false}) {
  final button = _submitAction(tester, editing: editing);
  return find
      .descendant(of: find.byWidget(button), matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data ?? '')
      .join(' ')
      .trim();
}

/// The screen heading: the first copy the form renders, above the club card.
String? _headerText(WidgetTester tester) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data != null && data.trim().isNotEmpty) return data;
  }
  return null;
}

/// The first rendered copy containing [needle], e.g. the fee setting label.
String? _labelContaining(WidgetTester tester, String needle) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data != null && data.toLowerCase().contains(needle)) return data;
  }
  return null;
}

/// Every labeled input on the form, used to compare club and standalone
/// wording without pinning a single translation string.
Set<String> _inputLabels(WidgetTester tester) => tester
    .widgetList<InputDecorator>(find.byType(InputDecorator))
    .map((decorator) => decorator.decoration.labelText ?? '')
    .where((label) => label.isNotEmpty)
    .toSet();

/// The asset rendered on the sport card that shows [sportName].
String? _cardAsset(WidgetTester tester, String sportName) {
  final card = find
      .ancestor(of: find.text(sportName), matching: find.byType(Column))
      .first;
  final icons = find.descendant(
    of: card,
    matching: find.byWidgetPredicate(
      (widget) => widget is SvgPicture || widget is Image,
    ),
  );
  for (final element in icons.evaluate()) {
    final widget = element.widget;
    if (widget is SvgPicture) {
      final loader = widget.bytesLoader;
      if (loader is SvgAssetLoader) return loader.assetName;
    }
    if (widget is Image && widget.image is AssetImage) {
      return (widget.image as AssetImage).assetName;
    }
  }
  return null;
}

/// Every color filter drawn above the icon of the sport card showing
/// [sportName]. The shared asset keeps its own colors unless something
/// repaints it, so an empty list means the card renders like the home filter.
List<ColorFiltered> _colorFiltersAbove(WidgetTester tester, String sportName) {
  final card = find
      .ancestor(of: find.text(sportName), matching: find.byType(Column))
      .first;
  final icon = find.descendant(
    of: card,
    matching: find.byWidgetPredicate(
      (widget) => widget is SvgPicture || widget is Image,
    ),
  );
  return find
      .ancestor(of: icon, matching: find.byType(ColorFiltered))
      .evaluate()
      .map((element) => element.widget as ColorFiltered)
      .toList();
}

/// The sport catalog's own retry. The inline area section has a retry of its
/// own, so the lookup is scoped to the catalog block.
Finder _sportRetry() => find.descendant(
  of: find
      .ancestor(of: textCI('Môn thể thao'), matching: find.byType(Column))
      .first,
  matching: find.text('Thử lại'),
);

/// The locality sheet owns its retry action.
Finder _areaRetry() =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text('Retry'));

/// The session title the form proposes for whichever sport is currently held,
/// including a legacy sport that is not part of the active catalog. The hint
/// belongs to the surrounding [InputDecorator], not to the edit control.
String? _proposedTitle(WidgetTester tester, List<String> sportNames) {
  for (final decorator in tester.widgetList<InputDecorator>(
    find.byType(InputDecorator),
  )) {
    final hint = decorator.decoration.hintText;
    if (hint == null) continue;
    if (sportNames.any(hint.contains)) return hint;
  }
  return null;
}

/// Case-insensitive text lookup: the same copy may be rendered in a small-caps
/// style, so assertions target the wording rather than its casing.
Finder textCI(String value) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText())?.toLowerCase() ==
          value.toLowerCase(),
);

/// Existing session whose sport was retired from the admin catalog.
final _legacySession = SocialSessionModel(
  id: 'session-legacy',
  communityId: 'club-1',
  hostUserId: 'host-1',
  title: 'Kèo bóng chuyền cuối tuần',
  playFormat: 'Giao lưu',
  startAt: DateTime(2026, 10, 5, 9),
  durationMinutes: 120,
  venueName: 'Nhà thi đấu Quân khu 7',
  venueAddress: '202 Hoàng Văn Thụ, Phường 9, Quận 3',
  maxSlots: 8,
  currentSlots: 3,
  feePerSlot: 50000,
  visibility: 'PUBLIC',
  sport: 'bong-chuyen-retired',
  sportName: 'Bóng chuyền',
);

/// The attached-club context is resolved through this repository; the sport
/// cases do not care about it, so the stub answers "no club" and keeps the
/// form away from the real HTTP client.
class _SilentCommunityRepository extends Fake implements ICommunityRepository {
  @override
  Future<Community?> getCommunityById(String id) async => null;
}

/// The area control is covered separately; this stub keeps the form away from
/// the real HTTP client.
class _SilentRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async =>
      const [];
}

/// Captures the create and update payloads the form sends. `Fake` covers the
/// endpoints the form does not reach during a save.
class _RecordingSocialSessionRepository extends Fake
    implements ISocialSessionRepository {
  final List<CreateSocialSessionRequest> creates = [];
  final List<({String sessionId, Map<String, dynamic> fields})> updates = [];

  @override
  Future<SocialSessionModel> create(CreateSocialSessionRequest request) async {
    creates.add(request);
    return _legacySession;
  }

  @override
  Future<SocialSessionModel> update(
    String sessionId,
    Map<String, dynamic> fields,
  ) async {
    updates.add((sessionId: sessionId, fields: fields));
    return _legacySession;
  }

  @override
  Future<SocialSessionModel> getDetail(String sessionId) async =>
      _legacySession;

  @override
  Future<SocialSessionListResponse> listByDate({
    required String date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
  }) async => const SocialSessionListResponse(items: <SocialSessionModel>[]);
}
