import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/usecases/tournament/create_tournament_use_case.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_info_form.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_settings_form.dart';
import 'package:app_quanly_giaidau/core/extensions/animation_extensions.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState
    extends ConsumerState<CreateTournamentScreen> {
  static const _log = AppLogger('CreateTournament');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _maxTeamsController = TextEditingController(text: '16');
  final _roundCountController = TextEditingController(text: '1');
  final _nameFocusNode = FocusNode();
  final _maxTeamsFocusNode = FocusNode();
  final _roundCountFocusNode = FocusNode();

  String _selectedSport = AppConstants.sportBadminton;
  String _selectedFormat = AppConstants.formatSingles;
  String? _selectedCategory = AppConstants.categoryMenSingles;
  String _selectedBracket = AppConstants.bracketSingleElimination;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _maxTeamsController.dispose();
    _roundCountController.dispose();
    _nameFocusNode.dispose();
    _maxTeamsFocusNode.dispose();
    _roundCountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createTournament() async {
    final name = _nameController.text.trim();
    final isValid = _formKey.currentState!.validate();
    
    if (!isValid || name.isEmpty) {
      // Bắt lỗi kép, phòng trường hợp validator của Form bị bypass
      if (name.isEmpty) {
        _nameFocusNode.requestFocus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tên giải đấu không được để trống!'),
              backgroundColor: context.colors.error,
            ),
          );
        }
      } else if (_maxTeamsController.text.trim().isNotEmpty) {
        final val = int.tryParse(_maxTeamsController.text.trim());
        final isRoundRobin = _selectedBracket == AppConstants.bracketRoundRobin;
        if (isRoundRobin) {
          if (val == null || val < 3 || val > 16) {
            _maxTeamsFocusNode.requestFocus();
            return;
          }
          final rc = int.tryParse(_roundCountController.text.trim());
          if (rc == null || rc < 1) {
            _roundCountFocusNode.requestFocus();
            return;
          }
        } else {
          if (val == null || val < 2 || val > 32) {
            _maxTeamsFocusNode.requestFocus();
            return;
          }
        }
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      _log.info('Bắt đầu tạo giải đấu');
      final isRoundRobin = _selectedBracket == AppConstants.bracketRoundRobin;
      final defaultMaxTeams = isRoundRobin ? 16 : 16;
      final maxTeamsVal = int.tryParse(_maxTeamsController.text.trim()) ?? defaultMaxTeams;
      final roundCountVal = isRoundRobin ? (int.tryParse(_roundCountController.text.trim()) ?? 1) : 1;

      _log.info('Đang lưu Tournament thông qua API...');
      final createdTournament =
          await ref.read(createTournamentUseCaseProvider).call(
                CreateTournamentParams(
                  name: _nameController.text.trim(),
                  sport: _selectedSport,
                  format: _selectedFormat,
                  category: _selectedCategory,
                  bracketType: _selectedBracket,
                  description: _descController.text.trim(),
                  maxTeams: maxTeamsVal,
                  roundCount: roundCountVal,
                ),
              );
      _log.success('Lưu Tournament thành công!');

      _log.info('Tự động đăng nhập nội bộ...');
      await ref.read(authProvider.notifier).loginLocally(
        tokenCode: createdTournament.adminToken,
        role: UserRole.admin,
        tournamentId: createdTournament.id,
      );
      _log.success('Đăng nhập nội bộ thành công!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Tạo giải đấu thành công!'),
            backgroundColor: context.colors.success,
          ),
        );
        _log.info('Chuyển hướng sang màn hình Admin...');
        context.go('/admin/tournament/${createdTournament.id}');
      }
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      _log.debug('Kết thúc _createTournament()');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text(
          'Tạo giải đấu mới',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ─── Thông tin cơ bản ───
            TournamentInfoForm(
              nameController: _nameController,
              descController: _descController,
              nameFocusNode: _nameFocusNode,
            ),

            // ─── Cài đặt giải đấu ───
            TournamentSettingsForm(
              selectedSport: _selectedSport,
              selectedFormat: _selectedFormat,
              selectedCategory: _selectedCategory,
              selectedBracket: _selectedBracket,
              maxTeamsController: _maxTeamsController,
              maxTeamsFocusNode: _maxTeamsFocusNode,
              roundCountController: _roundCountController,
              roundCountFocusNode: _roundCountFocusNode,
              formKey: _formKey,
              onSportChanged: (val) => setState(() => _selectedSport = val),
              onFormatChanged: (val) => setState(() => _selectedFormat = val),
              onCategoryChanged: (val) => setState(() => _selectedCategory = val),
              onBracketChanged: (val) => setState(() => _selectedBracket = val),
              onShowBracketInfo: _showBracketInfoModal,
            ),

            const SizedBox(height: 12),

            // ─── Submit Button ───
            Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                gradient: context.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTournament,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Tạo giải đấu ngay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ).scaleIn(delay: 350.ms),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }



  void _showBracketInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Giải thích các Thể thức thi đấu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ...AppConstants.bracketTypeNames.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_tree_rounded, size: 18, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.bracketTypeNames[key] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppConstants.bracketTypeDetails[key] ?? '',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
