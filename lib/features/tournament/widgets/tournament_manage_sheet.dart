import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Khung bottom sheet dùng chung cho các sheet quản lý giải đấu
/// (OpenSpec `quan-ly-giai-web-parity`): tiêu đề cố định + thân cuộn +
/// thanh thao tác sticky, chiếm [heightFactor] chiều cao màn hình.
///
/// Khi [busy]: mọi nút trên thanh thao tác bị khoá (chống double-tap), nút
/// đầu tiên hiện spinner và sheet không cho đóng (`PopScope` chặn pop).
/// Tiêu đề do nơi gọi truyền vào, không dùng key l10n.
class TournamentManageSheet extends StatelessWidget {
  const TournamentManageSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.busy = false,
    this.heightFactor = 0.92,
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 8, 20, 16),
  }) : assert(heightFactor > 0 && heightFactor <= 1);

  /// Tiêu đề sheet.
  final String title;

  /// Thân sheet, nằm trong khu vực cuộn.
  final Widget child;

  /// Các nút trên thanh thao tác sticky; nút đầu tiên là nút chính
  /// (hiện spinner khi [busy]).
  final List<Widget>? actions;

  /// Đang xử lý: khoá nút, hiện spinner, chặn đóng sheet qua `PopScope`
  /// (barrier/back). Lưu ý kéo xuống và drag handle dismiss đều gọi thẳng
  /// `Navigator.pop` (bypass `PopScope`) — nơi gọi tự mở sheet qua
  /// `showModalBottomSheet` thì truyền `enableDrag: false` và
  /// `showDragHandle: false` khi busy (helper [show] đã tự làm theo busy
  /// lúc mở).
  final bool busy;

  /// Tỉ lệ chiều cao sheet so với màn hình.
  final double heightFactor;

  /// Padding quanh thân cuộn (mặc định 20 hai bên).
  final EdgeInsets bodyPadding;

  /// Mở sheet một dòng theo quy ước app: full-height control, drag handle
  /// (khi không busy), tối rộng 640, bo góc trên. Trả về kết quả `T?` khi
  /// sheet pop có giá trị.
  ///
  /// [busy] là snapshot chụp MỘT LẦN lúc mở sheet: `enableDrag: !busy`,
  /// `showDragHandle: !busy` và trạng thái khung đều lấy giá trị lúc gọi —
  /// cha đổi `busy` sau khi mở không tự cập nhật lên sheet. Kéo xuống và
  /// drag handle đều gọi thẳng `Navigator.pop` (bypass `PopScope`), nên
  /// nơi gọi cần truyền `busy: true` vào helper khi mở sheet ở trạng thái
  /// bận, hoặc đóng/mở lại sheet sau khi đổi state — không đổi được
  /// `enableDrag`/`showDragHandle` từ builder (tham số route chốt lúc push).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool busy = false,
    double heightFactor = 0.92,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      // Kéo xuống và drag handle đều gọi thẳng Navigator.pop (bypass
      // PopScope); handle còn có gesture detector riêng khi enableDrag tắt,
      // nên tắt cả hai khi mở sheet ở trạng thái busy.
      enableDrag: !busy,
      showDragHandle: !busy,
      builder: (_) => TournamentManageSheet(
        title: title,
        actions: actions,
        busy: busy,
        heightFactor: heightFactor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actionList = actions;
    return PopScope(
      canPop: !busy,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: heightFactor,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SizedBox.expand(
                  child: Material(
                    key: const ValueKey('tournament-manage-sheet'),
                    color: colors.bgCard,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('tournament-manage-sheet-body'),
                            padding: bodyPadding,
                            child: child,
                          ),
                        ),
                        if (actionList != null && actionList.isNotEmpty)
                          _buildActionBar(context, actionList),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('tournament-manage-sheet-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: busy ? null : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, List<Widget> actionList) {
    final colors = context.colors;
    final items = <Widget>[];
    for (var index = 0; index < actionList.length; index++) {
      items.add(_wrapAction(actionList[index], primary: index == 0));
      if (index < actionList.length - 1) items.add(const SizedBox(width: 8));
    }
    return Container(
      key: const ValueKey('tournament-manage-sheet-actions'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      // OverflowBar thay Row: nút dài tiếng Việt trên màn hẹp tự xuống hàng
      // thay vì tràn ngang (RenderFlex overflow).
      child: OverflowBar(
        alignment: MainAxisAlignment.end,
        spacing: 8,
        overflowSpacing: 8,
        children: items,
      ),
    );
  }

  /// Khi [busy]: khoá nút (bỏ qua pointer, mờ đi); nút chính được phủ
  /// spinner 16px strokeWidth 2 theo pattern nút của app.
  Widget _wrapAction(Widget action, {required bool primary}) {
    if (!busy) return action;
    Widget wrapped = IgnorePointer(child: Opacity(opacity: 0.6, child: action));
    if (primary) {
      wrapped = Stack(
        alignment: Alignment.center,
        children: [
          wrapped,
          const SizedBox.square(
            key: ValueKey('tournament-manage-sheet-busy-spinner'),
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }
    return wrapped;
  }
}

/// Lấy thông điệp lỗi server (Dio `message`) hiển thị nguyên văn trong các
/// sheet quản lý giải; null khi lỗi không mang message hiển thị được.
String? tournamentSheetServerMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        final first = message.first;
        if (first is String && first.trim().isNotEmpty) return first;
      }
    }
  }
  return null;
}
