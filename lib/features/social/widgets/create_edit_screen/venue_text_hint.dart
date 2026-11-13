import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/venue_text_check.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One flat amber line under the venue name / address fields that warns when
/// the two texts look swapped, merged or repeated, with a text button that
/// hands the corrected pair to [onApply]. Renders nothing when all is fine.
class VenueTextHintBar extends StatelessWidget {
  const VenueTextHintBar({
    super.key,
    required this.name,
    required this.address,
    required this.onApply,
  });

  final String name;
  final String address;
  final void Function(String name, String address) onApply;

  @override
  Widget build(BuildContext context) {
    final hint = checkVenueFields(name, address);
    if (hint == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final amber = context.colors.warning;
    final message = switch (hint.code) {
      VenueTextHintCode.nameIsAddress => l10n.venueHintNameIsAddress,
      VenueTextHintCode.nameHasAddress => l10n.venueHintNameHasAddress,
      VenueTextHintCode.addressIsName => l10n.venueHintAddressIsName,
      VenueTextHintCode.addressRepeatsName =>
        l10n.venueHintAddressRepeatsName,
      VenueTextHintCode.sameText => l10n.venueHintSameText,
    };
    final next = hint.next;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: amber,
              ),
            ),
          ),
          if (next != null)
            TextButton(
              onPressed: () => onApply(next.name, next.address),
              style: TextButton.styleFrom(
                foregroundColor: amber,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.filterApply,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
