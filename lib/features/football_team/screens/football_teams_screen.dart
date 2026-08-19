import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';

class FootballTeamsScreen extends ConsumerStatefulWidget {
  final String? initialTeamId;

  const FootballTeamsScreen({super.key, this.initialTeamId});
  @override
  ConsumerState<FootballTeamsScreen> createState() => _FootballTeamsScreenState();
}

class _FootballTeamsScreenState extends ConsumerState<FootballTeamsScreen> {
  List<FootballTeamSummary> _teams = const [];
  FootballTeamSummary? _selected;
  final _name = TextEditingController();
  final _newName = TextEditingController();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _candidates = const [];
  bool _loading = true;
  bool _saving = false;
  String? _footballCategoryId;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _name.dispose(); _newName.dispose(); _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ref.read(footballTeamApiProvider).listMyFootballTeams(),
        ref.read(dioClientProvider).dio.get('/categories'),
      ]);
      final teams = results[0] as List<FootballTeamSummary>;
      final rawCategories = results[1].data is Map ? results[1].data['data'] : results[1].data;
      final footballCategory = rawCategories is List
          ? rawCategories.whereType<Map>().cast<Map<String, dynamic>>().firstWhere((item) => item['isActive'] != false && RegExp(r'football|bóng đá|soccer', caseSensitive: false).hasMatch('${item['name']} ${item['slug']}'), orElse: () => <String, dynamic>{})
          : <String, dynamic>{};
      if (!mounted) return;
      final activeTeams = teams.where((team) => team.status == 'ACTIVE').toList();
      final requested = activeTeams.where((team) => team.id == widget.initialTeamId).firstOrNull;
      setState(() { _footballCategoryId = footballCategory['id']?.toString(); _teams = activeTeams; _selected = requested ?? _selected ?? activeTeams.firstOrNull; _name.text = _selected?.name ?? ''; });
    } catch (error) { if (mounted) _showError(error); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorParser.parse(error, 'Có lỗi xảy ra'))));

  Future<void> _create() async {
    final name = _newName.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final categoryId = _footballCategoryId;
      if (categoryId == null || categoryId.isEmpty) return;
      final team = await ref.read(footballTeamApiProvider).createFootballTeam(name: name, categoryId: categoryId);
      if (!mounted) return;
      setState(() { _teams = [team, ..._teams]; _selected = team; _name.text = team.name; _newName.clear(); });
    } catch (error) { if (mounted) _showError(error); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _saveName() async {
    if (_selected == null || _name.text.trim().isEmpty) return;
    try { final team = await ref.read(footballTeamApiProvider).updateFootballTeam(_selected!.id, name: _name.text); if (mounted) setState(() { _selected = team; _teams = _teams.map((item) => item.id == team.id ? team : item).toList(); }); }
    catch (error) { if (mounted) _showError(error); }
  }

  Future<void> _searchMembers() async {
    if (_selected == null || _search.text.trim().length < 2) return setState(() => _candidates = const []);
    try { final rows = await ref.read(footballTeamApiProvider).searchFootballTeamMembers(_selected!.id, _search.text); if (mounted) setState(() => _candidates = rows); }
    catch (error) { if (mounted) _showError(error); }
  }

  Future<void> _invite(String userId) async {
    if (_selected == null) return;
    try { await ref.read(footballTeamApiProvider).inviteFootballTeamMember(_selected!.id, userId); if (mounted) { setState(() => _candidates = _candidates.where((row) => row['id']?.toString() != userId).toList()); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi lời mời.'))); } }
    catch (error) { if (mounted) _showError(error); }
  }

  Future<void> _cancelInvite(String userId) async {
    if (_selected == null) return;
    try { await ref.read(footballTeamApiProvider).cancelFootballTeamInvite(_selected!.id, userId); await _load(); }
    catch (error) { if (mounted) _showError(error); }
  }

  Future<void> _changeRole(String userId, String role) async {
    if (_selected == null) return;
    try {
      await ref.read(footballTeamApiProvider).updateFootballTeamMember(_selected!.id, userId, role);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _pickLogo() async {
    final selected = _selected;
    if (selected == null) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (file == null) return;
    try {
      final team = await ref.read(footballTeamApiProvider).uploadFootballTeamLogo(selected.id, await file.readAsBytes(), file.name);
      if (mounted) {
        setState(() {
          _selected = team;
          _teams = _teams.map((item) => item.id == team.id ? team : item).toList();
        });
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(title: const Text('Đội bóng của tôi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Đội đang hoạt động ${_teams.length}/3', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._teams.map(
                    (team) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(team.name.substring(0, team.name.length > 1 ? 2 : 1).toUpperCase())),
                        title: Text(team.name),
                        subtitle: Text('ELO ${team.eloPoints} · ${team.activeMembers.length} thành viên'),
                        selected: selected?.id == team.id,
                        onTap: () => setState(() {
                          _selected = team;
                          _name.text = team.name;
                          _candidates = const [];
                        }),
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: _newName, decoration: const InputDecoration(labelText: 'Tên đội mới'))),
                          const SizedBox(width: 8),
                          FilledButton(onPressed: _saving ? null : _create, child: const Text('Tạo')),
                        ],
                      ),
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _pickLogo,
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundImage: selected.logoUrl == null ? null : NetworkImage(selected.logoUrl!),
                                    child: selected.logoUrl == null ? const Icon(Icons.add_a_photo_outlined) : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Thông tin đội', style: TextStyle(fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên đội'))),
                                const SizedBox(width: 8),
                                OutlinedButton(onPressed: _saveName, child: const Text('Lưu')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Mời thành viên', style: TextStyle(fontWeight: FontWeight.w800)),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: _search, decoration: const InputDecoration(hintText: 'Tên hoặc email'))),
                                IconButton(onPressed: _searchMembers, icon: const Icon(Icons.search)),
                              ],
                            ),
                            ..._candidates.map(
                              (candidate) => ListTile(
                                dense: true,
                                title: Text(candidate['fullName']?.toString() ?? candidate['id']?.toString() ?? 'Tài khoản'),
                                trailing: TextButton(onPressed: () => _invite(candidate['id'].toString()), child: const Text('Mời')),
                              ),
                            ),
                            const Divider(),
                            ...selected.members.map((member) {
                              final isActive = member.status == null || member.status!.toUpperCase() == 'ACTIVE';
                              return ListTile(
                                dense: true,
                                title: Text(member.userId),
                                subtitle: isActive ? null : const Text('Đang mời - chờ xác nhận', style: TextStyle(fontStyle: FontStyle.italic)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isActive)
                                      DropdownButton<String>(
                                        value: const {'CAPTAIN', 'MANAGER', 'PLAYER'}.contains(member.role) ? member.role : 'PLAYER',
                                        items: const [
                                          DropdownMenuItem(value: 'CAPTAIN', child: Text('Đội trưởng')),
                                          DropdownMenuItem(value: 'MANAGER', child: Text('Quản lý')),
                                          DropdownMenuItem(value: 'PLAYER', child: Text('Thành viên')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null && value != member.role) _changeRole(member.userId, value);
                                        },
                                      ),
                                    if (isActive && member.role != 'CAPTAIN')
                                      IconButton(
                                        onPressed: () async {
                                          try {
                                            await ref.read(footballTeamApiProvider).removeFootballTeamMember(selected.id, member.userId);
                                            await _load();
                                          } catch (error) {
                                            if (mounted) _showError(error);
                                          }
                                        },
                                        icon: const Icon(Icons.person_remove_outlined),
                                      ),
                                    if (!isActive)
                                      IconButton(
                                        onPressed: () => _cancelInvite(member.userId),
                                        tooltip: 'Hủy lời mời',
                                        icon: const Icon(Icons.close, size: 20),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
