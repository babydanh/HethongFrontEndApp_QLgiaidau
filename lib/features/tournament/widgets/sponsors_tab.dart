import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class SponsorsTab extends StatelessWidget {
  final List<TournamentSponsor> sponsors;

  const SponsorsTab({super.key, required this.sponsors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final sorted = [...sponsors]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.handshake_outlined, color: colors.warning),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.sponsorsDescription,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...sorted.map((sponsor) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SponsorCard(sponsor: sponsor),
              )),
        ],
      ),
    );
  }
}

class _SponsorCard extends StatelessWidget {
  final TournamentSponsor sponsor;

  const _SponsorCard({required this.sponsor});

  String _tierLabel(AppLocalizations l10n) {
    switch (sponsor.tier) {
      case 'TITLE':
        return l10n.sponsorTierTitle;
      case 'DIAMOND':
        return l10n.sponsorTierDiamond;
      case 'SILVER':
        return l10n.sponsorTierSilver;
      case 'BRONZE':
        return l10n.sponsorTierBronze;
      case 'IN_KIND':
        return l10n.sponsorTierInKind;
      case 'GOLD':
      default:
        return l10n.sponsorTierGold;
    }
  }

  Future<void> _openWebsite() async {
    final value = sponsor.websiteUrl;
    if (value == null || value.isEmpty) return;
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final hasWebsite = sponsor.websiteUrl != null && sponsor.websiteUrl!.isNotEmpty;

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.bgDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              sponsor.logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.business_outlined,
                color: colors.textSecondary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tierLabel(l10n),
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sponsor.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (sponsor.shortDescription != null &&
                    sponsor.shortDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sponsor.shortDescription!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
                if (hasWebsite) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.sponsorVisitWebsite,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasWebsite)
            Icon(Icons.open_in_new_rounded, color: AppTheme.primary, size: 18),
        ],
      ),
    );

    return hasWebsite
        ? InkWell(
            onTap: _openWebsite,
            borderRadius: BorderRadius.circular(16),
            child: card,
          )
        : card;
  }
}
