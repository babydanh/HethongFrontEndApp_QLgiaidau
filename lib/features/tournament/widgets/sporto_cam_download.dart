import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum SportoCamStore { android, ios }

/// Store listings of the dedicated SportO Cam recording app (not the main SportO app).
const sportoCamStoreUrls = {
  SportoCamStore.android:
      'https://play.google.com/store/apps/details?id=vn.vnvar.sportocam&hl=vi',
  SportoCamStore.ios:
      'https://apps.apple.com/vn/app/sporto-cam/id6813012756?l=vi',
};

/// A phone gets its own store only; any other platform gets both so the link can be passed on.
List<SportoCamStore> sportoCamStoresFor(TargetPlatform platform) =>
    switch (platform) {
      TargetPlatform.android => [SportoCamStore.android],
      TargetPlatform.iOS => [SportoCamStore.ios],
      _ => SportoCamStore.values,
    };

Future<void> _openExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Download buttons for the SportO Cam phone app, shown under the add-camera help.
/// [platform] and [openUrl] are only overridden by tests.
class SportoCamDownload extends StatelessWidget {
  const SportoCamDownload({
    super.key,
    this.platform,
    this.openUrl = _openExternally,
  });

  final TargetPlatform? platform;
  final Future<void> Function(Uri uri) openUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final stores = sportoCamStoresFor(platform ?? defaultTargetPlatform);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tournamentCameraSportoCamHint,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (index, store) in stores.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey('sporto-cam-download-${store.name}'),
                  style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
                  ),
                  onPressed: () =>
                      openUrl(Uri.parse(sportoCamStoreUrls[store]!)),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    store == SportoCamStore.android
                        ? l10n.tournamentCameraSportoCamAndroid
                        : l10n.tournamentCameraSportoCamIos,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
