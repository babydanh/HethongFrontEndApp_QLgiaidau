import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/countdown_timer.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class AboutTab extends StatelessWidget {
  final Tournament tournament;
  final int teamCount;
  final String Function(String? url) resolveImageUrl;
  final ScrollController? scrollController;

  const AboutTab({
    super.key,
    required this.tournament,
    required this.teamCount,
    required this.resolveImageUrl,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final resolvedAvatar = resolveImageUrl(tournament.creatorAvatarUrl);
    final creatorName = tournament.creatorFullName ?? l10n.organizerName;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        children: [
          // ─── Main Info Card ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── BTC Section ──
                _buildSectionHeader(colors, l10n.sectionOrganizer),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      backgroundImage: resolvedAvatar.isNotEmpty
                          ? NetworkImage(resolvedAvatar)
                          : null,
                      child: resolvedAvatar.isEmpty
                          ? Text(
                              creatorName.isNotEmpty ? creatorName[0].toUpperCase() : 'B',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                creatorName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.border.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.newlyCreated,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.tournamentFounder,
                            style: TextStyle(fontSize: 13, color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionDivider(colors),
                const SizedBox(height: 16),

                // ── Description Section ──
                if (tournament.description.isNotEmpty) ...[
                  _buildSectionHeader(colors, l10n.sectionAboutTournament),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: HtmlWidget(
                        _convertEditorJsOrHtmlToHtml(tournament.description),
                        textStyle: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                        customStylesBuilder: (element) {
                          if (element.localName == 'img') {
                            return {
                              'max-width': '100%',
                              'height': 'auto',
                              'border-radius': '8px',
                              'display': 'block',
                              'margin': '8px auto',
                            };
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionDivider(colors),
                  const SizedBox(height: 16),
                ],

                // ── Countdown (if upcoming) ──
                if (StatusHelper.isTournamentUpcoming(tournament.status) &&
                    tournament.registrationStartDate != null) ...[
                  CountdownTimer(
                    targetDate: tournament.registrationStartDate!,
                    compact: false,
                  ),
                  const SizedBox(height: 16),
                  _sectionDivider(colors),
                  const SizedBox(height: 16),
                ],

                // ── Tournament Info Section ──
                _buildSectionHeader(colors, l10n.sectionTournamentInfo),
                const SizedBox(height: 12),
                _buildInfoRow(
                  label: l10n.sportLabel,
                  value: AppConstants.sportNames[tournament.sport] ?? tournament.sport,
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  label: l10n.formatLabel,
                  value: AppConstants.formatNames[tournament.format] ??
                      tournament.format.replaceAll('_', ' '),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  label: l10n.bracketTypeLabel,
                  value: AppConstants.bracketTypeNames[tournament.bracketType] ??
                      tournament.bracketType,
                  colors: colors,
                ),
                if (tournament.bracketType != AppConstants.bracketRoundRobin) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: l10n.maxTeamsLabel,
                    value: '${tournament.maxTeams} ${l10n.teamsUnit}',
                    colors: colors,
                  ),
                ],
                const SizedBox(height: 16),
                _sectionDivider(colors),
                const SizedBox(height: 16),

                // ── Prize Section (merged into About) ──
                if (tournament.prizeDescription != null &&
                    tournament.prizeDescription!.trim().isNotEmpty) ...[
                  _buildSectionHeader(
                    colors,
                    l10n.sectionPrize,
                    accentColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tournament.prizeDescription!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionDivider(colors),
                  const SizedBox(height: 16),
                ],

                // ── Contact Section ──
                _buildSectionHeader(colors, l10n.sectionContact),
                const SizedBox(height: 12),
                _buildContactCard(tournament.contactInfo, colors, l10n),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Registration Info Card ───
          if (tournament.registrationStartDate != null ||
              tournament.entryFee != null) ...[
            _buildRegistrationInfoCard(context, tournament),
            const SizedBox(height: 100),
          ] else
            const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    AppColorsExtension colors,
    String title, {
    Color? accentColor,
  }) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accentColor ?? AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _sectionDivider(AppColorsExtension colors) {
    return Container(
      height: 1,
      color: colors.border.withValues(alpha: 0.5),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required AppColorsExtension colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
      Map<String, dynamic>? contactInfo, AppColorsExtension colors, AppLocalizations l10n) {
    if (contactInfo == null || contactInfo.isEmpty) {
      return Text(
        l10n.notUpdated,
        style: TextStyle(fontSize: 13, color: colors.textSecondary),
      );
    }

    final items = <Widget>[];
    void addItem(IconData icon, String? value, String label,
        {String? action}) {
      if (value == null || value.toString().trim().isEmpty) return;
      items.add(
        InkWell(
          onTap: action != null ? () => _launchUrl(action) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
              ],
            ),
          ),
        ),
      );
    }

    addItem(Icons.phone_rounded, contactInfo['phone']?.toString(), 'Phone',
        action: contactInfo['phone'] != null
            ? 'tel:${contactInfo['phone']}'
            : null);
    addItem(Icons.email_rounded, contactInfo['email']?.toString(), 'Email',
        action: contactInfo['email'] != null
            ? 'mailto:${contactInfo['email']}'
            : null);
    addItem(Icons.chat_rounded, contactInfo['zalo']?.toString(), 'Zalo',
        action: contactInfo['zalo'] != null
            ? 'https://zalo.me/${contactInfo['zalo']}'
            : null);
    addItem(
        Icons.facebook_rounded,
        contactInfo['facebook']?.toString(),
        'Facebook',
        action: contactInfo['facebook']?.toString() != null
            ? contactInfo['facebook'].toString()
            : null);

    if (items.isEmpty) {
      return Text(
        l10n.notUpdated,
        style: TextStyle(fontSize: 13, color: colors.textSecondary),
      );
    }

    return Column(children: items);
  }

  Widget _buildRegistrationInfoCard(
      BuildContext context, Tournament tournament) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final slotsFilled = tournament.maxTeams > 0
        ? tournament.divisions
            .fold<int>(0, (sum, d) => sum + d.participantCount)
        : 0;
    final isRegistrationOpen =
        StatusHelper.isTournamentRegistration(tournament.status) ||
            StatusHelper.isTournamentUpcoming(tournament.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(colors, l10n.sectionRegistration),
          const SizedBox(height: 16),
          // Entry fee
          if (tournament.entryFee != null && tournament.entryFee! > 0) ...[
            _buildRegInfoRow(l10n.entryFeeLabel,
                '${tournament.entryFee!.toStringAsFixed(0)} ${l10n.vnd}', colors),
            const SizedBox(height: 12),
          ] else if (tournament.entryFee != null && tournament.entryFee! == 0) ...[
            _buildRegInfoRow(l10n.entryFeeLabel, l10n.freePrice, colors),
            const SizedBox(height: 12),
          ],
          // Max participants
          _buildRegInfoRow(l10n.maxQuantityLabel, '${tournament.maxTeams} ${l10n.teamsUnit}',
              colors),
          const SizedBox(height: 12),
          // Registration period
          if (tournament.registrationStartDate != null) ...[
            _buildRegInfoRow(
              l10n.registrationOpen,
              _formatDate(tournament.registrationStartDate!),
              colors,
            ),
            const SizedBox(height: 8),
          ],
          if (tournament.registrationEndDate != null) ...[
            _buildRegInfoRow(
              l10n.registrationClose,
              _formatDate(tournament.registrationEndDate!),
              colors,
            ),
            const SizedBox(height: 16),
          ],
          // Slot progress bar
          if (tournament.maxTeams > 0) ...[
            _buildSlotProgressBar(slotsFilled, tournament.maxTeams, colors, l10n),
            const SizedBox(height: 16),
          ],
          // Countdown & Register button
          if (isRegistrationOpen) ...[
            if (tournament.registrationStartDate != null &&
                tournament.registrationStartDate!
                    .isAfter(DateTime.now()))
              CountdownTimer(
                targetDate: tournament.registrationStartDate!,
                compact: false,
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: () =>
                      context.push('/register/${tournament.id}'),
                  child: Text(
                    l10n.register,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ] else if (tournament.registrationEndDate != null &&
              tournament.registrationEndDate!
                  .isBefore(DateTime.now())) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_off_rounded,
                      size: 18, color: colors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    l10n.registrationEnded,
                    style: TextStyle(fontSize: 14, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegInfoRow(
      String label, String value, AppColorsExtension colors) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotProgressBar(
      int filled, int max, AppColorsExtension colors, AppLocalizations l10n) {
    final ratio = max > 0 ? filled / max : 0.0;
    final progressColor = ratio >= 0.9
        ? colors.error
        : ratio >= 0.7
            ? colors.warning
            : colors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${l10n.registeredSlots} $filled / $max',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const Spacer(),
            Text(
              '${(ratio * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: progressColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _convertEditorJsOrHtmlToHtml(String raw) {
    if (raw.trim().isEmpty) return '';
    final trimmed = raw.trim();

    // Thử parse nếu là dữ liệu JSON Blocks từ Editor.js
    if (trimmed.startsWith('{') && trimmed.contains('"blocks"')) {
      try {
        final Map<String, dynamic> json = jsonDecode(trimmed);
        final blocks = json['blocks'] as List?;
        if (blocks != null && blocks.isNotEmpty) {
          final buffer = StringBuffer();
          for (final block in blocks) {
            final type = block['type'];
            final data = block['data'] as Map?;
            if (data == null) continue;

            if (type == 'header') {
              final level = data['level'] ?? 2;
              buffer.write('<h$level style="margin:8px 0;font-weight:bold;">${data['text'] ?? ''}</h$level>');
            } else if (type == 'paragraph') {
              buffer.write('<p style="margin:6px 0;">${data['text'] ?? ''}</p>');
            } else if (type == 'image') {
              final url = data['file']?['url'] ?? data['url'];
              final caption = data['caption'] ?? '';
              if (url != null && url.toString().isNotEmpty) {
                buffer.write('<div style="text-align:center;margin:12px 0;"><img src="$url" alt="$caption" style="max-width:100%;border-radius:8px;" />');
                if (caption.toString().isNotEmpty) {
                  buffer.write('<p style="font-size:11px;color:#888;margin-top:4px;">$caption</p>');
                }
                buffer.write('</div>');
              }
            } else if (type == 'list') {
              final style = data['style'] == 'ordered' ? 'ol' : 'ul';
              final items = data['items'] as List?;
              if (items != null) {
                buffer.write('<$style style="padding-left:20px;margin:6px 0;">');
                for (final item in items) {
                  buffer.write('<li>$item</li>');
                }
                buffer.write('</$style>');
              }
            } else if (type == 'raw' || type == 'quote') {
              buffer.write('<blockquote style="border-left:3px solid #0066FF;padding-left:8px;margin:8px 0;color:#555;">${data['text'] ?? data['html'] ?? ''}</blockquote>');
            }
          }
          final result = buffer.toString();
          if (result.isNotEmpty) return result;
        }
      } catch (_) {}
    }

    return raw;
  }
}
