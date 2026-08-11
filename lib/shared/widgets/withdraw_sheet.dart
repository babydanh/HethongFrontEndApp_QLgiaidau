import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

/// Bottom sheet xác nhận rút lui khỏi giải đấu.
/// - Giải miễn phí: xác nhận đơn giản, rút luôn.
/// - Giải có phí và đã đóng tiền: lấy ngân hàng từ profile.
///   • Nếu profile đã có đủ → hiển thị thông tin, cho phép xác nhận ngay.
///   • Nếu chưa có → yêu cầu nhập, lưu vào profile đồng thời khi rút lui.
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
  static Future<void> show(
    BuildContext context, {
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

  /// true khi profile đã có đầy đủ ngân hàng và đang hiển thị từ profile
  bool _usingProfileBank = false;

  /// false chừng nào chưa check profile xong (chỉ relevant khi hasPaid=true)
  bool _profileBankLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.hasPaid) {
      // Dùng postFrameCallback để đảm bảo ref.read an toàn sau khi widget mount
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProfileBank();
      });
    } else {
      // Giải miễn phí không cần load bank → đánh dấu loaded ngay
      _profileBankLoaded = true;
    }
  }

  void _loadProfileBank() {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile != null) {
      final hasBank = (profile.bankName?.isNotEmpty ?? false) &&
          (profile.bankAccountNumber?.isNotEmpty ?? false) &&
          (profile.bankAccountName?.isNotEmpty ?? false);
      if (hasBank) {
        _bankNameCtrl.text = profile.bankName!;
        _accountNumberCtrl.text = profile.bankAccountNumber!;
        _accountNameCtrl.text = profile.bankAccountName!;
        _usingProfileBank = true;
      }
    }
    if (mounted) setState(() => _profileBankLoaded = true);
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  /// Cần nhập form bank khi giải có phí VÀ chưa dùng profile bank
  bool get _needsBankInput => widget.hasPaid && !_usingProfileBank;

  Future<void> _handleWithdraw() async {
    // Validate form bank nếu user cần nhập thủ công
    if (_needsBankInput) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _submitting = true);
    try {
      final bankName = _bankNameCtrl.text.trim().isEmpty
          ? null
          : _bankNameCtrl.text.trim();
      final bankAccountNumber = _accountNumberCtrl.text.trim().isEmpty
          ? null
          : _accountNumberCtrl.text.trim();
      final bankAccountName = _accountNameCtrl.text.trim().isEmpty
          ? null
          : _accountNameCtrl.text.trim().toUpperCase();

      // Nếu user vừa nhập bank mới (chưa có trong profile) → lưu vào profile
      // Làm trước khi gọi withdraw để nếu withdraw thất bại thì bank vẫn được lưu
      if (_needsBankInput &&
          bankName != null &&
          bankAccountNumber != null &&
          bankAccountName != null) {
        try {
          await ref.read(userRepositoryProvider).updateProfile({
            'bankName': bankName,
            'bankAccountNumber': bankAccountNumber,
            'bankAccountName': bankAccountName,
          });
          ref.invalidate(userProfileProvider);
        } catch (_) {
          // Không block rút lui nếu lưu profile thất bại
        }
      }

      await ref.read(tournamentRepositoryProvider).withdraw(
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
        // Chỉ gửi bank khi giải có phí (backend cũng fallback từ profile nếu null)
        bankName: widget.hasPaid ? bankName : null,
        bankAccountNumber: widget.hasPaid ? bankAccountNumber : null,
        bankAccountName: widget.hasPaid ? bankAccountName : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.hasPaid
                ? 'Đã rút lui. Tiền hoàn sẽ được xử lý trong 3–5 ngày.'
                : 'Đã rút lui khỏi giải đấu'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
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
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title + close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rút lui',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mô tả
          Text(
            widget.hasPaid
                ? (_usingProfileBank
                    ? 'Tiền hoàn sẽ được chuyển vào tài khoản ngân hàng trong hồ sơ của bạn.'
                    : 'Bạn đã đóng phí. Vui lòng nhập thông tin ngân hàng để nhận hoàn tiền (sẽ được lưu vào hồ sơ).')
                : 'Bạn có chắc muốn rút lui khỏi giải đấu này?',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Bank section: chỉ khi giải có phí
          if (widget.hasPaid) ...[
            if (!_profileBankLoaded)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_usingProfileBank)
              _BankInfoCard(
                colors: colors,
                bankName: _bankNameCtrl.text,
                accountNumber: _accountNumberCtrl.text,
                accountName: _accountNameCtrl.text,
                onChangePressed: () => setState(() {
                  _usingProfileBank = false;
                  _bankNameCtrl.clear();
                  _accountNumberCtrl.clear();
                  _accountNameCtrl.clear();
                }),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _bankNameCtrl,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Tên ngân hàng',
                        hintText: 'VD: Vietcombank, Techcombank',
                        filled: true,
                        fillColor: colors.bgDark,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Nhập tên ngân hàng'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountNumberCtrl,
                      style: TextStyle(color: colors.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số tài khoản',
                        hintText: 'Nhập số tài khoản',
                        filled: true,
                        fillColor: colors.bgDark,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 6)
                              ? 'Số tài khoản không hợp lệ'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountNameCtrl,
                      style: TextStyle(color: colors.textPrimary),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Chủ tài khoản',
                        hintText: 'VIẾT HOA KHÔNG DẤU',
                        filled: true,
                        fillColor: colors.bgDark,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Nhập tên chủ tài khoản'
                              : null,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Warning box — luôn hiển thị trước nút xác nhận
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.error.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, size: 20, color: colors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hành động này không thể hoàn tác.',
                    style: TextStyle(fontSize: 13, color: colors.error),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _handleWithdraw,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.exit_to_app_rounded),
              label:
                  Text(_submitting ? 'Đang xử lý...' : 'Xác nhận rút lui'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card hiển thị thông tin ngân hàng từ profile (read-only)
class _BankInfoCard extends StatelessWidget {
  final AppColorsExtension colors;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final VoidCallback onChangePressed;

  const _BankInfoCard({
    required this.colors,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.account_balance_rounded,
                    size: 16, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Ngân hàng hoàn tiền',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
              GestureDetector(
                onTap: onChangePressed,
                child: Text(
                  'Đổi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BankRow(label: 'Ngân hàng', value: bankName, colors: colors),
          const SizedBox(height: 4),
          _BankRow(label: 'Số TK', value: accountNumber, colors: colors),
          const SizedBox(height: 4),
          _BankRow(label: 'Chủ TK', value: accountName, colors: colors),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final AppColorsExtension colors;
  final String label;
  final String value;

  const _BankRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
