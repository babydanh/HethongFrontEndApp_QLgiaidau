import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class TeamsEmptyView extends StatelessWidget {
  const TeamsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_rounded,
              size: 64,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              "Chưa có VĐV đăng ký",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Hãy kiểm tra lại sau khi giải đấu mở đăng ký",
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
