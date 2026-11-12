import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Video hướng dẫn tuỳ chọn. Bỏ file này vào `assets/videos/` để khe video hiện
/// ra; không có file thì khe tự ẩn và hộp thoại vẫn đủ ý.
const cameraTabHelpVideoAsset = 'assets/videos/camera_tab_help.mp4';

const _stepInterval = Duration(milliseconds: 1800);

Future<void> showCameraTabHelpDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const CameraTabHelpDialog(),
);

/// Hướng dẫn tab Camera: ba bước sáng lần lượt. Tôn trọng yêu cầu giảm chuyển
/// động của hệ điều hành: khi bật thì ba bước hiện tĩnh, không chạy hoạt ảnh.
class CameraTabHelpDialog extends StatefulWidget {
  const CameraTabHelpDialog({super.key});

  @override
  State<CameraTabHelpDialog> createState() => _CameraTabHelpDialogState();
}

class _CameraTabHelpDialogState extends State<CameraTabHelpDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _stepInterval * 3,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _started = false;
    } else if (!_started) {
      _started = true;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final steps = [
      (
        l10n.camTabHelpStep1Title,
        l10n.camTabHelpStep1Body,
        Icons.sports_tennis,
      ),
      (l10n.camTabHelpStep2Title, l10n.camTabHelpStep2Body, Icons.play_circle),
      (l10n.camTabHelpStep3Title, l10n.camTabHelpStep3Body, Icons.videocam),
    ];
    return AlertDialog(
      title: Text(l10n.camTabHelpHeading),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HelpVideoSlot(),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final active = animate
                    ? (_controller.value * steps.length).floor() % steps.length
                    : -1;
                return Column(
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      _StepTile(
                        key: ValueKey('camera-help-step-$i'),
                        title: steps[i].$1,
                        body: steps[i].$2,
                        icon: steps[i].$3,
                        highlighted: active == i,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.camTabHelpClose),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.highlighted,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingSM),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.primary.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              color: highlighted ? AppTheme.primary : colors.textMuted,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Khe video tuỳ chọn: chỉ dựng khi file có trong bundle, ngược lại ẩn hẳn.
class _HelpVideoSlot extends StatefulWidget {
  const _HelpVideoSlot();

  @override
  State<_HelpVideoSlot> createState() => _HelpVideoSlotState();
}

class _HelpVideoSlotState extends State<_HelpVideoSlot> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!manifest.listAssets().contains(cameraTabHelpVideoAsset)) return;
      final controller = VideoPlayerController.asset(cameraTabHelpVideoAsset);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.play();
      setState(() => _video = controller);
    } on Object {
      // Video chỉ là phần thêm: lỗi gì cũng coi như không có.
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: AspectRatio(
          aspectRatio: video.value.aspectRatio,
          child: VideoPlayer(video),
        ),
      ),
    );
  }
}
