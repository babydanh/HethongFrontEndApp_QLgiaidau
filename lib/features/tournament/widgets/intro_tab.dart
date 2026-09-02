import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class IntroTab extends StatelessWidget {
  final Tournament tournament;
  final String Function(String? url) resolveImageUrl;

  const IntroTab({
    super.key,
    required this.tournament,
    required this.resolveImageUrl,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(double? amount) {
    if (amount == null || amount <= 0) return 'Miễn phí';
    final fmt = NumberFormat('#,###', 'vi_VN');
    return '${fmt.format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final colors = context.colors;
    final desc = t.description.trim();
    final resolvedAvatar = resolveImageUrl(t.creatorAvatarUrl);
    final creatorName = t.creatorFullName ?? 'Ban tổ chức';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. BAN TỔ CHỨC ───
          _buildSectionHeader(context, 'BAN TỔ CHỨC & ĐƠN VỊ VẬN HÀNH'),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.bgSurface,
                backgroundImage: resolvedAvatar.isNotEmpty
                    ? NetworkImage(resolvedAvatar)
                    : null,
                child: resolvedAvatar.isEmpty
                    ? Text(
                        creatorName.isNotEmpty
                            ? creatorName[0].toUpperCase()
                            : 'B',
                        style: TextStyle(
                          fontSize: 15,
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
                      creatorName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Đơn vị tổ chức chuyên nghiệp',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 20),

          // ─── 2. THÔNG TIN CHI TIẾT / MÔ TẢ GIẢI ĐẤU ───
          if (desc.isNotEmpty) ...[
            _buildSectionHeader(context, 'THÔNG TIN GIỚI THIỆU GIẢI ĐẤU'),
            const SizedBox(height: 10),
            _buildDescriptionContent(context, desc),
            const SizedBox(height: 20),
            Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 20),
          ],

          // ─── 3. THÔNG TIN ĐĂNG KÝ & LỆ PHÍ ───
          _buildSectionHeader(context, 'THỜI GIAN ĐĂNG KÝ & LỆ PHÍ'),
          const SizedBox(height: 12),
          _buildMetaRow(context, 'Mở đăng ký:', _formatDate(t.registrationStartDate)),
          const SizedBox(height: 8),
          _buildMetaRow(context, 'Hạn chót đăng ký:', _formatDate(t.registrationEndDate)),
          const SizedBox(height: 8),
          _buildMetaRow(
            context,
            'Lệ phí tham gia:',
            _formatCurrency(t.entryFee),
            isFee: true,
          ),
          const SizedBox(height: 20),
          Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 20),

          // ─── 4. CƠ CẤU GIẢI THƯỞNG ───
          if (t.prizeDescription != null && t.prizeDescription!.isNotEmpty) ...[
            _buildSectionHeader(context, 'CƠ CẤU GIẢI THƯỞNG'),
            const SizedBox(height: 10),
            _buildDescriptionContent(context, t.prizeDescription!),
            const SizedBox(height: 20),
            Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 20),
          ],

          // ─── 5. ĐỊA ĐIỂM THI ĐẤU CHI TIẾT ───
          _buildSectionHeader(context, 'ĐỊA ĐIỂM TỔ CHỨC'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (t.venueName != null && t.venueName!.isNotEmpty)
                      Text(
                        t.venueName!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    Text(
                      t.locationAddress ?? t.city ?? 'Chưa cập nhật địa chỉ cụ thể',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildDescriptionContent(BuildContext context, String text) {
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

  Widget _buildMetaRow(
    BuildContext context,
    String label,
    String value, {
    bool isFee = false,
  }) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isFee ? colors.error : colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
