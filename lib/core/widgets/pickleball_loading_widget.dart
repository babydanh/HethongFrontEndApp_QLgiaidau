import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_loading_widget.dart';

class PickleballLoadingWidget extends StatelessWidget {
  final double size;
  final String? message;
  final Color? textColor;
  final SportoLoadingVariant variant;

  const PickleballLoadingWidget({
    super.key,
    this.size = 80,
    this.message,
    this.textColor,
    this.variant = SportoLoadingVariant.orbit,
  });

  @override
  Widget build(BuildContext context) {
    return SportoLoadingWidget(
      size: size,
      message: message,
      textColor: textColor,
      variant: variant,
    );
  }
}

