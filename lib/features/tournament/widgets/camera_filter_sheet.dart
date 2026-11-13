import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Lựa chọn của bảng lọc: vòng (null = tất cả) và "Chưa có cam".
typedef CameraFilterChoice = ({int? round, bool onlyNoCamera});

/// Hiện tối đa ~3,5 dòng vòng rồi cuộn, để nhiều vòng cũng không đẩy cao bảng.
const double _listMaxHeight = kMinTouchTarget * 3.5;

/// Bảng dưới "Lọc trận": danh sách vòng (chọn 1), công tắc "Chưa có cam", nút
/// "Xoá lọc" / "Áp dụng". Trả về lựa chọn khi Áp dụng hoặc Xoá lọc; vuốt/đóng
/// bảng thì trả null và bộ lọc hiện tại không đổi.
Future<CameraFilterChoice?> showCameraFilterSheet(
  BuildContext context, {
  required List<int> rounds,
  required CameraFilterChoice current,
}) => showModalBottomSheet<CameraFilterChoice>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _CameraFilterSheet(rounds: rounds, current: current),
);

class _CameraFilterSheet extends StatefulWidget {
  const _CameraFilterSheet({required this.rounds, required this.current});

  final List<int> rounds;
  final CameraFilterChoice current;

  @override
  State<_CameraFilterSheet> createState() => _CameraFilterSheetState();
}

class _CameraFilterSheetState extends State<_CameraFilterSheet> {
  late int? _round = widget.current.round;
  late bool _onlyNoCamera = widget.current.onlyNoCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final options = <int?>[null, ...widget.rounds];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMD,
          0,
          AppTheme.spacingMD,
          AppTheme.spacingMD,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.camTabFilterTooltip,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _listMaxHeight),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final round = options[index];
                      final selected = round == _round;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        minTileHeight: kMinTouchTarget,
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                        ),
                        title: Text(
                          round == null
                              ? l10n.camTabAllRounds
                              : l10n.camTabRound(round),
                        ),
                        onTap: () => setState(() => _round = round),
                      );
                    },
                  ),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.camTabNoCamera),
              value: _onlyNoCamera,
              onChanged: (value) => setState(() => _onlyNoCamera = value),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop((round: null, onlyNoCamera: false)),
                    child: Text(l10n.camTabClearFilter),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop((round: _round, onlyNoCamera: _onlyNoCamera)),
                    child: Text(l10n.camTabApplyFilter),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
