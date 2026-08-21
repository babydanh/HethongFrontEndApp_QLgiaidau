import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';

/// Compact team-first registration view for football Lite management.
/// The organizer opens one team card to inspect its roster instead of seeing
/// every member as a separate top-level registration row.
class FootballRegistrationGroups extends StatefulWidget {
  final List<LiteParticipant> participants;
  final AppColorsExtension colors;
  final bool rosterConfirmed;
  final Future<void> Function(LiteParticipant participant, String reason)?
      onKickParticipant;

  const FootballRegistrationGroups({
    super.key,
    required this.participants,
    required this.colors,
    required this.rosterConfirmed,
    this.onKickParticipant,
  });

  @override
  State<FootballRegistrationGroups> createState() =>
      _FootballRegistrationGroupsState();
}

class _FootballRegistrationGroupsState
    extends State<FootballRegistrationGroups> {
  final Set<String> _expanded = <String>{};

  Map<String, List<LiteParticipant>> _groupParticipants() {
    final groups = <String, List<LiteParticipant>>{};
    for (final participant in widget.participants) {
      final key = participant.footballTeamId ?? 'legacy:${participant.id}';
      groups.putIfAbsent(key, () => <LiteParticipant>[]).add(participant);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = _groupParticipants();
    return Column(
      children: groups.entries.map((entry) {
        final team = entry.value.first;
        final expanded = _expanded.contains(entry.key);
        final members = <String, LiteMember>{};
        for (final participant in entry.value) {
          for (final member in participant.members) {
            members[member.id] = member;
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() {
                  if (expanded) {
                    _expanded.remove(entry.key);
                  } else {
                    _expanded.add(entry.key);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _TeamLogo(
                        url: team.footballTeamLogoUrl,
                        name: team.teamName,
                        colors: widget.colors,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.teamName.isEmpty
                                  ? l10n.lite_teamUnnamed
                                  : team.teamName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.lite_memberCountStatus(
                                members.length,
                                _statusLabel(entry.value, l10n),
                              ),
                              style: TextStyle(
                                color: widget.colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: widget.colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  color: widget.colors.bgSurface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      if (widget.rosterConfirmed)
                        _StatusChip(
                          label: l10n.lite_rosterConfirmed,
                          color: widget.colors.success,
                        ),
                      const SizedBox(height: 8),
                      ...members.values.map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppTheme.primary
                                    .withValues(alpha: 0.1),
                                backgroundImage: member.avatarUrl.isNotEmpty
                                    ? NetworkImage(member.avatarUrl)
                                    : null,
                                child: member.avatarUrl.isEmpty
                                    ? Icon(
                                        Icons.person_outline,
                                        size: 17,
                                        color: AppTheme.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  member.fullName.isEmpty
                                      ? l10n.lite_memberUnnamed
                                      : member.fullName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _memberRoleLabel(member.role, l10n),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.onKickParticipant != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmKick(context, team),
                            icon: const Icon(Icons.person_remove_outlined, size: 16),
                            label: Text(l10n.lite_removeTeamFromTournament),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.colors.error,
                              side: BorderSide(
                                color: widget.colors.error.withValues(alpha: 0.35),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _statusLabel(List<LiteParticipant> participants, AppLocalizations l10n) {
    final statuses = participants.map((item) => item.status).toSet();
    if (statuses.contains('KICKED')) return l10n.lite_statusKicked;
    // Lite is direct participation. Legacy approval statuses are displayed as
    // registered instead of exposing an approval workflow that no longer exists.
    if (statuses.contains('PENDING_APPROVAL') || statuses.contains('PENDING')) {
      return l10n.lite_statusRegistered;
    }
    if (statuses.contains('COMPLETE')) return l10n.lite_statusComplete;
    return l10n.lite_statusRegistering;
  }

  String _memberRoleLabel(String role, AppLocalizations l10n) {
    switch (role) {
      case 'MAIN':
      case 'STARTER':
        return l10n.lite_roleMain;
      case 'RESERVE':
      case 'SUBSTITUTE':
        return l10n.lite_roleReserve;
      default:
        return l10n.lite_roleMember;
    }
  }

  Future<void> _confirmKick(
    BuildContext context,
    LiteParticipant participant,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lite_kickTeamTitle),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l10n.lite_kickReasonLabel,
            hintText: l10n.lite_kickReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              reasonController.text.trim(),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: widget.colors.error,
            ),
            child: Text(l10n.lite_kickTeamAction),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || widget.onKickParticipant == null || !mounted) {
      return;
    }
    await widget.onKickParticipant!(participant, reason);
  }

}

class _TeamLogo extends StatelessWidget {
  final String? url;
  final String name;
  final AppColorsExtension colors;

  const _TeamLogo({
    required this.url,
    required this.name,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
      backgroundImage: url != null && url!.isNotEmpty
          ? NetworkImage(url!)
          : null,
      child: url == null || url!.isEmpty
          ? Text(
              name.isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            )
          : null,
    );
  }

}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

}
