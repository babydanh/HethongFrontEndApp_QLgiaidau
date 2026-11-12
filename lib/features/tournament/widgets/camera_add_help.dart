import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// How many times the "?" ring pulses to catch the eye before it settles.
/// Finite on purpose: an endless animation never lets `pumpAndSettle` return
/// and keeps nagging the organiser.
const _pulseCount = 3;

/// Header row of the "Add camera" sheet: a short line plus a "?" button that
/// opens an animated explanation of how a picture reaches SportO through AQP
/// (OBS or phone → AQP SportO → viewers) and the three steps to follow.
///
/// Animations are off when the OS asks to reduce motion.
class CameraAddHelp extends StatefulWidget {
  const CameraAddHelp({super.key});

  @override
  State<CameraAddHelp> createState() => _CameraAddHelpState();
}

class _CameraAddHelpState extends State<CameraAddHelp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _open = false;
  bool _pulseStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pulseStarted || MediaQuery.disableAnimationsOf(context)) return;
    _pulseStarted = true;
    _pulse.repeat(count: _pulseCount);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final panel = _open
        ? const _HelpPanel(key: ValueKey('camera-help-panel'))
        : const SizedBox(width: double.infinity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.tournamentCameraHelpTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            _buildButton(l10n, colors),
          ],
        ),
        // AnimatedSize with a zero duration dirties its own layout, so reduced
        // motion skips it instead of shortening it.
        if (MediaQuery.disableAnimationsOf(context))
          panel
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: panel,
          ),
      ],
    );
  }

  Widget _buildButton(AppLocalizations l10n, AppColorsExtension colors) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      expanded: _open,
      label: l10n.tournamentCameraHelpLabel,
      excludeSemantics: true,
      child: InkResponse(
        key: const ValueKey('camera-help-button'),
        onTap: () => setState(() => _open = !_open),
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.45 * (1 - _pulse.value),
                    child: Container(
                      width: 32 + 14 * _pulse.value,
                      height: 32 + 14 * _pulse.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent),
                ),
                child: Text(
                  '?',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpPanel extends StatelessWidget {
  const _HelpPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      l10n.tournamentCameraHelpStep1,
      l10n.tournamentCameraHelpStep2,
      l10n.tournamentCameraHelpStep3,
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _FlowNode(
                icon: Icons.smartphone_rounded,
                label: l10n.tournamentCameraHelpDevice,
              ),
              const Expanded(child: _FlowLine()),
              _FlowNode(
                icon: Icons.sensors_rounded,
                label: l10n.tournamentCameraHelpAqp,
              ),
              const Expanded(child: _FlowLine()),
              _FlowNode(
                icon: Icons.visibility_rounded,
                label: l10n.tournamentCameraHelpViewer,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final step in steps)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF7DD3FC)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dot that keeps travelling along the line while the panel is open; it
/// rests in the middle when the OS asks to reduce motion.
class _FlowLine extends StatefulWidget {
  const _FlowLine();

  @override
  State<_FlowLine> createState() => _FlowLineState();
}

class _FlowLineState extends State<_FlowLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        height: 6,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            Container(height: 2, color: const Color(0xFF334155)),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Align(
                alignment: Alignment(
                  _started ? -1 + 2 * _controller.value : -0.2,
                  0,
                ),
                child: child,
              ),
              child: Container(
                width: 12,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
