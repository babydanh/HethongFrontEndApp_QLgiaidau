import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/community/widgets/community_social_settings_sheet.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class FakeCommunityRepository extends Fake implements ICommunityRepository {
  final bool shouldFail;
  FakeCommunityRepository({this.shouldFail = false});

  @override
  Future<CommunitySocialSettings> getSocialSettings(String communityId) async {
    if (shouldFail) throw Exception('Network error');
    return const CommunitySocialSettings(
      postingPolicy: 'MEMBERS',
      postApprovalRequired: true,
      commentsEnabled: true,
      chatEnabled: true,
      publicFeed: true,
      memberTaggingPolicy: 'MEMBERS',
    );
  }

  @override
  Future<List<CommunityTagPreset>> getTagPresets(String communityId) async {
    if (shouldFail) throw Exception('Network error');
    return const [
      CommunityTagPreset(id: '1', name: 'Giao lưu', color: '#3B82F6'),
    ];
  }
}

void main() {
  testWidgets('CommunitySocialSettingsSheet loads settings and renders without crashing', (tester) async {
    final fakeRepo = FakeCommunityRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: CommunitySocialSettingsSheet(
            repository: fakeRepo,
            communityId: 'test-community-id',
          ),
        ),
      ),
    );

    // Complete loading
    await tester.pumpAndSettle();

    // Verify content rendered
    expect(find.text('Cài đặt bảng tin & sinh hoạt'), findsOneWidget);
    expect(find.text('Quyền đăng bài'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('CommunitySocialSettingsSheet handles error gracefully without getting stuck', (tester) async {
    final failingRepo = FakeCommunityRepository(shouldFail: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: CommunitySocialSettingsSheet(
            repository: failingRepo,
            communityId: 'test-community-id',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify it doesn't get stuck in loading
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Cài đặt bảng tin & sinh hoạt'), findsOneWidget);
  });
}
