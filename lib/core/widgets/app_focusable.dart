import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class AppFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AppFocusable({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<AppFocusable> createState() => _AppFocusableState();
}

class _AppFocusableState extends State<AppFocusable> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
              border: _isFocused
                  ? Border.all(color: AppTheme.primary, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
