import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/social_map_tile_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Màn ghim vị trí sân trên bản đồ (OpenStreetMap — không cần API key).
/// Trả về [LatLng] đã chọn qua Navigator.pop, null khi hủy.
class SocialLocationPicker extends ConsumerStatefulWidget {
  /// Tâm bản đồ ban đầu (vị trí user / tọa độ cũ / fallback TP.HCM).
  final LatLng initialCenter;

  /// Pin ban đầu (khi sửa kèo đã ghim).
  final LatLng? initialPin;

  const SocialLocationPicker({
    super.key,
    required this.initialCenter,
    this.initialPin,
  });

  /// Mở picker và chờ kết quả. Dùng trong create/edit Social.
  static Future<LatLng?> show(
    BuildContext context, {
    required LatLng initialCenter,
    LatLng? initialPin,
  }) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => SocialLocationPicker(
          initialCenter: initialCenter,
          initialPin: initialPin,
        ),
      ),
    );
  }

  static Future<LatLng?> showSheet(
    BuildContext context, {
    required LatLng initialCenter,
  }) => showModalBottomSheet<LatLng>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: SocialLocationPicker(initialCenter: initialCenter),
    ),
  );

  @override
  ConsumerState<SocialLocationPicker> createState() =>
      _SocialLocationPickerState();
}

class _SocialLocationPickerState extends ConsumerState<SocialLocationPicker> {
  final MapController _mapController = MapController();
  late LatLng _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialPin ?? widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.socialLocationPinAction,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Dùng vị trí hiện tại',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _useCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15,
              minZoom: 5,
              maxZoom: 19,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _picked = position.center;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.osmUserAgentPackageName,
                tileProvider: SocialMapTileProvider(),
              ),
              IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Icon(
                      Icons.location_pin,
                      size: 44,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      l10n.socialPlaceMapHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_picked),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.socialLocationConfirmRequired,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final notifier = ref.read(userLocationProvider.notifier);
    await notifier.useCurrentPosition();
    final location = ref.read(userLocationProvider);
    if (!location.hasPosition ||
        location.latitude == null ||
        location.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(location.message ?? 'Không thể lấy vị trí hiện tại.'),
          ),
        );
      }
      return;
    }
    final point = LatLng(location.latitude!, location.longitude!);
    setState(() => _picked = point);
    _mapController.move(point, 16);
  }
}
