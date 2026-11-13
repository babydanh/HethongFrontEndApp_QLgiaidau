import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Lựa chọn của bảng lọc: nhãn chặng (null = tất cả) và "Chưa có cam".
typedef CameraFilterChoice = ({String? stage, bool onlyNoCamera});

/// Hiện tối đa ~3,5 dòng chặng rồi cuộn, để nhiều bảng/lượt cũng không đẩy cao
/// bảng.
const double _listMaxHeight = kMinTouchTarget * 3.5;

/// Bảng dưới "Lọc trận": danh sách chặng (bảng/lượt/vòng playoff, chọn 1, kèm
/// số trận), công tắc "Chưa có cam", nút "Xoá lọc" / "Áp dụng". Trả về lựa chọn
/// khi Áp dụng hoặc Xoá lọc; vuốt/đóng bảng thì trả null và bộ lọc không đổi.
Future<CameraFilterChoice?> showCameraFilterSheet(
  BuildContext context, {
  required List<CameraStage> stages,
  required CameraFilterChoice current,
}) => showModalBottomSheet<CameraFilterChoice>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _CameraFilterSheet(stages: stages, current: current),
);

class _CameraFilterSheet extends StatefulWidget {
  const _CameraFilterSheet({required this.stages, required this.current});

  final List<CameraStage> stages;
  final CameraFilterChoice current;

  @override
  State<_CameraFilterSheet> createState() => _CameraFilterSheetState();
}

class _CameraFilterSheetState extends State<_CameraFilterSheet> {
  late String? _stage = widget.current.stage;
  late bool _onlyNoCamera = widget.current.onlyNoCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final options = <CameraStage?>[null, ...widget.stages];
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
                      final stage = options[index];
                      final selected = stage?.label == _stage;
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
                          stage == null ? l10n.camTabAllStages : stage.label,
                        ),
                        trailing: stage == null ? null : Text('${stage.count}'),
                        onTap: () => setState(() => _stage = stage?.label),
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
                    ).pop((stage: null, onlyNoCamera: false)),
                    child: Text(l10n.camTabClearFilter),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop((stage: _stage, onlyNoCamera: _onlyNoCamera)),
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
