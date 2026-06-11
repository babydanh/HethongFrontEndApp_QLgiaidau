import 'package:flutter/material.dart';

class SportIconWidget extends StatelessWidget {
  final String iconData;
  final double size;

  const SportIconWidget({
    super.key,
    required this.iconData,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (iconData.startsWith('assets/')) {
      return Image.asset(
        iconData,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      return Text(
        iconData,
        style: TextStyle(fontSize: size),
      );
    }
  }
}
