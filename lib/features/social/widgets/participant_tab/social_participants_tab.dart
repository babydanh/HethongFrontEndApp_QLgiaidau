import 'dart:math' as math;
import 'social_ticket_slots.dart';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

class SocialParticipantsTab extends StatelessWidget {
  const SocialParticipantsTab({
    super.key,
    required this.session,
    required this.isHost,
    required this.onAddParticipant,
    required this.onRemoveParticipant,
    this.onApproveParticipant,
    this.onRejectParticipant,
    this.removingParticipantId,
  });

  final SocialSessionModel session;
  final bool isHost;
  final ValueChanged<int> onAddParticipant;
  final ValueChanged<SocialParticipantModel> onRemoveParticipant;
  final ValueChanged<SocialParticipantModel>? onApproveParticipant;
  final ValueChanged<SocialParticipantModel>? onRejectParticipant;
  final String? removingParticipantId;

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    final colors = context.colors;

    final english = Localizations.localeOf(context).languageCode == 'en';
    late final List<SocialTicketSlot> slots;
    try {
      slots = projectSocialTickets(session);
    } on FormatException {
      return Center(
        child: Text(
          english
              ? 'Invalid ticket data. Please refresh.'
              : 'Dữ liệu vé không hợp lệ. Vui lòng tải lại.',
        ),
      );
    }
    final totalSlots = session.maxSlots;
    final confirmedCount = slots.length;
    final inconsistent =
        confirmedCount != session.currentSlots || confirmedCount > totalSlots;
    final isCompleted = session.status.toUpperCase() == 'COMPLETED';
    final pendingRequests = session.requestedParticipants;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ─── 1. XÁC NHẬN THAM GIA Header & More icon ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${english ? 'CONFIRMED' : 'XÁC NHẬN THAM GIA'} • $confirmedCount/$totalSlots',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (inconsistent)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              english
                  ? 'Ticket totals differ from the server. Please refresh.'
                  : 'Số vé chưa khớp máy chủ. Vui lòng tải lại.',
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: math.max(
              1,
              math.min(
                4,
                ((MediaQuery.sizeOf(context).width - 32) /
                        (80 * MediaQuery.textScalerOf(context).scale(1)))
                    .floor(),
              ),
            ),
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            mainAxisExtent: 72 + MediaQuery.textScalerOf(context).scale(18),
          ),
          itemCount: math.max(totalSlots, confirmedCount),
          itemBuilder: (context, index) {
            if (index < slots.length) {
              final slot = slots[index];
              final p = slot.participant;
              final canRemove =
                  isHost &&
                  !isCompleted &&
                  !p.isHost &&
                  p.userId != session.hostUserId &&
                  p.apiIdentifier.isNotEmpty;
              return Semantics(
                key: ValueKey(slot.key),
                label:
                    '${p.name}, ${english ? 'ticket' : 'vé'} ${slot.ticketIndex + 1}/${p.ticketCount}',
                child: InkWell(
                  onTap: canRemove && removingParticipantId == null
                      ? () => onRemoveParticipant(p)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: colors.success.withValues(
                                      alpha: 0.35,
                                    ),
                                    child: Center(child: Text(p.initials)),
                                  ),
                                  if (p.avatarUrl?.trim().isNotEmpty == true)
                                    Image.network(
                                      p.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stack) =>
                                          Center(child: Text(p.initials)),
                                    ),
                                  if (slot.ticketIndex > 0)
                                    ColoredBox(
                                      color: Colors.black54,
                                      child: Center(
                                        child: Text(
                                          '+${slot.ticketIndex}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (canRemove)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.bgCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.border),
                                ),
                                child: removingParticipantId == p.apiIdentifier
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.close_rounded,
                                        size: 17,
                                        color: colors.error,
                                      ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // Empty slot with '+' icon
              return InkWell(
                onTap: (isHost && !isCompleted)
                    ? () => onAddParticipant(index + 1)
                    : null,
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.bgElevated.withValues(alpha: 0.5),
                        border: Border.all(
                          color: colors.border,
                          width: 1.5,
                          strokeAlign: BorderSide.strokeAlignCenter,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 28,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              );
            }
          },
        ),

        // ─── 3. ĐÃ YÊU CẦU (Chỉ hiển thị khi isHost = true và có yêu cầu) ───
        if (isHost && pendingRequests.isNotEmpty) ...[
          const SizedBox(height: 20),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 16),
          Text(
            '${english ? 'REQUESTED' : 'ĐÃ YÊU CẦU'} • ${pendingRequests.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingRequests.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = pendingRequests[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.success.withValues(alpha: 0.35),
                        border: Border.all(
                          color: colors.success.withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          p.initials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name and Actions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.name} • ${p.ticketCount} ${english ? 'tickets' : 'vé'}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              // Icons.check button (Duyệt yêu cầu)
                              IconButton.outlined(
                                onPressed: onApproveParticipant != null
                                    ? () => onApproveParticipant!(p)
                                    : null,
                                icon: const Icon(Icons.check, size: 16),
                                tooltip: 'Cho phép tham gia',
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(
                                    color: AppTheme.primary,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Icons.close_rounded button (Từ chối yêu cầu)
                              IconButton.outlined(
                                tooltip: 'Từ chối yêu cầu',
                                onPressed: onRejectParticipant != null
                                    ? () => onRejectParticipant!(p)
                                    : null,
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: colors.error,
                                ),
                                style: IconButton.styleFrom(
                                  side: BorderSide(color: colors.border),
                                  padding: const EdgeInsets.all(8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
