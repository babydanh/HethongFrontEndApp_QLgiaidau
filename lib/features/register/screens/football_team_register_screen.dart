import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

class FootballTeamRegisterScreen extends ConsumerStatefulWidget {
  const FootballTeamRegisterScreen({super.key, required this.tournamentId, this.divisionId, this.categoryId, this.inviteCode, this.participantId, this.teamSize = 7, this.maxReserve = 0});
  final String tournamentId;
  final String? divisionId;
  final String? categoryId;
  final String? inviteCode;
  final String? participantId;
  final int teamSize;
  final int maxReserve;

  @override
  ConsumerState<FootballTeamRegisterScreen> createState() => _FootballTeamRegisterScreenState();
}

class _FootballTeamRegisterScreenState extends ConsumerState<FootballTeamRegisterScreen> {
  final _name = TextEditingController();
  List<FootballTeamSummary> _teams = const [];
  String? _selected;
  bool _loading = true;
  bool _saving = false;
  List<FootballTeamMemberSummary> _members = const [];
  Set<String> _selectedMemberIds = <String>{};
  Set<String> _selectedReserveIds = <String>{};
  FootballRosterStatus? _rosterStatus;
  bool _rosterAction = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (widget.participantId != null) {
      try {
        final status = await ref.read(tournamentRepositoryProvider).getFootballRosterStatus(
          tournamentId: widget.tournamentId,
          participantId: widget.participantId!,
        );
        if (mounted) setState(() => _rosterStatus = status);
      } catch (_) {}
    }
    try {
      final teams = await ref.read(footballTeamApiProvider).listMyFootballTeams();
      if (!mounted) return;
      final filtered = teams.where((team) => widget.categoryId == null || team.categoryId == widget.categoryId).toList();
      final firstId = filtered.firstOrNull?.id;
      setState(() { _teams = filtered; _selected = firstId; });
      if (firstId != null) await _loadMembers(firstId);
    } catch (_) {
      if (mounted) setState(() { _teams = []; });
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _respondToRoster(String action) async {
    if (widget.participantId == null || _rosterAction) return;
    setState(() => _rosterAction = true);
    try {
      await ref.read(tournamentRepositoryProvider).respondFootballRoster(
        tournamentId: widget.tournamentId,
        participantId: widget.participantId!,
        action: action,
      );
      final status = await ref.read(tournamentRepositoryProvider).getFootballRosterStatus(
        tournamentId: widget.tournamentId,
        participantId: widget.participantId!,
      );
      if (mounted) setState(() => _rosterStatus = status);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorParser.parse(error, 'Không thể cập nhật đội hình'))));
    } finally {
      if (mounted) setState(() => _rosterAction = false);
    }
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty || widget.categoryId == null) return;
    setState(() => _saving = true);
    try {
      final team = await ref.read(footballTeamApiProvider).createFootballTeam(name: name, categoryId: widget.categoryId!);
      if (!mounted) return;
      setState(() { _teams = [team, ..._teams]; _selected = team.id; _name.clear(); });
      await _loadMembers(team.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo đội. Hãy mời đủ thành viên trong trang đội.')));
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorParser.parse(error, 'Không thể tạo đội')))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _loadMembers(String teamId) async {
    try {
      final team = await ref.read(footballTeamApiProvider).getFootballTeam(teamId);
      if (!mounted || _selected != teamId) return;
      final members = team.members.where((member) => member.status == null || member.status == 'ACTIVE').toList();
      String? currentUserId;
      try {
        currentUserId = (await ref.read(userProfileProvider.future)).id;
      } catch (_) {
        currentUserId = null;
      }
      setState(() {
        _members = members;
        final ids = members.map((member) => member.userId).where((id) => id.isNotEmpty).toList();
        final orderedIds = [
          if (currentUserId != null && ids.contains(currentUserId)) currentUserId,
          ...ids.where((id) => id != currentUserId),
        ];
        _selectedMemberIds = orderedIds.take(widget.teamSize).toSet();
        _selectedReserveIds = <String>{};
      });
    } catch (_) {
      if (mounted && _selected == teamId) setState(() { _members = const []; _selectedMemberIds = <String>{}; });
    }
  }

  Future<void> _register() async {
    final id = _selected;
    final team = _teams.where((item) => item.id == id).firstOrNull;
    if (team == null) return;
    setState(() => _saving = true);
    try {
      final result = await ref.read(tournamentRepositoryProvider).registerParticipant(
        tournamentId: widget.tournamentId,
        teamName: team.name,
        footballTeamId: team.id,
        memberIds: _selectedMemberIds.toList(),
        reserveMemberIds: _selectedReserveIds.toList(),
        divisionId: widget.divisionId,
        inviteCode: widget.inviteCode,
        rankingConsent: true,
      );
      if (!mounted) return;
      if (result.entryFee > 0 && result.participantId.isNotEmpty) {
        context.push('/payment/checkout', extra: {'tournamentId': widget.tournamentId, 'participantId': result.participantId, 'divisionId': widget.divisionId, 'amount': result.entryFee});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký đội thành công.')));
        context.pop();
      }
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorParser.parse(error, 'Không thể đăng ký đội')))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng ký đội bóng')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      if (_rosterStatus?.currentMember?.confirmationStatus == 'PENDING') Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bạn được chọn vào đội hình giải này', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Hãy xác nhận trước khi Ban tổ chức khóa roster.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              FilledButton.icon(onPressed: _rosterAction ? null : () => _respondToRoster('CONFIRM'), icon: const Icon(Icons.check, size: 16), label: const Text('Xác nhận')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _rosterAction ? null : () => _respondToRoster('DECLINE'), icon: const Icon(Icons.close, size: 16), label: const Text('Từ chối')),
            ]),
          ]),
        ),
      ),
      const Text('Chọn đội đã tạo', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (_loading) const Center(child: CircularProgressIndicator()) else if (_teams.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Chưa có đội bóng phù hợp với môn này.')))
      else RadioGroup<String>(
        groupValue: _selected,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selected = value);
          _loadMembers(value);
        },
        child: Column(
          children: _teams.map((team) => RadioListTile<String>(
            value: team.id,
            title: Text(team.name),
            subtitle: Text(team.role == 'PLAYER' ? 'Thành viên' : 'Có quyền đăng ký'),
          )).toList(),
        ),
      ),
      if (_members.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('Đội hình đăng ký', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Chọn đúng ${widget.teamSize} cầu thủ chính và tối đa ${widget.maxReserve} dự bị.', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ..._members.map((member) => CheckboxListTile(
          dense: true,
          value: _selectedMemberIds.contains(member.userId) || _selectedReserveIds.contains(member.userId),
          onChanged: (_) => _showRosterRolePicker(member),
          title: Text(member.userId, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_selectedMemberIds.contains(member.userId) ? 'Chính • ${member.role}' : _selectedReserveIds.contains(member.userId) ? 'Dự bị • ${member.role}' : member.role),
        )),
      ],
      const SizedBox(height: 16),
      const Text('Tạo đội nhanh', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: TextField(controller: _name, decoration: const InputDecoration(hintText: 'Tên đội'))), const SizedBox(width: 8), FilledButton(onPressed: _saving ? null : _create, child: const Text('Tạo'))]),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: _saving || _loading || _selected == null || _selectedMemberIds.length != widget.teamSize || _selectedReserveIds.length > widget.maxReserve ? null : _register, icon: const Icon(Icons.check), label: const Text('Đăng ký đội đã chọn')),
    ]),
  );

  Future<void> _showRosterRolePicker(FootballTeamMemberSummary member) async {
    final current = _selectedMemberIds.contains(member.userId)
        ? 'MAIN'
        : _selectedReserveIds.contains(member.userId)
            ? 'RESERVE'
            : 'NONE';
    final role = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.sports_soccer), title: const Text('Cầu thủ chính'), enabled: current != 'MAIN' && _selectedMemberIds.length >= widget.teamSize ? false : true, onTap: () => Navigator.pop(sheetContext, 'MAIN')),
          ListTile(leading: const Icon(Icons.event_seat), title: const Text('Cầu thủ dự bị'), enabled: current != 'RESERVE' && _selectedReserveIds.length >= widget.maxReserve ? false : true, onTap: () => Navigator.pop(sheetContext, 'RESERVE')),
          ListTile(leading: const Icon(Icons.remove_circle_outline), title: const Text('Bỏ chọn'), onTap: () => Navigator.pop(sheetContext, 'NONE')),
        ]),
      ),
    );
    if (!mounted || role == null) return;
    setState(() {
      _selectedMemberIds.remove(member.userId);
      _selectedReserveIds.remove(member.userId);
      if (role == 'MAIN') _selectedMemberIds.add(member.userId);
      if (role == 'RESERVE') _selectedReserveIds.add(member.userId);
    });
  }
}
