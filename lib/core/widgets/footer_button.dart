import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// A reusable footer button pinned at the bottom of a screen or sheet.
///
/// Renders a full-width [FilledButton] inside a safe-area-aware container
/// with consistent padding, height, and theming across the app.
class FooterButton extends StatelessWidget {
  const FooterButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  /// Button label text.
  final String label;

  /// Called when the button is pressed. Pass `null` to disable the button.
  final VoidCallback? onPressed;

  /// When `true`, shows a loading spinner instead of the label.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}
