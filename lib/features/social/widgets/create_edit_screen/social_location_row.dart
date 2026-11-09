import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SocialLocationRow extends StatelessWidget {
  const SocialLocationRow({
    super.key,
    required this.place,
    required this.onTap,
    this.errorText,
  });

  final SocialPlace? place;
  final VoidCallback onTap;

  /// When set, the row turns red and the message is shown under it.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final selected = place;
    final name = selected?.name.trim() ?? '';
    final address = selected?.isDeferred == true
        ? ''
        : selected?.formattedAddress.trim() ?? '';

    final error = errorText;
    final row = Semantics(
      button: true,
      label: name.isEmpty ? l10n.socialPlaceSelect : '$name, $address',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: error == null ? AppTheme.primary : colors.error,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: name.isEmpty
                    ? Text(
                        l10n.socialPlaceSelect,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (address.isNotEmpty)
                            Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
    if (error == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(error, style: TextStyle(fontSize: 12, color: colors.error)),
        ),
      ],
    );
  }
}
