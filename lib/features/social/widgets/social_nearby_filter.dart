import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_location_picker.dart';
import 'package:latlong2/latlong.dart';

/// Toggle "Gần bạn" + chips bán kính + banner xin quyền vị trí.
/// Đặt dưới [SocialDateSelector] trong [SocialListView].
class SocialNearbyFilter extends ConsumerWidget {
  const SocialNearbyFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(socialFilterProvider);
    final location = ref.watch(userLocationProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NearbyToggle(
                active: filter.nearbyOnly,
                isDark: isDark,
                onTap: () => _onToggleNearby(ref, filter.nearbyOnly),
              ),
              // Chips bán kính — chỉ hiện khi đã bật + đã có vị trí.
              if (filter.nearbyOnly && location.hasPosition) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: nearbyRadiusOptions.map((radius) {
                        final selected = filter.radiusKm == radius;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              '${radius.toInt()} km',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: selected,
                            onSelected: (_) {
                              ref
                                  .read(socialFilterProvider.notifier)
                                  .setRadiusKm(radius);
                            },
                            selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: selected
                                  ? AppTheme.primary
                                  : (isDark
                                        ? Colors.white24
                                        : const Color(0xFFE2E8F0)),
                            ),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              if (filter.nearbyOnly && location.isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          if (filter.nearbyOnly &&
              location.status == UserLocationStatus.selected)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Vị trí đã chọn (ước lượng) · khoảng cách đường chim bay',
                style: TextStyle(fontSize: 12),
              ),
            ),
          // Banner khi bật "Gần bạn" nhưng chưa có vị trí.
          if (filter.nearbyOnly && !location.hasPosition && !location.isLoading)
            _PermissionBanner(location: location),
        ],
      ),
    );
  }

  Future<void> _onToggleNearby(WidgetRef ref, bool current) async {
    if (current) {
      ref.read(socialFilterProvider.notifier).setNearbyOnly(false);
      return;
    }
    ref.read(socialFilterProvider.notifier).setNearbyOnly(true);
    await ref.read(userLocationProvider.notifier).requestWhenInUse();
  }
}

class _NearbyToggle extends StatelessWidget {
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _NearbyToggle({
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withValues(alpha: 0.12)
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppTheme.primary
                : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.my_location_rounded : Icons.location_on_outlined,
              size: 15,
              color: active
                  ? AppTheme.primary
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              'Gần bạn',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? AppTheme.primary
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBanner extends ConsumerWidget {
  final UserLocationState location;

  const _PermissionBanner({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlocked =
        location.status == UserLocationStatus.permanentlyDenied ||
        location.status == UserLocationStatus.serviceDisabled;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBlocked
                ? Icons.location_off_rounded
                : Icons.location_searching_rounded,
            size: 18,
            color: isDark ? Colors.white60 : const Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location.message ??
                  'Cần quyền vị trí để hiện Social gần bạn (đang xếp theo giờ).',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : const Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final pin = await SocialLocationPicker.show(
                context,
                initialCenter: const LatLng(10.7769, 106.7009),
              );
              if (pin != null) {
                ref.read(userLocationProvider.notifier)
                    .useSelectedPosition(pin.latitude, pin.longitude);
              }
            },
            child: const Text('Chọn trên bản đồ'),
          ),
          TextButton(
            onPressed: () => _onBannerAction(ref, isBlocked),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(isBlocked ? 'Mở cài đặt' : 'Thử lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _onBannerAction(WidgetRef ref, bool isBlocked) async {
    final notifier = ref.read(userLocationProvider.notifier);
    if (!isBlocked) {
      await notifier.requestWhenInUse();
      return;
    }
    if (location.status == UserLocationStatus.serviceDisabled) {
      await notifier.openSystemSettings();
    } else {
      await notifier.openAppLocationSettings();
    }
  }
}
