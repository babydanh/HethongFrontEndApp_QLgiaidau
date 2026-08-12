import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

class CommunityComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback? onPickImage;
  final int imageCount;

  const CommunityComposer({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    this.onPickImage,
    this.imageCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: colors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          children: [
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Chia sẻ điều gì đó với CLB…',
                border: InputBorder.none,
              ),
            ),
            const Divider(height: AppTheme.spacingMD),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 19),
                  label: Text(imageCount > 0 ? 'Ảnh $imageCount' : 'Ảnh'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.local_offer_outlined, size: 19),
                  label: const Text('Gắn thẻ'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  child: isSubmitting
                      ? const SizedBox.square(dimension: 17, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Đăng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
