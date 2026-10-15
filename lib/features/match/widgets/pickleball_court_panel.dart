import 'dart:async';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_settings_sheet.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gắn sơ đồ sân vào màn ghi điểm. Tự đồng bộ lượt giao và mốc đổi sân sau
/// mỗi điểm; chỉ ghi server khi cài đặt sân thực sự đổi.
class PickleballCourtPanel extends ConsumerStatefulWidget {
  const PickleballCourtPanel({
    super.key,
    required this.params,
    required this.canScore,
  });

  final MatchControlParams params;

  /// Quyền ghi điểm: chỉ người có quyền mới thấy nút ⚙.
  final bool canScore;

  @override
  ConsumerState<PickleballCourtPanel> createState() =>
      _PickleballCourtPanelState();
}

class _PickleballCourtPanelState extends ConsumerState<PickleballCourtPanel> {
  /// Lỗi đồng bộ tự động gần nhất đã báo; tránh toast lặp cho cùng một lỗi.
  String? _lastSyncError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_sync());
    });
  }

  Future<void> _sync() async {
    final error = await ref
        .read(pickleballCourtNotifierProvider(widget.params).notifier)
        .syncAutomatic();
    if (error == null) {
      _lastSyncError = null;
      return;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = ErrorParser.parse(error, l10n.pickleballCourtSaveError, l10n);
    if (message == _lastSyncError) return;
    _lastSyncError = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pickleballCourtContextProvider(widget.params), (previous, next) {
      if (next != null) unawaited(_sync());
    });

    final courtContext = ref.watch(pickleballCourtContextProvider(widget.params));
    if (courtContext == null) return const SizedBox.shrink();
    final court = ref.watch(pickleballCourtNotifierProvider(widget.params));
    final match = ref.watch(singleMatchProvider(widget.params)).value;

    return PickleballCourtView(
      layout: resolveCourtLayout(court, courtContext),
      team1Players: match?.team1Members ?? const <String>[],
      team2Players: match?.team2Members ?? const <String>[],
      onOpenSettings: widget.canScore
          ? () => showPickleballCourtSettingsSheet(context, widget.params)
          : null,
    );
  }
}
