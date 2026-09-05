import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/elo_tier.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_tier_badge.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

enum EloOperationType { add, subtract, set }

/// Bottom Sheet điều phối ELO thành viên trong CLB (Dành cho Chủ CLB / Ban Quản Trị)
/// Đồng bộ tính năng 100% với MemberEloAdjustModal.tsx trên bản Web.
class MemberEloAdjustSheet extends ConsumerStatefulWidget {
  final String communityId;
  final String userId;
  final String memberName;
  final int currentElo;
  final String categoryName;
  final VoidCallback? onSuccess;

  const MemberEloAdjustSheet({
    super.key,
    required this.communityId,
    required this.userId,
    required this.memberName,
    this.currentElo = 1000,
    this.categoryName = 'Pickleball',
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String communityId,
    required String userId,
    required String memberName,
    int currentElo = 1000,
    String categoryName = 'Pickleball',
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberEloAdjustSheet(
        communityId: communityId,
        userId: userId,
        memberName: memberName,
        currentElo: currentElo,
        categoryName: categoryName,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<MemberEloAdjustSheet> createState() => _MemberEloAdjustSheetState();
}

class _MemberEloAdjustSheetState extends ConsumerState<MemberEloAdjustSheet> {
  EloOperationType _operation = EloOperationType.add;
  final TextEditingController _amountController = TextEditingController(text: '25');
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _parsedAmount => int.tryParse(_amountController.text.trim()) ?? 0;

  int get _previewElo {
    final amount = _parsedAmount;
    switch (_operation) {
      case EloOperationType.add:
        return widget.currentElo + amount;
      case EloOperationType.subtract:
        return (widget.currentElo - amount).clamp(0, 99999);
      case EloOperationType.set:
        return amount.clamp(0, 99999);
    }
  }

  Future<void> _submit() async {
    final amount = _parsedAmount;
    final reason = _reasonController.text.trim();

    if (_operation == EloOperationType.set && amount < 0) {
      setState(() => _errorText = 'Điểm ELO không thể nhỏ hơn 0');
      return;
    }
    if ((_operation == EloOperationType.add || _operation == EloOperationType.subtract) && amount <= 0) {
      setState(() => _errorText = 'Vui lòng nhập số điểm thay đổi lớn hơn 0');
      return;
    }
    if (reason.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập lý do điều chỉnh ELO (để lưu lịch sử minh bạch)');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final opString = _operation == EloOperationType.add
          ? 'ADD'
          : _operation == EloOperationType.subtract
              ? 'SUBTRACT'
              : 'SET';

      await repo.adjustMemberElo(
        widget.communityId,
        userId: widget.userId,
        operation: opString,
        points: amount,
        reason: reason,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật ELO thành viên thành công!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = 'Không thể cập nhật ELO: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentTier = resolveEloTier(elo: widget.currentElo).shortCode;
    final previewTier = resolveEloTier(elo: _previewElo).shortCode;
    final isTierChanged = currentTier != previewTier;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điều phối ELO Thành viên',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.memberName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Chọn thao tác ELO (Thêm + / Bớt - / Đặt mới =)
              Text(
                'THAO TÁC ELO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Row(
                  children: [
                    _buildOpTab(
                      type: EloOperationType.add,
                      label: 'Thêm (+)',
                      icon: Icons.add_rounded,
                      activeColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    _buildOpTab(
                      type: EloOperationType.subtract,
                      label: 'Bớt (-)',
                      icon: Icons.remove_rounded,
                      activeColor: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    _buildOpTab(
                      type: EloOperationType.set,
                      label: 'Đặt mới (=)',
                      icon: Icons.edit_rounded,
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ô nhập số điểm ELO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _operation == EloOperationType.set ? 'ĐIỂM ELO MỚI' : 'SỐ ĐIỂM THAY ĐỔI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (_operation != EloOperationType.set)
                    Row(
                      children: [10, 25, 50].map((val) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _amountController.text = val.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.borderLight),
                              ),
                              child: Text(
                                _operation == EloOperationType.add ? '+$val' : '-$val',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.bgSurface,
                  hintText: _operation == EloOperationType.set ? '1000' : '25',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                  prefixIcon: Icon(
                    _operation == EloOperationType.add
                        ? Icons.add_rounded
                        : _operation == EloOperationType.subtract
                            ? Icons.remove_rounded
                            : Icons.pin_rounded,
                    color: colors.textMuted,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Hộp xem trước thay đổi ELO và Hạng (Rank Preview)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XEM TRƯỚC XẾP HẠNG SAU ĐIỀU CHỈNH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderLight),
                      ),
                      child: Row(
                        children: [
                          // Hiện tại
                          EloTierBadge(
                            elo: widget.currentElo,
                            categoryName: widget.categoryName,
                            scale: 0.9,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.currentElo}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: colors.textMuted,
                          ),
                          const Spacer(),
                          // Sau thay đổi
                          EloTierBadge(
                            elo: _previewElo,
                            categoryName: widget.categoryName,
                            scale: 0.9,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_previewElo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _previewElo > widget.currentElo
                                  ? const Color(0xFF10B981)
                                  : _previewElo < widget.currentElo
                                      ? const Color(0xFFEF4444)
                                      : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isTierChanged) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hạng sẽ tự động đổi từ $currentTier sang $previewTier',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ô nhập lý do
              Text(
                'LÝ DO ĐIỀU CHỈNH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.bgSurface,
                  hintText: 'Ví dụ: Đạt giải nhất nội bộ, điều chỉnh ELO nhập môn...',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Nút xác nhận
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Xác nhận điều chỉnh ELO',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpTab({
    required EloOperationType type,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final colors = context.colors;
    final isSelected = _operation == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _operation = type;
            if (type == EloOperationType.set) {
              _amountController.text = widget.currentElo.toString();
            } else if (_amountController.text == widget.currentElo.toString()) {
              _amountController.text = '25';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
