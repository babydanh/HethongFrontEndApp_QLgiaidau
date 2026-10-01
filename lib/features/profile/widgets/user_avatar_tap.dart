import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// The shared interaction behind every entry point into a user profile.
///
/// A user name and the avatar beside it must behave identically, so the
/// platform split lives here once instead of being reinvented per surface:
///
///  * **Touch devices** (Android / iOS) — a tap opens [UserProfileBottomSheet],
///    whose "Xem hồ sơ" action reaches the profile page. There is no hover, so
///    no hover gesture is registered either.
///  * **Pointer devices** (web, macOS, Windows, Linux) — hovering opens the
///    same preview content in a popup anchored to [child], which auto-hides
///    [autoHideDelay] after it appears. A tap skips the preview and goes
///    straight to the profile page.
class UserProfileTapTarget extends StatefulWidget {
  final String userId;
  final String name;
  final String? communityId;
  final String? imageUrl;
  final int elo;
  final String? tierName;
  final int matchesPlayed;

  /// How long the pointer must rest on the target before the preview opens.
  final Duration hoverDelay;

  /// How long the preview stays open after appearing.
  final Duration autoHideDelay;

  /// Width of the hover preview popup.
  final double previewWidth;

  /// Forwarded to the preview so a "matches" filter keeps working.
  final void Function(String query)? onFilterMatches;

  final Widget child;

  const UserProfileTapTarget({
    super.key,
    required this.userId,
    required this.name,
    required this.child,
    this.communityId,
    this.imageUrl,
    this.elo = 0,
    this.tierName,
    this.matchesPlayed = 0,
    this.hoverDelay = const Duration(milliseconds: 350),
    this.autoHideDelay = const Duration(seconds: 5),
    this.previewWidth = 360,
    this.onFilterMatches,
  });

  @override
  State<UserProfileTapTarget> createState() => _UserProfileTapTargetState();
}

/// The one avatar entry point into a user's profile.
///
/// Every surface that shows somebody else's avatar should render this instead
/// of a bare avatar, so tapping always leads somewhere instead of being a
/// dead pixel, and pointer devices get a preview for free.
///
/// The avatar visuals are delegated to [RankAvatar] so tier rings stay
/// identical everywhere; the interaction is owned by [UserProfileTapTarget],
/// which is also what a bare user name should be wrapped in.
class UserAvatarTap extends StatelessWidget {
  final String userId;
  final String name;
  final String? communityId;
  final String? imageUrl;
  final int elo;
  final String? tierName;
  final int matchesPlayed;
  final double size;
  final double ringWidth;

  /// Minimum edge of the tappable box. Keeps the target reachable on touch
  /// even when the avatar artwork itself is smaller.
  final double minTouchTarget;

  /// How long the pointer must rest on the avatar before the preview opens.
  final Duration hoverDelay;

  /// How long the preview stays open after appearing.
  final Duration autoHideDelay;

  /// Width of the hover preview popup.
  final double previewWidth;

  /// Forwarded to the preview so a "matches" filter keeps working.
  final void Function(String query)? onFilterMatches;

  const UserAvatarTap({
    super.key,
    required this.userId,
    required this.name,
    this.communityId,
    this.imageUrl,
    this.elo = 0,
    this.tierName,
    this.matchesPlayed = 0,
    this.size = 40,
    this.ringWidth = 2,
    this.minTouchTarget = 44,
    this.hoverDelay = const Duration(milliseconds: 350),
    this.autoHideDelay = const Duration(seconds: 5),
    this.previewWidth = 360,
    this.onFilterMatches,
  });

  @override
  Widget build(BuildContext context) {
    final box = math.max(size, minTouchTarget);
    return UserProfileTapTarget(
      userId: userId,
      name: name,
      communityId: communityId,
      imageUrl: imageUrl,
      elo: elo,
      tierName: tierName,
      matchesPlayed: matchesPlayed,
      hoverDelay: hoverDelay,
      autoHideDelay: autoHideDelay,
      previewWidth: previewWidth,
      onFilterMatches: onFilterMatches,
      child: SizedBox(
        width: box,
        height: box,
        child: Center(
          child: RankAvatar(
            imageUrl: imageUrl,
            name: name.trim(),
            elo: elo,
            tierName: tierName,
            matchesPlayed: matchesPlayed,
            size: size,
            ringWidth: ringWidth,
          ),
        ),
      ),
    );
  }
}

class _UserProfileTapTargetState extends State<UserProfileTapTarget> {
  final LayerLink _anchorLink = LayerLink();

  OverlayEntry? _previewEntry;
  Timer? _hoverTimer;
  Timer? _dismissTimer;
  Timer? _autoHideTimer;

  /// Read at call time (not cached) so `debugDefaultTargetPlatformOverride`
  /// and web builds each see the right answer.
  bool get _supportsHover =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => true,
        _ => false,
      };

  String _profileRoute() => NavigationHelper.getUserProfileRoute(
    widget.userId,
    communityId: widget.communityId,
  );

  @override
  void dispose() {
    _dismissPreview();
    super.dispose();
  }

  void _handleTap() {
    if (widget.userId.trim().isEmpty) return;
    if (_supportsHover) {
      _dismissPreview();
      context.push(_profileRoute());
      return;
    }
    _openPreviewSheet();
  }

  void _openPreviewSheet() {
    unawaited(
      UserProfileBottomSheet.show(
        context,
        userId: widget.userId,
        communityId: widget.communityId,
        initialFullName: widget.name,
        initialAvatarUrl: widget.imageUrl,
        onFilterMatches: widget.onFilterMatches,
      ),
    );
  }

  void _onPointerEnter(PointerEnterEvent _) {
    if (!_supportsHover) return;
    _dismissTimer?.cancel();
    _hoverTimer?.cancel();
    _hoverTimer = Timer(widget.hoverDelay, _showPreview);
  }

  void _onPointerExit(PointerExitEvent _) {
    _hoverTimer?.cancel();
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_pointerGrace, _dismissPreview);
  }

  /// Short window that lets the pointer travel from the avatar into the
  /// popup without the popup vanishing in between.
  static const Duration _pointerGrace = Duration(milliseconds: 250);

  void _showPreview() {
    if (!mounted || _previewEntry != null) return;
    final entry = OverlayEntry(builder: _buildPreview);
    _previewEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
    _autoHideTimer = Timer(widget.autoHideDelay, _dismissPreview);
  }

  void _dismissPreview() {
    _hoverTimer?.cancel();
    _dismissTimer?.cancel();
    _autoHideTimer?.cancel();
    _previewEntry?.remove();
    _previewEntry = null;
  }

  void _openProfileFromPreview() {
    _dismissPreview();
    context.push(_profileRoute());
  }

  Widget _buildPreview(BuildContext overlayContext) {
    final colors = overlayContext.colors;
    final maxHeight = math.min(
      MediaQuery.sizeOf(overlayContext).height * 0.62,
      520.0,
    );
    return Positioned(
      width: widget.previewWidth,
      child: CompositedTransformFollower(
        link: _anchorLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 8),
        child: MouseRegion(
          onEnter: (_) => _dismissTimer?.cancel(),
          // The same grace the source's own exit gets. Without it the popup
          // vanishes the instant the pointer leaves it — including on the
          // short trip back to the avatar to re-hover, which reads as a
          // broken hover card rather than a dismiss.
          onExit: (_) {
            _dismissTimer?.cancel();
            _dismissTimer = Timer(_pointerGrace, _dismissPreview);
          },
          child: Material(
            color: colors.bgCard,
            elevation: 12,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              // The preview reuses the sheet's content, so the "view profile"
              // action must not pop a route it does not own — and it must not
              // scroll out of reach either. The popup is capped at `maxHeight`
              // while the sheet's body wants more, so the actions are pinned
              // to the popup's bottom edge: the profile page stays one click
              // away no matter how far the stats push the content down.
              child: UserProfileBottomSheet(
                userId: widget.userId,
                communityId: widget.communityId,
                initialFullName: widget.name,
                initialAvatarUrl: widget.imageUrl,
                onFilterMatches: widget.onFilterMatches,
                onViewProfile: _openProfileFromPreview,
                pinActions: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayName = widget.name.trim();
    // An unresolved slot (a team name, a "TBD" athlete, a comment with no
    // author id) must stay inert instead of advertising a dead control.
    final canOpen = widget.userId.trim().isNotEmpty;
    final label = canOpen
        ? (l10n == null
              ? displayName
              : l10n.userProfileViewProfileOf(displayName))
        : null;

    return CompositedTransformTarget(
      link: _anchorLink,
      child: Semantics(
        // `container` is what makes this a node of its own — without it the
        // annotation is merged upward and a screen reader announces the row
        // as nothing but its loose text. `excludeSemantics` then keeps the
        // wrapped content (avatar + name + timestamp) as that single node
        // instead of leaking child labels beside it.
        container: true,
        excludeSemantics: true,
        button: canOpen,
        label: label,
        child: MouseRegion(
          cursor: canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: _onPointerEnter,
          onExit: _onPointerExit,
          child: GestureDetector(
            onTap: canOpen ? _handleTap : null,
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
