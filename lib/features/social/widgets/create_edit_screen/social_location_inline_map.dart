import 'dart:math' show Point;

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/social_map_tile_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map inside the location sheet. A tap or a pin drag reports a placed
/// (confirmed) point; the parent decides what "confirmed" means.
///
/// Without [onPinPlaced] the map is read-only: the pin is fixed (a venue from
/// the directory) and only panning/zooming is left to the user.
class SocialLocationInlineMap extends StatefulWidget {
  const SocialLocationInlineMap({
    super.key,
    required this.controller,
    required this.pin,
    this.zoom = 15,
    this.locating = false,
    this.onPinDragged,
    this.onPinPlaced,
    this.onMyLocation,
  });

  static const height = 180.0;

  final MapController controller;
  final LatLng pin;
  final double zoom;
  final bool locating;

  /// Live position while the pin is being dragged (not yet confirmed).
  final ValueChanged<LatLng>? onPinDragged;
  final ValueChanged<LatLng>? onPinPlaced;
  final VoidCallback? onMyLocation;

  bool get readOnly => onPinPlaced == null;

  @override
  State<SocialLocationInlineMap> createState() =>
      _SocialLocationInlineMapState();
}

class _SocialLocationInlineMapState extends State<SocialLocationInlineMap> {
  Point<double>? _dragPoint;
  LatLng? _dragLatLng;

  void _dragStart() {
    _dragPoint = widget.controller.camera.latLngToScreenPoint(widget.pin);
    _dragLatLng = widget.pin;
  }

  void _dragUpdate(Offset delta) {
    final start = _dragPoint;
    if (start == null) return;
    final next = Point<double>(start.x + delta.dx, start.y + delta.dy);
    _dragPoint = next;
    _dragLatLng = widget.controller.camera.pointToLatLng(next);
    widget.onPinDragged?.call(_dragLatLng!);
  }

  void _dragEnd() {
    final end = _dragLatLng;
    _dragPoint = null;
    _dragLatLng = null;
    if (end != null) widget.onPinPlaced?.call(end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SocialLocationInlineMap.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // The map sits in a scrolling form: a no-op vertical drag
            // recognizer keeps a drag that starts on the map from scrolling
            // the page, while the map's own recognizers still win first.
            child: RawGestureDetector(
              gestures: {
                VerticalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      VerticalDragGestureRecognizer
                    >(
                      VerticalDragGestureRecognizer.new,
                      (recognizer) => recognizer.onUpdate = (_) {},
                    ),
              },
              child: Stack(
                children: [
                  _buildMap(),
                  if (!widget.readOnly)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        tooltip: l10n.socialLocationInlineMyLocation,
                        onPressed: widget.locating ? null : widget.onMyLocation,
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        icon: const Icon(Icons.my_location),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () =>
              launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
          child: const Text(
            '© OpenStreetMap contributors',
            style: TextStyle(
              fontSize: 11,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  static const _pinIcon = Icon(
    Icons.location_pin,
    color: Colors.redAccent,
    size: 42,
  );

  Widget _buildMap() {
    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: widget.pin,
        initialZoom: widget.zoom,
        minZoom: 5,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, point) => widget.onPinPlaced?.call(point),
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmTileUrl,
          userAgentPackageName: AppConstants.osmUserAgentPackageName,
          tileProvider: SocialMapTileProvider(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.pin,
              width: 44,
              height: 44,
              // The pin tip, not its centre, sits on the coordinate.
              alignment: Alignment.topCenter,
              child: widget.readOnly
                  ? _pinIcon
                  : GestureDetector(
                      key: const ValueKey('social-inline-pin'),
                      onPanStart: (_) => _dragStart(),
                      onPanUpdate: (details) => _dragUpdate(details.delta),
                      onPanEnd: (_) => _dragEnd(),
                      child: _pinIcon,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
