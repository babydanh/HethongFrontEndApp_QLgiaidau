import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';

class IntroTab extends StatelessWidget {
  final Tournament tournament;
  final String Function(String? url)? resolveImageUrl;

  const IntroTab({
    super.key,
    required this.tournament,
    this.resolveImageUrl,
  });

  String _resolve(String? url) {
    if (url == null || url.isEmpty) return '';
    if (resolveImageUrl != null) return resolveImageUrl!(url);
    if (url.startsWith('http')) return url;
    return 'https://sporto.asia$url';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = tournament;
    final desc = t.description.trim();
    final hasPrize = !t.isClubLite &&
        t.prizeDescription != null &&
        t.prizeDescription!.trim().isNotEmpty;

    final creatorName = t.creatorFullName ?? 'Ban tổ chức';
    final resolvedAvatar = _resolve(t.creatorAvatarUrl);

    final hasContent = desc.isNotEmpty || hasPrize;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── THÔNG TIN GIỚI THIỆU ───
          if (desc.isNotEmpty) ...[
            _buildSectionHeader(context, 'THÔNG TIN GIỚI THIỆU'),
            const SizedBox(height: 10),
            _buildHtmlContent(context, desc),
          ],

          // ─── CƠ CẤU GIẢI THƯỞNG ───
          if (hasPrize) ...[
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(
                color: colors.border.withValues(alpha: 0.6),
                height: 1,
              ),
              const SizedBox(height: 16),
            ],
            _buildSectionHeader(context, 'CƠ CẤU GIẢI THƯỞNG'),
            const SizedBox(height: 10),
            _buildHtmlContent(context, t.prizeDescription!.trim()),
          ],

          // Nếu không có nội dung giới thiệu
          if (!hasContent) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 40,
                    color: colors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ban tổ chức chưa cập nhật thông tin giới thiệu chi tiết cho giải đấu này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── THÔNG TIN BAN TỔ CHỨC / NGƯỜI SÁNG LẬP ───
          if (resolvedAvatar.isNotEmpty || creatorName.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(
              color: colors.border.withValues(alpha: 0.6),
              height: 1,
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'BAN TỔ CHỨC GIẢI ĐẤU'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    backgroundImage: resolvedAvatar.isNotEmpty
                        ? NetworkImage(resolvedAvatar)
                        : null,
                    child: resolvedAvatar.isEmpty
                        ? Text(
                            creatorName.isNotEmpty
                                ? creatorName[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontSize: 14,
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
                        Text(
                          creatorName.isNotEmpty
                              ? creatorName
                              : 'Ban tổ chức giải đấu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Người sáng lập giải đấu',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: context.colors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildHtmlContent(BuildContext context, String text) {
    final colors = context.colors;
    final isHtml = text.contains('<') && text.contains('>');
    if (isHtml) {
      return HtmlWidget(
        text,
        textStyle: TextStyle(
          fontSize: 13.5,
          color: colors.textSecondary,
          height: 1.55,
        ),
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        color: colors.textSecondary,
        height: 1.55,
      ),
    );
  }
}
