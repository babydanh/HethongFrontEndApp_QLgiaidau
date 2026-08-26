import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

const _kTierOrder = [
  'TITLE',
  'DIAMOND',
  'GOLD',
  'SILVER',
  'BRONZE',
  'IN_KIND',
];

class _TierStyle {
  final Color accent;
  final Color border;
  final Color background;
  final Color badgeBg;
  final Color badgeText;

  const _TierStyle({
    required this.accent,
    required this.border,
    required this.background,
    required this.badgeBg,
    required this.badgeText,
  });
}

_TierStyle _getTierStyle(String tier, bool isDark) {
  switch (tier) {
    case 'TITLE':
      return _TierStyle(
        accent: const Color(0xFF7C3AED),
        border: isDark ? const Color(0xFF5B21B6) : const Color(0xFFDDD6FE),
        background: isDark
            ? const Color(0xFF2E1065).withValues(alpha: 0.3)
            : const Color(0xFFF5F3FF),
        badgeBg: isDark ? const Color(0xFF4C1D95) : const Color(0xFFEDE9FE),
        badgeText: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF6D28D9),
      );
    case 'DIAMOND':
      return _TierStyle(
        accent: const Color(0xFF0891B2),
        border: isDark ? const Color(0xFF155E75) : const Color(0xFFA5F3FC),
        background: isDark
            ? const Color(0xFF083344).withValues(alpha: 0.3)
            : const Color(0xFFECFEFF),
        badgeBg: isDark ? const Color(0xFF164E63) : const Color(0xFFCFFAFE),
        badgeText: isDark ? const Color(0xFFA5F3FC) : const Color(0xFF0E7490),
      );
    case 'GOLD':
      return _TierStyle(
        accent: const Color(0xFFD97706),
        border: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
        background: isDark
            ? const Color(0xFF451A03).withValues(alpha: 0.3)
            : const Color(0xFFFFFBEB),
        badgeBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
        badgeText: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
      );
    case 'SILVER':
      return _TierStyle(
        accent: const Color(0xFF64748B),
        border: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        background: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.3)
            : const Color(0xFFF8FAFC),
        badgeBg: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        badgeText: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
      );
    case 'BRONZE':
      return _TierStyle(
        accent: const Color(0xFFEA580C),
        border: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFED7AA),
        background: isDark
            ? const Color(0xFF431407).withValues(alpha: 0.3)
            : const Color(0xFFFFFAF0),
        badgeBg: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
        badgeText: isDark ? const Color(0xFFFED7AA) : const Color(0xFFC2410C),
      );
    case 'IN_KIND':
    default:
      return _TierStyle(
        accent: const Color(0xFF059669),
        border: isDark ? const Color(0xFF064E3B) : const Color(0xFFA7F3D0),
        background: isDark
            ? const Color(0xFF022C22).withValues(alpha: 0.3)
            : const Color(0xFFECFDF5),
        badgeBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
        badgeText: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
      );
  }
}

String _getTierLabel(String tier, AppLocalizations l10n) {
  switch (tier) {
    case 'TITLE':
      return l10n.sponsorTierTitle;
    case 'DIAMOND':
      return l10n.sponsorTierDiamond;
    case 'GOLD':
      return l10n.sponsorTierGold;
    case 'SILVER':
      return l10n.sponsorTierSilver;
    case 'BRONZE':
      return l10n.sponsorTierBronze;
    case 'IN_KIND':
    default:
      return l10n.sponsorTierInKind;
  }
}

class SponsorsTab extends StatelessWidget {
  final List<TournamentSponsor> sponsors;

  const SponsorsTab({super.key, required this.sponsors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group sponsors by Tier according to kTierOrder
    final groups = _kTierOrder.map((tier) {
      final list = sponsors.where((s) => s.tier == tier).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return (tier: tier, sponsors: list);
    }).where((group) => group.sponsors.isNotEmpty).toList();

    // Catch any unrecognized tiers not in kTierOrder
    final otherSponsors = sponsors
        .where((s) => !_kTierOrder.contains(s.tier))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    if (otherSponsors.isNotEmpty) {
      groups.add((tier: 'IN_KIND', sponsors: otherSponsors));
    }

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 48,
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.sponsorsTitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.handshake_outlined, color: colors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sponsorsTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.sponsorsDescription,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sponsor Groups by Tier
          ...groups.map((group) {
            final tierStyle = _getTierStyle(group.tier, isDark);
            final isFeatured = group.tier == 'TITLE' || group.tier == 'DIAMOND';

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier Header Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: tierStyle.border.withValues(alpha: 0.8),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: tierStyle.badgeBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: tierStyle.border, width: 1),
                          ),
                          child: Text(
                            _getTierLabel(group.tier, l10n).toUpperCase(),
                            style: TextStyle(
                              color: tierStyle.badgeText,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: tierStyle.border.withValues(alpha: 0.8),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Responsive Grid of neat sponsor cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isFeatured ? 2 : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isFeatured ? 1.4 : 1.6,
                    ),
                    itemCount: group.sponsors.length,
                    itemBuilder: (context, index) {
                      final sponsor = group.sponsors[index];
                      return _SponsorLogoCard(
                        sponsor: sponsor,
                        tierStyle: tierStyle,
                        isFeatured: isFeatured,
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SponsorLogoCard extends StatelessWidget {
  final TournamentSponsor sponsor;
  final _TierStyle tierStyle;
  final bool isFeatured;

  const _SponsorLogoCard({
    required this.sponsor,
    required this.tierStyle,
    required this.isFeatured,
  });

  Future<void> _openWebsite() async {
    final value = sponsor.websiteUrl;
    if (value == null || value.isEmpty) return;
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get _initials {
    final parts = sponsor.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'SP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasWebsite =
        sponsor.websiteUrl != null && sponsor.websiteUrl!.isNotEmpty;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? colors.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tierStyle.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tierStyle.accent.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Frame
          Expanded(
            child: Center(
              child: sponsor.logoUrl.isNotEmpty
                  ? Image.network(
                      sponsor.logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackInitials(),
                    )
                  : _buildFallbackInitials(),
            ),
          ),
          const SizedBox(height: 6),

          // Name and Website icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  sponsor.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: isFeatured ? 12 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasWebsite) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 11,
                  color: tierStyle.accent,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (hasWebsite) {
      return InkWell(
        onTap: _openWebsite,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }

  Widget _buildFallbackInitials() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: tierStyle.badgeBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: tierStyle.badgeText,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
