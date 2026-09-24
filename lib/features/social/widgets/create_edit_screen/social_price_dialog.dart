import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class SocialPriceDialog extends StatefulWidget {
  const SocialPriceDialog({super.key, required this.initialPrice});

  final int initialPrice;

  static Future<int?> show(BuildContext context, int initialPrice) {
    return showDialog<int>(
      context: context,
      builder: (_) => SocialPriceDialog(initialPrice: initialPrice),
    );
  }

  @override
  State<SocialPriceDialog> createState() => _SocialPriceDialogState();
}

class _SocialPriceDialogState extends State<SocialPriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPrice > 0 ? widget.initialPrice.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      title: Text(
        'Phí tham gia kèo (VNĐ)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Để trống hoặc nhập 0 nếu là kèo miễn phí.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'VD: 50000',
              suffixText: 'VNĐ',
              suffixStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: Text('Miễn phí', style: TextStyle(color: colors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            int.tryParse(_controller.text.trim()) ?? 0,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
