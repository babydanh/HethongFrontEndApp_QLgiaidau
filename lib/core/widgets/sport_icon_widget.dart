import 'package:flutter/material.dart';
import 'sport_choice_tile.dart';

class SportIconWidget extends StatelessWidget {
  final String iconData;
  final double size;
  final Color? color;

  const SportIconWidget({
    super.key,
    required this.iconData,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SportChoiceTile.buildSportIcon(
      iconData,
      size,
      color ?? Theme.of(context).iconTheme.color ?? Colors.black,
    );
  }
}
