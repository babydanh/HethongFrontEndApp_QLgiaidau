import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_update_service.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class AppUpdateGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppUpdateGate({super.key, required this.child});

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_checked || !mounted) return;
    _checked = true;
    try {
      final info = await AppUpdateService(ref.read(dioProvider)).check();
      if (!mounted || info == null || !info.hasUpdate || info.storeUrl.isEmpty) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: !info.isRequired,
        builder: (_) => _UpdateDialog(info: info),
      );
    } catch (_) {
      // Version checking must never block startup when the backend is unavailable.
    }
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
