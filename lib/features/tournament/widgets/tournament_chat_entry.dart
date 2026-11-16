import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_room.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const double _kTapTarget = 44;
const double _kIconSize = 22;
const double _kDimmedOpacity = 0.55;

/// Chat icon in the tournament hero. Each look has its own icon and label
/// (not only a colour change):
/// open (green) · closed (grey archive box) · kicked (dimmed, explains) ·
/// guest (signed out, goes to login) · not registered (goes to sign-up, or
/// dimmed and explains when sign-up is closed) · pending (enters, input
/// locked). A purged room or an unknown reply hides the icon so no dead
/// control is left behind.
class TournamentChatEntry extends ConsumerWidget {
  const TournamentChatEntry({
    super.key,
    required this.tournamentId,
    this.iconShadows,
  });

  final String tournamentId;
  final List<Shadow>? iconShadows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(authProvider.select((a) => a.isAuthenticated));
    if (!signedIn) {
      return _ChatIconButton(
        buttonKey: const ValueKey('tournament-chat-guest'),
        icon: Icons.chat_bubble_outline_rounded,
        color: AppTheme.accent,
        label: l10n.tournamentChatTooltipOpen,
        shadows: iconShadows,
        onPressed: () => context.push('/login'),
      );
    }

    final room = ref.watch(tournamentChatRoomProvider(tournamentId)).asData;
    if (room == null) return const SizedBox.shrink();
    switch (room.value.state) {
      case TournamentChatState.open:
        return _ChatIconButton(
          buttonKey: const ValueKey('tournament-chat-open'),
          icon: Icons.chat_bubble_rounded,
          color: AppTheme.accent,
          label: l10n.tournamentChatTooltipOpen,
          shadows: iconShadows,
          onPressed: () => _openRoom(context, room.value, readOnly: false),
        );
      case TournamentChatState.closed:
        return _ChatIconButton(
          buttonKey: const ValueKey('tournament-chat-closed'),
          icon: Icons.inventory_2_outlined,
          color: Colors.grey,
          label: l10n.tournamentChatTooltipClosed,
          shadows: iconShadows,
          onPressed: () => _openRoom(context, room.value, readOnly: true),
        );
      case TournamentChatState.kicked:
        return _ChatIconButton(
          buttonKey: const ValueKey('tournament-chat-kicked'),
          icon: Icons.block_rounded,
          color: Colors.grey,
          opacity: _kDimmedOpacity,
          label: l10n.tournamentChatTooltipKicked,
          shadows: iconShadows,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chatRoomKickedNotice)),
          ),
        );
      case TournamentChatState.needsRegistration:
        return _ChatIconButton(
          buttonKey: const ValueKey('tournament-chat-register'),
          icon: Icons.how_to_reg_rounded,
          color: AppTheme.accent,
          label: l10n.tournamentChatTooltipRegister,
          shadows: iconShadows,
          onPressed: () => context.push('/register/$tournamentId'),
        );
      case TournamentChatState.registrationClosed:
        return _ChatIconButton(
          buttonKey: const ValueKey('tournament-chat-register-closed'),
          icon: Icons.how_to_reg_rounded,
          color: Colors.grey,
          opacity: _kDimmedOpacity,
          label: l10n.tournamentChatTooltipRegistrationClosed,
          shadows: iconShadows,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.tournamentChatTooltipRegistrationClosed),
            ),
          ),
        );
      case TournamentChatState.pending:
        return _ChatIconButton(
          buttonKey: const ValueKey('tournament-chat-pending'),
          icon: Icons.hourglass_top_rounded,
          color: AppTheme.accent,
          label: l10n.tournamentChatTooltipPending,
          shadows: iconShadows,
          onPressed: () => _openRoom(context, room.value, readOnly: false),
        );
      case TournamentChatState.purged:
        return const SizedBox.shrink();
    }
  }

  void _openRoom(
    BuildContext context,
    TournamentChatRoom room, {
    required bool readOnly,
  }) {
    final name = room.name?.isNotEmpty == true
        ? room.name!
        : AppLocalizations.of(context)!.tournamentChatRoomName;
    final uri = Uri(
      path: '/chat/${room.roomId}',
      queryParameters: {
        'name': name,
        if (room.logoUrl?.isNotEmpty == true) 'avatar': room.logoUrl!,
        'type': 'TOURNAMENT',
        'tournamentId': tournamentId,
        if (readOnly) 'readOnly': '1',
        if (room.state == TournamentChatState.pending) 'pending': '1',
        if (room.canModerate) 'organizer': '1',
      },
    );
    context.push(uri.toString());
  }
}

class _ChatIconButton extends StatelessWidget {
  const _ChatIconButton({
    required this.buttonKey,
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
    this.opacity = 1,
    this.shadows,
  });

  final Key buttonKey;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;
  final double opacity;
  final List<Shadow>? shadows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: opacity,
        child: IconButton(
          key: buttonKey,
          tooltip: label,
          constraints: const BoxConstraints(
            minWidth: _kTapTarget,
            minHeight: _kTapTarget,
          ),
          icon: Icon(icon, color: color, size: _kIconSize, shadows: shadows),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
