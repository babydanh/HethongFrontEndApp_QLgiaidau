import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_club_members_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_external_participant_modal.dart';
import 'package:flutter/material.dart';

class SocialAddParticipantSheet extends StatelessWidget {
  const SocialAddParticipantSheet({
    super.key,
    required this.parentContext,
    required this.session,
    required this.slotNumber,
  });

  final BuildContext parentContext;
  final SocialSessionModel session;
  final int slotNumber;

  static Future<void> show(
    BuildContext context,
    SocialSessionModel session,
    int slotNumber,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.colors.bgCard,
      builder: (_) => SocialAddParticipantSheet(
        parentContext: context,
        session: session,
        slotNumber: slotNumber,
      ),
    );
  }

  void _openNext(BuildContext context, {required bool clubMember}) {
    Navigator.pop(context);
    if (!parentContext.mounted) return;
    if (clubMember) {
      SocialClubMembersSheet.show(parentContext, session, slotNumber);
    } else {
      SocialExternalParticipantModal.show(parentContext, session, slotNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Text(
                  'Thêm người tham gia',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _option(
            context,
            'Thêm thành viên CLB',
            () => _openNext(context, clubMember: true),
          ),
          _option(
            context,
            'Thêm người ngoài CLB',
            () => _openNext(context, clubMember: false),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String label, VoidCallback onTap) {
    final colors = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colors.textSecondary,
        size: 24,
      ),
      onTap: onTap,
    );
  }
}
