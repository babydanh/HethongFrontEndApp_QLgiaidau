import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/core/widgets/socket_observer.dart';
import 'package:app_quanly_giaidau/core/widgets/app_update_gate.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class TournamentApp extends ConsumerWidget {
  const TournamentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return SocketObserver(
      child: AppUpdateGate(
        child: MaterialApp.router(
        title: AppLocalizations.of(context)?.coreAppTitle ?? 'Tournament Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        scrollBehavior: MyCustomScrollBehavior(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
  }
}
