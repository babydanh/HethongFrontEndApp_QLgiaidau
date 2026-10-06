import 'dart:io';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/data/repositories/api/backend_social_location_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_flow.dart';
import 'package:latlong2/latlong.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participants_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_ticket_slots.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Opt-in network test. All participants come from the real server, unchanged.
// No fake adapters, provider overrides, fixtures, or synthetic participant rows.
void main() {
  const enabled = bool.fromEnvironment('SOCIAL_LIVE');
  const date = String.fromEnvironment('SOCIAL_LIVE_DATE');
  final sessions = <SocialSessionModel>[];
  final regions = <({LatLng pin, SocialPlace region, String venueName})>[];
  Map<String, dynamic> unwrap(dynamic value) {
    final body = Map<String, dynamic>.from(value as Map);
    return body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : body;
  }

  setUpAll(() async {
    if (!enabled) return;
    if (date.isEmpty) throw StateError('SOCIAL_LIVE_DATE is required');
    // Remove flutter_test's HTTP-400 override to use the real OS HTTP client.
    HttpOverrides.global = null;
    final env = <String, String>{};
    for (final line in File('.env').readAsLinesSync()) {
      final split = line.indexOf('=');
      if (split > 0 && !line.trimLeft().startsWith('#')) {
        env[line.substring(0, split).trim()] = line
            .substring(split + 1)
            .trim()
            .replaceAll(RegExp(r'''^['"]|['"]$'''), '');
      }
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: env['API_BASE_URL']!,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          if (env['APP_API_KEY']?.isNotEmpty == true)
            'x-app-key': env['APP_API_KEY'],
        },
      ),
    );
    try {
      final rows =
          unwrap(
                (await dio.get(
                  '/social-sessions',
                  queryParameters: {'date': date, 'limit': 50},
                )).data,
              )['items']
              as List;
      for (final row in rows.take(10)) {
        final raw = unwrap(
          (await dio.get('/social-sessions/${(row as Map)['id']}')).data,
        );
        sessions.add(SocialSessionModel.fromJson(raw));
      }
      expect(
        sessions,
        isNotEmpty,
        reason: 'Need real sessions; no synthetic fallback',
      );
      for (final session in sessions.where(
        (s) => s.latitude != null && s.longitude != null,
      )) {
        final pin = LatLng(session.latitude!, session.longitude!);
        final region = await BackendSocialLocationRepository(
          dio: dio,
        ).reverseLookup(pin);
        regions.add((pin: pin, region: region, venueName: session.venueName));
      }
    } finally {
      dio.close(force: true);
    }
  });

  test(
    'real resolver labels fill empty input and preserve user venue names and metadata',
    () {
      expect(regions, isNotEmpty, reason: 'Need a real pinned venue');
      for (final sample in regions) {
        for (final input in ['', '   ', sample.venueName]) {
          final place = socialPlaceFromResolvedPin(
            input,
            sample.pin,
            sample.region,
          );
          expect(
            place.name,
            input.trim().isEmpty
                ? sample.region.formattedAddress
                : input.trim(),
          );
          expect(place.latitude, sample.pin.latitude);
          expect(place.longitude, sample.pin.longitude);
          expect(place.provinceCode, sample.region.provinceCode);
          expect(place.wardCode, sample.region.wardCode);
          expect(place.regionEstimated, sample.region.regionEstimated);
          expect(place.nameFromRegion, input.trim().isEmpty);
        }
      }
    },
    skip: !enabled,
  );

  testWidgets(
    'real joined tickets render at 320px with vi/en and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final session in sessions) {
        final slots = projectSocialTickets(session);
        expect(slots.length, session.currentSlots);
        for (final locale in const [Locale('vi'), Locale('en')]) {
          for (final scale in [1.0, 2.0]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.lightTheme,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: const Size(320, 900),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: SocialParticipantsTab(
                      session: session,
                      isHost: session.isHost,
                      onAddParticipant: (_) =>
                          fail('Guest cannot add participants'),
                      onRemoveParticipant: (_) =>
                          fail('Guest cannot remove participants'),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason: 'No overflow for real API participants',
            );
            for (final slot in slots) {
              final finder = find.byKey(ValueKey(slot.key));
              await tester.scrollUntilVisible(
                finder,
                120,
                scrollable: find.byType(Scrollable).first,
              );
              expect(finder, findsOneWidget);
              expect(
                find.descendant(
                  of: finder,
                  matching: find.text(slot.participant.name),
                ),
                findsOneWidget,
              );
              if (slot.ticketIndex > 0) {
                expect(
                  find.descendant(
                    of: finder,
                    matching: find.text('+${slot.ticketIndex}'),
                  ),
                  findsOneWidget,
                );
              } else {
                expect(
                  find.descendant(
                    of: finder,
                    matching: find.textContaining(RegExp(r'^\+\d+$')),
                  ),
                  findsNothing,
                );
              }
              await tester.tap(finder);
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: !enabled,
  );
}
