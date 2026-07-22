import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';

/// Bottom sheet xác nhận rút lui khỏi giải đấu.
/// Nếu đã đóng phí, hiển thị form nhập thông tin ngân hàng.
class WithdrawSheet extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? divisionId;
  final bool hasPaid;

  const WithdrawSheet({
    super.key,
    required this.tournamentId,
    this.divisionId,
    this.hasPaid = false,
  });

  /// Hiển thị WithdrawSheet như một modal bottom sheet.
  static Future<void> show(BuildContext context, {
    required String tournamentId,
    String? divisionId,
    bool hasPaid = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawSheet(
        tournamentId: tournamentId,
        divisionId: divisionId,
        hasPaid: hasPaid,
      ),
    );
  }

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  bool _submitting = false;
  bool _confirmOnly = false;

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleWithdraw() async {
    if (!widget.hasPaid || _confirmOnly) {
      // Free / confirm only — submit without bank info
      setState(() => _submitting = true);
      try {
        await ref.read(tournamentRepositoryProvider).withdraw(
          tournamentId: widget.tournamentId,
          divisionId: widget.divisionId,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã rút lui khỏi giải đấu'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    // Paid — validate bank form
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(tournamentRepositoryProvider).withdraw(
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
        bankName: _bankNameCtrl.text.trim(),
        bankAccountNumber: _accountNumberCtrl.text.trim(),
        bankAccountName: _accountNameCtrl.text.trim().toUpperCase(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yêu cầu rút lui đã gửi. Tiền sẽ được hoàn trong 3-5 ngày.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Rút lui', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: colors.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(widget.hasPaid
            ? 'Bạn đã đóng phí giải đấu này. Vui lòng nhập thông tin ngân hàng để nhận hoàn tiền.'
            : 'Bạn có chắc muốn rút lui khỏi giải đấu này?',
            style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4)),
          const SizedBox(height: 24),
          if (widget.hasPaid && !_confirmOnly) ...[
            Form(key: _formKey, child: Column(children: [
              TextFormField(
                controller: _bankNameCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Tên ngân hàng',
                  hintText: 'VD: Vietcombank, Techcombank',
                  filled: true, fillColor: colors.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên ngân hàng' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberCtrl,
                style: TextStyle(color: colors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tài khoản',
                  hintText: 'Nhập số tài khoản',
                  filled: true, fillColor: colors.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().length < 6) ? 'Số tài khoản không hợp lệ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNameCtrl,
                style: TextStyle(color: colors.textPrimary),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Chủ tài khoản',
                  hintText: 'VIẾT HOA KHÔNG DẤU',
                  filled: true, fillColor: colors.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên chủ tài khoản' : null,
              ),
            ])),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _confirmOnly = true),
              child: Text('Không cần hoàn tiền, chỉ rút lui', style: TextStyle(fontSize: 12, color: colors.textMuted)),
            ),
          ] else ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.error.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Icon(Icons.warning_rounded, size: 20, color: colors.error),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  widget.hasPaid ? 'Bạn sẽ rút lui mà không nhận hoàn tiền.' : 'Hành động này không thể hoàn tác.',
                  style: TextStyle(fontSize: 13, color: colors.error))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _handleWithdraw,
              icon: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.exit_to_app_rounded),
              label: Text(_submitting ? 'Đang xử lý...' : 'Xác nhận rút lui'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
