part of '../screens/club_detail_screen.dart';

//  TAB BAR DELEGATE
// ═══════════════════════════════════════════
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;
  final ValueChanged<String>? onMoreSelected;

  static const double _tabBarHeight = 44.0;

  _TabBarDelegate({
    required this.tabController,
    required this.colors,
    this.onMoreSelected,
  });

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      // color: colors.bgCard,
      height: _tabBarHeight,
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            final activeIndex = tabController.index;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabItem(
                  index: 0,
                  label: l10n.clubDetailFeedTab,
                  isActive: activeIndex == 0,
                  colors: colors,
                ),
                const SizedBox(width: 14),
                _buildTabItem(
                  index: 1,
                  label: 'Thi đấu',
                  isActive: activeIndex == 1,
                  colors: colors,
                ),
                const SizedBox(width: 14),
                _buildTabItem(
                  index: 2,
                  label: l10n.club_tabMembers,
                  isActive: activeIndex == 2,
                  colors: colors,
                ),
                const SizedBox(width: 14),
                _buildMoreTabButton(context, colors, l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required bool isActive,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: () => tabController.animateTo(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: _tabBarHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? AppTheme.primary : const Color(0xFF64748B),
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: 2.5,
              width: 24.0,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreTabButton(
      BuildContext context,
      AppColorsExtension colors,
      AppLocalizations l10n,
      ) {
    return SizedBox(
      height: _tabBarHeight,
      child: PopupMenuButton<String>(
        tooltip: 'Xem thêm',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        onSelected: onMoreSelected,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xem thêm',
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 1),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'tourneys',
            height: 40,
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.club_tabTournaments,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'gallery',
            height: 40,
            child: Row(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.club_tabGallery,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: colors.textPrimary,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.club_tabSettings,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => _tabBarHeight;

  @override
  double get minExtent => _tabBarHeight;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController ||
        oldDelegate.colors != colors;
  }
}

/// Chỉ khởi tạo tab nặng khi tab đó thực sự được chọn.
///
/// `TabBarView` vẫn cần một child cho từng trang để giữ layout, nhưng các
/// widget bên trong (socket, timer, ranking request) không nên chạy ngay khi
/// người dùng chỉ đang xem Bảng tin.
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
class _AthleticBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Diagonal sweep line (thick)
    final sweepPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-20, h + 20), Offset(w * 0.75, -20), sweepPaint);

    // Diagonal thin line
    final thinLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(10, h + 10), Offset(w * 0.85, -15), thinLinePaint);

    // Court border
    final courtPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final courtRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, 12, w - 32, h - 24),
      const Radius.circular(8),
    );
    canvas.drawRRect(courtRect, courtPaint);

    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.36, courtPaint);

    // Center dashed line
    final centerLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w / 2, 12), Offset(w / 2, h - 12), centerLinePaint);

    // Corner accents
    final accentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Top-left corner
    final pathTl = Path()
      ..moveTo(16, 28)
      ..lineTo(16, 12)
      ..lineTo(32, 12);
    canvas.drawPath(pathTl, accentPaint);

    // Bottom-right corner
    final pathBr = Path()
      ..moveTo(w - 16, h - 28)
      ..lineTo(w - 16, h - 12)
      ..lineTo(w - 32, h - 12);
    canvas.drawPath(pathBr, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Form tham gia CLB được tách thành một route widget độc lập.
///
/// `showDialog` hoàn tất Future ngay khi Navigator nhận lệnh pop, nhưng route
/// còn reverse transition. Vì vậy controller phải được sở hữu bởi State của
/// dialog và chỉ dispose trong `State.dispose`, sau khi route đã tháo xong.
class _JoinQuestionsDialog extends StatefulWidget {
  final List<String> questions;
  final String title;
  final String instruction;
  final String requiredMessage;
  final String cancelLabel;
  final String submitLabel;

  const _JoinQuestionsDialog({
    required this.questions,
    required this.title,
    required this.instruction,
    required this.requiredMessage,
    required this.cancelLabel,
    required this.submitLabel,
  });

  @override
  State<_JoinQuestionsDialog> createState() => _JoinQuestionsDialogState();
}

class _JoinQuestionsDialogState extends State<_JoinQuestionsDialog> {
  late final List<TextEditingController> _controllers;
  late final List<String?> _validationErrors;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = widget.questions
        .map((_) => TextEditingController())
        .toList(growable: false);
    _validationErrors = List<String?>.filled(widget.questions.length, null);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _close([Map<String, dynamic>? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    var isValid = true;
    for (var i = 0; i < _controllers.length; i++) {
      final isEmpty = _controllers[i].text.trim().isEmpty;
      _validationErrors[i] = isEmpty ? widget.requiredMessage : null;
      if (isEmpty) isValid = false;
    }
    if (!isValid) {
      setState(() {});
      return;
    }

    final result = <String, dynamic>{
      for (var i = 0; i < widget.questions.length; i++)
        widget.questions[i]: _controllers[i].text.trim(),
    };
    setState(() => _isSubmitting = true);

    // Cho TextField/FocusScope hoàn tất frame hiện tại trước khi tháo route.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _close(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.instruction),
            const SizedBox(height: 16),
            ...List.generate(
              widget.questions.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[index],
                  maxLines: 2,
                  onChanged: (_) {
                    if (_validationErrors[index] != null) {
                      setState(() => _validationErrors[index] = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: widget.questions[index],
                    border: const OutlineInputBorder(),
                    errorText: _validationErrors[index],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _close,
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
