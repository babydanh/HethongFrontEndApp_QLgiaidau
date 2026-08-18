import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tạo nhanh Public trên app. Không nhận communityId; quản lý chi tiết mở trên web.
class CreatePublicQuickTournamentScreen extends ConsumerStatefulWidget {
  const CreatePublicQuickTournamentScreen({super.key});

  @override
  ConsumerState<CreatePublicQuickTournamentScreen> createState() => _CreatePublicQuickTournamentScreenState();
}

class _CreatePublicQuickTournamentScreenState extends ConsumerState<CreatePublicQuickTournamentScreen> {
  static const _log = AppLogger('CreatePublicQuickTournament');
  final _nameController = TextEditingController();
  final _maxTeamsController = TextEditingController(text: '16');
  String _sport = AppConstants.sportBadminton;
  String _format = AppConstants.formatSingles;
  String _bracket = AppConstants.bracketSingleElimination;
  String _visibility = 'PUBLIC';
  static const _registrationMode = 'APPROVAL';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final maxTeams = int.tryParse(_maxTeamsController.text.trim());
    if (name.isEmpty) {
      _showError('Vui lòng nhập tên giải đấu.');
      return;
    }
    if (maxTeams == null || maxTeams < 2 || maxTeams > 32) {
      _showError('Quy mô phải từ 2 đến 32 người/đội.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ref.read(dioClientProvider).dio.post('/tournaments/lite', data: {
        'name': name,
        'sport': _sport,
        'format': _format,
        'bracketType': _bracket,
        'maxTeams': maxTeams,
        'visibility': _visibility,
        'registrationMode': _registrationMode,
        'isRanked': false,
      });
      final raw = response.data;
      final payload = raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final tournamentId = payload['id']?.toString() ?? '';
      if (tournamentId.isEmpty) throw const FormatException('Không nhận được mã giải đấu.');
      _log.info('Tạo Public Quick thành công: $tournamentId');
      await _openWebManagement(tournamentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo giải. Đang mở trang quản lý trên web.')));
        context.pop();
      }
    } catch (error, stack) {
      _log.error('Không thể tạo Public Quick', error, stack);
      if (mounted) _showError(ErrorParser.parse(error, 'Không thể tạo giải đấu.'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openWebManagement(String tournamentId) async {
    final uri = Uri.parse('${AppConstants.appDomain}/organizer/tournaments/$tournamentId/manage');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const FormatException('Không thể mở trang quản lý trên web.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: context.colors.error));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(title: const Text('Tạo giải nhanh'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Giải Public', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tạo nhanh trên app, bổ sung cấu hình nâng cao trong trang quản lý web.', style: TextStyle(color: colors.textMuted, height: 1.35)),
          const SizedBox(height: 20),
          _label('Tên giải đấu *', colors),
          const SizedBox(height: 6),
          TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'VD: Giải Cầu lông Cuối Tuần')),
          const SizedBox(height: 18),
          _label('Môn thể thao *', colors),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(initialValue: _sport, items: AppConstants.sportNames.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(), onChanged: (value) => setState(() => _sport = value ?? _sport)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _dropdown('Hình thức', _format, AppConstants.formatNames, (value) => setState(() => _format = value))),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('Thể thức', _bracket, AppConstants.bracketTypeNames, (value) => setState(() => _bracket = value))),
          ]),
          const SizedBox(height: 18),
          _label('Số đội / người tối đa', colors),
          const SizedBox(height: 6),
          TextField(controller: _maxTeamsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '16')),
          const SizedBox(height: 18),
          _choiceGroup('Hiển thị giải đấu', {'PUBLIC': 'Công khai', 'PRIVATE': 'Không niêm yết'}, _visibility, (value) => setState(() => _visibility = value)),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)), child: Text('Đăng ký mặc định ở chế độ Xét duyệt. Bạn có thể thay đổi cách nhận đăng ký trong trang quản lý web sau khi tạo.', style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35))),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)), child: Text('Không có lựa chọn câu lạc bộ trong luồng Public. Muốn tạo trong CLB, hãy vào trang CLB và chọn Lite CLB hoặc Tạo nhanh trên web.', style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35))),
          const SizedBox(height: 24),
          FilledButton(onPressed: _isSubmitting ? null : _submit, child: Text(_isSubmitting ? 'Đang tạo...' : 'Tạo giải nhanh')),
        ],
      ),
    );
  }

  Widget _label(String text, AppColorsExtension colors) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary));

  Widget _dropdown(String label, String value, Map<String, String> options, ValueChanged<String> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary)), const SizedBox(height: 6), DropdownButtonFormField<String>(initialValue: value, items: options.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis))).toList(), onChanged: (next) { if (next != null) onChanged(next); })]);

  Widget _choiceGroup(String title, Map<String, String> options, String value, ValueChanged<String> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary)), const SizedBox(height: 8), ...options.entries.map((entry) => RadioListTile<String>(value: entry.key, groupValue: value, onChanged: (next) { if (next != null) onChanged(next); }, title: Text(entry.value), dense: true, contentPadding: EdgeInsets.zero))]);
}
