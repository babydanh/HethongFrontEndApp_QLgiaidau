import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Màn ghim vị trí sân trên bản đồ (OpenStreetMap — không cần API key).
/// Trả về [LatLng] đã chọn qua Navigator.pop, null khi hủy.
class SocialLocationPicker extends StatefulWidget {
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

  @override
  State<SocialLocationPicker> createState() => _SocialLocationPickerState();
}

class _SocialLocationPickerState extends State<SocialLocationPicker> {
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
    final coords =
        '${_picked.latitude.toStringAsFixed(5)}, ${_picked.longitude.toStringAsFixed(5)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.socialLocationPinAction,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: l10n.socialLocationCenterOnPin,
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () => _mapController.move(_picked, 16),
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
              onTap: (_, latLng) => setState(() => _picked = latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'asia.sporto.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_pin,
                      size: 44,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
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
                      l10n.socialLocationMovePinHint(coords),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        height: 1.4,
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
}
