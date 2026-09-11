part of '../screens/club_detail_screen.dart';

extension _ClubDetailAboutHelpers on _ClubDetailScreenState {
  Widget _buildFbMetaRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorsExtension colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: colors.textPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFbRuleItem({
    required int index,
    required String content,
    required AppColorsExtension colors,
  }) {
    // Tách tiêu đề quy tắc và nội dung quy tắc nếu có ký tự : hoặc -
    String ruleTitle = content;
    String? ruleBody;
    if (content.contains(': ')) {
      final parts = content.split(': ');
      ruleTitle = parts.first;
      ruleBody = parts.sublist(1).join(': ');
    } else if (content.contains(' - ')) {
      final parts = content.split(' - ');
      ruleTitle = parts.first;
      ruleBody = parts.sublist(1).join(' - ');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ruleTitle,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  height: 1.3,
                ),
              ),
              if (ruleBody != null && ruleBody.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  ruleBody.trim(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFbActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorsExtension colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: colors.textPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fbDivider(AppColorsExtension colors) => Divider(
    height: 1,
    thickness: 1,
    color: colors.borderLight.withValues(alpha: 0.6),
  );

  IconData _socialIcon(String key) {
    switch (key.toLowerCase()) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'zalo':
        return Icons.chat_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  String _socialLabel(String key) {
    switch (key.toLowerCase()) {
      case 'facebook':
        return 'Facebook';
      case 'zalo':
        return 'Zalo';
      default:
        return 'Website';
    }
  }

  Future<void> _openSocialLink(String value) async {
    final l10n = AppLocalizations.of(context)!;
    final raw = value.trim();
    final uri = Uri.tryParse(
      raw.startsWith('http://') || raw.startsWith('https://')
          ? raw
          : 'https://$raw',
    );
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailOpenLinkError)));
      }
    }
  }

  // ════════════════════════════════════
  //  TAB 2: GIẢI ĐẤU
  // ════════════════════════════════════
  String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (Platform.isAndroid && trimmed.contains('localhost')) {
        return trimmed.replaceFirst('localhost', '10.0.2.2');
      }
      if (Platform.isAndroid && trimmed.contains('127.0.0.1')) {
        return trimmed.replaceFirst('127.0.0.1', '10.0.2.2');
      }
      return trimmed;
    }
    var apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (Platform.isAndroid && apiBase.contains('localhost')) {
      apiBase = apiBase.replaceFirst('localhost', '10.0.2.2');
    }
    final host = apiBase.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return '${host.replaceFirst(RegExp(r'/$'), '')}/${trimmed.replaceFirst(RegExp(r'^/'), '')}';
  }
}
