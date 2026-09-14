import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_update_service.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';

class AppUpdateGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppUpdateGate({super.key, required this.child});

  static Future<void> showUpdateDialog(BuildContext context, AppUpdateInfo info) async {
    if (kDebugMode) return;
    final navContext = rootNavigatorKey.currentContext ?? context;
    await showDialog<void>(
      context: navContext,
      barrierDismissible: !info.isRequired,
      builder: (_) => _UpdateDialog(info: info),
    );
  }

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  bool _checked = false;
  bool _checking = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (kDebugMode) return;
    if (_checked || _checking || !mounted) return;
    _checking = true;
    try {
      final info = await AppUpdateService(ref.read(dioProvider)).check();
      if (!mounted) return;
      if (info == null) {
        debugPrint('[AppUpdateGate] info is null, scheduling retry...');
        _scheduleRetry();
        return;
      }
      debugPrint('[AppUpdateGate] current: ${info.currentVersion}, latest: ${info.latestVersion}, min: ${info.minimumVersion}, hasUpdate: ${info.hasUpdate}, isRequired: ${info.isRequired}');
      if (!info.hasUpdate) {
        _checked = true;
        return;
      }

      _checked = true;
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      await showDialog<void>(
        context: navContext,
        barrierDismissible: !info.isRequired,
        builder: (_) => _UpdateDialog(info: info),
      );
    } catch (e, stack) {
      debugPrint('[AppUpdateGate] check failed: $e\n$stack');
      // Version checking must never block startup when the backend is
      // unavailable. Retry shortly so a transient startup failure does not
      // make an outdated app miss the gate permanently.
      _scheduleRetry();
    } finally {
      _checking = false;
    }
  }

  void _scheduleRetry() {
    if (_checked || _retryTimer != null || !mounted) return;
    _retryTimer = Timer(const Duration(seconds: 15), () {
      _retryTimer = null;
      _checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends StatelessWidget {
  final AppUpdateInfo info;

  const _UpdateDialog({required this.info});

  Future<void> _openStore() async {
    final uri = Uri.tryParse(info.storeUrl);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !info.isRequired,
      child: AlertDialog(
        title: Text(l10n!.coreUpdateAvailable),
        content: SingleChildScrollView(
          child: Text(
            info.releaseNotes.trim().isEmpty
                ? l10n.coreUpdateDescription(info.latestVersion)
                : info.releaseNotes,
          ),
        ),
        actions: [
          if (!info.isRequired)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.coreUpdateLater),
            ),
          FilledButton(onPressed: _openStore, child: Text(l10n.coreUpdateNow)),
        ],
      ),
    );
  }
}
