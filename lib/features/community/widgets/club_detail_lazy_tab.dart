part of '../screens/club_detail_screen.dart';

class _LazyClubTab extends StatefulWidget {
  final TabController controller;
  final int index;
  final WidgetBuilder builder;

  const _LazyClubTab({
    required this.controller,
    required this.index,
    required this.builder,
  });

  @override
  State<_LazyClubTab> createState() => _LazyClubTabState();
}

class _LazyClubTabState extends State<_LazyClubTab> {
  late bool _hasBuilt;

  @override
  void initState() {
    super.initState();
    _hasBuilt = widget.controller.index == widget.index;
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_hasBuilt || widget.controller.index != widget.index || !mounted) {
      return;
    }
    setState(() => _hasBuilt = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBuilt) return const SizedBox.expand();
    return widget.builder(context);
  }
}

/// CustomPainter vẽ các đường kẻ sân thể thao & geometric accents cho Banner thể thao
