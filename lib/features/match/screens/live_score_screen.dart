import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/features/match/widgets/penalty_input_dialog.dart';
class LiveScoreScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String matchId;

  const LiveScoreScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  ConsumerState<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends ConsumerState<LiveScoreScreen> {
  final _maxScoreController = TextEditingController(text: '21');
  final _refereeController = TextEditingController();
  bool _winByTwo = true;

  @override
  void dispose() {
    _maxScoreController.dispose();
    _refereeController.dispose();
    super.dispose();
  }

  void _checkWinner(MatchModel match) {
    if (match.maxScore == null) return;
    
    int max = match.maxScore!;
    if (match.score1 >= max || match.score2 >= max) {
      if (match.winByTwo) {
        if ((match.score1 - match.score2).abs() < 2) return;
      }
      
      // Có người đạt đủ điều kiện thắng
      String winnerName = match.score1 > match.score2 ? match.team1Name : match.team2Name;
      String winnerId = match.score1 > match.score2 ? match.team1Id : match.team2Id;
      String loserId = match.score1 > match.score2 ? match.team2Id : match.team1Id;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: context.colors.bgCard,
          title: Text('🎉 Trận đấu kết thúc!', style: TextStyle(color: context.colors.textPrimary)),
          content: Text('Đội $winnerName đã giành chiến thắng!', style: TextStyle(color: context.colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tiếp tục đánh (Hủy)'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)))
                  .endMatch(winnerId, loserId);
                // Tự động lùi về màn hình trước đó (Sơ đồ nhánh đấu)
                context.pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.success),
              child: const Text('Xác nhận Kết thúc'),
            ),
          ],
        ),
      );
    }
  }

  void _showFoulSheet(bool isTeam1, MatchModel match) {
    final tournamentAsync = ref.read(tournamentProvider(widget.tournamentId));
    final sport = tournamentAsync.value?.sport ?? 'other';
    
    showDialog(
      context: context,
      builder: (_) => PenaltyInputDialog(
        sportType: sport,
        team1Name: match.team1Name,
        team2Name: match.team2Name,
        onSubmit: (teamName, option, reason) {
          final isT1 = teamName == match.team1Name;
          ref.read(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)))
            .addPenalty(isT1, sport, option.id, option.name, reason);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã ghi nhận ${option.name}.'), backgroundColor: context.colors.success),
            );
          }
        },
      ),
    );
  }

  void _showFoulSelectionDialog(MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        title: Text('Đội nào bị phạt?', style: TextStyle(color: context.colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(match.team1Name, style: TextStyle(color: context.colors.textPrimary)),
              tileColor: Colors.blueAccent.withValues(alpha: 0.1),
              onTap: () {
                Navigator.pop(ctx);
                _showFoulSheet(true, match);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(match.team2Name, style: TextStyle(color: context.colors.textPrimary)),
              tileColor: Colors.redAccent.withValues(alpha: 0.1),
              onTap: () {
                Navigator.pop(ctx);
                _showFoulSheet(false, match);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showForceWinDialog(MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        title: Text('Xử thắng nhanh', style: TextStyle(color: context.colors.error)),
        content: Text('Xác nhận xử thắng cho một đội (đối thủ bỏ cuộc hoặc phạm quy)?', style: TextStyle(color: context.colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _forceWinMatch(match.team1Id, match.team2Id);
            },
            child: Text(match.team1Name),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _forceWinMatch(match.team2Id, match.team1Id);
            },
            child: Text(match.team2Name),
          ),
        ],
      ),
    );
  }

  void _forceWinMatch(String winnerId, String loserId) {
    final match = ref.read(singleMatchProvider((tournamentId: widget.tournamentId, matchId: widget.matchId))).value;
    if (match != null) {
      int newScore1 = match.score1;
      int newScore2 = match.score2;
      
      if (winnerId == match.team1Id) {
        newScore1 = match.maxScore ?? (match.score1 <= match.score2 ? match.score2 + 1 : match.score1);
      } else {
        newScore2 = match.maxScore ?? (match.score2 <= match.score1 ? match.score1 + 1 : match.score2);
      }

      ref.read(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)))
        .updateMatchResultByAdmin(
          score1: newScore1,
          score2: newScore2,
          winnerId: winnerId,
          loserId: loserId,
        );
    } else {
      ref.read(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)))
        .endMatch(winnerId, loserId);
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(singleMatchProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));
    ref.watch(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));
    final authRole = ref.watch(authProvider).role;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        title: Text('Bàn Trọng Tài', style: TextStyle(fontSize: isLandscape ? 16 : 20)),
        toolbarHeight: isLandscape ? 40 : 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: isLandscape ? 20 : 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) return const Center(child: Text('Không tìm thấy trận đấu'));

          // Trigger auto-check winner if live
          if (match.isLive) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkWinner(match));
          }

          if (match.isScheduled) {
            return _buildSetupState(match);
          } else if (match.isLive) {
            return _buildLiveState(match);
          } else {
            return _buildCompletedState(match, authRole);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSetupState(MatchModel match) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cấu hình Trận đấu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
              const SizedBox(height: 16),
              Text('${match.team1Name} vs ${match.team2Name}', style: const TextStyle(fontSize: 18, color: AppTheme.primary)),
              const SizedBox(height: 32),
              TextField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Điểm tối đa để thắng (VD: 21)',
                  labelStyle: TextStyle(color: context.colors.textSecondary),
                  filled: true,
                  fillColor: context.colors.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _refereeController,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Tên trọng tài (Tùy chọn)',
                  labelStyle: TextStyle(color: context.colors.textSecondary),
                  filled: true,
                  fillColor: context.colors.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person, color: AppTheme.secondaryLight),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Áp dụng luật cách biệt 2 điểm', style: TextStyle(color: context.colors.textPrimary)),
                value: _winByTwo,
                onChanged: (val) {
                  setState(() => _winByTwo = val ?? true);
                },
                activeColor: AppTheme.primary,
                checkColor: Colors.white,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () async {
                    final controller = ref.read(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));
                    await controller.updateConfig(
                      maxScore: int.tryParse(_maxScoreController.text) ?? 21,
                      winByTwo: _winByTwo,
                    );
                    await controller.startMatch(
                      maxScore: int.tryParse(_maxScoreController.text) ?? 21,
                      timeLimitMinutes: null,
                      refereeName: _refereeController.text.trim(),
                    );
                  },
                  child: const Text('BẮT ĐẦU TRẬN ĐẤU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    ).animate().fade().scale();
  }

  Widget _buildLiveState(MatchModel match) {
    return Column(
      children: [
        // Top info bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: context.colors.bgCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Điểm tối đa: ${match.maxScore ?? 'Không giới hạn'}', style: TextStyle(color: context.colors.textSecondary)),
              if (match.winByTwo) Text('Luật cách biệt 2 điểm', style: TextStyle(color: context.colors.warning)),
              if (match.refereeName != null && match.refereeName!.isNotEmpty)
                Text('Trọng tài: ${match.refereeName}', style: const TextStyle(color: AppTheme.secondary)),
            ],
          ),
        ),
        
        // Split screen
        Expanded(
          child: Row(
            children: [
              // Team 1
              Expanded(
                child: _buildTeamScoreControl(
                  match: match,
                  isTeam1: true,
                  color: Colors.blueAccent,
                ),
              ),
              // Divider
              Container(width: 4, color: context.colors.bgDark),
              // Team 2
              Expanded(
                child: _buildTeamScoreControl(
                  match: match,
                  isTeam1: false,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
        
        // Bottom controls for Whistle and Force Win
        Container(
          padding: const EdgeInsets.all(12),
          color: context.colors.bgCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.sports, size: 24),
                  label: const Text('THỔI CÒI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: () => _showFoulSelectionDialog(match),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.emoji_events, size: 24),
                  label: const Text('XỬ THẮNG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: () => _showForceWinDialog(match),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamScoreControl({required MatchModel match, required bool isTeam1, required Color color}) {
    final teamName = isTeam1 ? match.team1Name : match.team2Name;
    final score = isTeam1 ? match.score1 : match.score2;
    final controller = ref.read(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));

    return GestureDetector(
      onTap: () => controller.addScore(isTeam1, 1),
      child: Container(
        color: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              teamName, 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color), 
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  '$score', 
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 40),
              color: color,
              onPressed: () => controller.addScore(isTeam1, -1),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState(MatchModel match, UserRole? role) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
            const SizedBox(height: 16),
            Text('TRẬN ĐẤU ĐÃ KẾT THÚC', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            const SizedBox(height: 12),
            Text('${match.team1Name}  ${match.score1} - ${match.score2}  ${match.team2Name}', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            const SizedBox(height: 16),
            
            if (role == UserRole.admin) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.red),
                label: const Text('SỬA KẾT QUẢ (ADMIN)', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _showAdminEditDialog(context, match),
              ),
              const SizedBox(height: 16),
            ],
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.bgSurface,
                foregroundColor: context.colors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => context.pop(),
              child: const Text('Quay lại sơ đồ giải'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text('Về trang chủ', style: TextStyle(color: context.colors.textMuted)),
            )
          ],
        ),
      ),
    ).animate().fade();
  }

  void _showAdminEditDialog(BuildContext context, MatchModel match) {
    final score1Ctrl = TextEditingController(text: match.score1.toString());
    final score2Ctrl = TextEditingController(text: match.score2.toString());
    String selectedWinnerId = match.winnerId.isNotEmpty ? match.winnerId : match.team1Id;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: context.colors.bgCard,
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Admin: Sửa Kết Quả', style: TextStyle(color: context.colors.textPrimary, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cảnh báo: Việc thay đổi kết quả sẽ ghi đè dữ liệu và tự động cập nhật lại nhánh đấu tiếp theo. Vui lòng cẩn trọng.',
                      style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(match.team1Name, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: score1Ctrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: context.colors.textPrimary),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: context.colors.bgDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(match.team2Name, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: score2Ctrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: context.colors.textPrimary),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: context.colors.bgDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Đội chiến thắng:', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedWinnerId,
                      dropdownColor: context.colors.bgCard,
                      items: [
                        DropdownMenuItem(value: match.team1Id, child: Text(match.team1Name, style: TextStyle(color: context.colors.textPrimary))),
                        DropdownMenuItem(value: match.team2Id, child: Text(match.team2Name, style: TextStyle(color: context.colors.textPrimary))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedWinnerId = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.colors.bgDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    final s1 = int.tryParse(score1Ctrl.text) ?? 0;
                    final s2 = int.tryParse(score2Ctrl.text) ?? 0;
                    final wId = selectedWinnerId;
                    final lId = selectedWinnerId == match.team1Id ? match.team2Id : match.team1Id;
                    
                    Navigator.pop(ctx);
                    ref.read(matchControllerProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)))
                      .updateMatchResultByAdmin(
                        score1: s1,
                        score2: s2,
                        winnerId: wId,
                        loserId: lId,
                      );
                      
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật kết quả trận đấu!')),
                    );
                  },
                  child: const Text('Lưu Thay Đổi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
