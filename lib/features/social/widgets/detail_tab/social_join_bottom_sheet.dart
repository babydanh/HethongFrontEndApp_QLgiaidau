import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';

class SocialJoinBottomSheet extends ConsumerStatefulWidget {
  final SocialSessionModel session;

  const SocialJoinBottomSheet({super.key, required this.session});

  static Future<bool?> show(BuildContext context, SocialSessionModel session) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SocialJoinBottomSheet(session: session),
    );
  }

  @override
  ConsumerState<SocialJoinBottomSheet> createState() =>
      _SocialJoinBottomSheetState();
}

class _SocialJoinBottomSheetState extends ConsumerState<SocialJoinBottomSheet> {
  int _ticketCount = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;

  int get _remainingSlots =>
      widget.session.maxParticipants - widget.session.currentParticipants;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final totalPrice = _ticketCount * widget.session.pricePerSlot;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Yêu cầu tham gia Social',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Session Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262626)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.session.fullDateTimeDisplay,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.session.venueAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Remaining slots tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Số lượng slot muốn đăng ký:',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSlots > 0
                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _remainingSlots > 0
                          ? 'Còn $_remainingSlots slot trống'
                          : 'Hết slot',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _remainingSlots > 0
                            ? const Color(0xFF16A34A)
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ticket Count Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.session.pricePerSlot == 0
                        ? 'Miễn phí'
                        : '${currencyFormatter.format(widget.session.pricePerSlot)} / vé',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  Row(
                    children: [
                      _buildCounterButton(
                        icon: Icons.remove,
                        onTap: _ticketCount > 1
                            ? () => setState(() => _ticketCount--)
                            : null,
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_ticketCount',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _buildCounterButton(
                        icon: Icons.add,
                        onTap: _ticketCount < _remainingSlots
                            ? () => setState(() => _ticketCount++)
                            : null,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total Price Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền thanh toán:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(totalPrice),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_remainingSlots > 0 &&
                          widget.session.status == 'OPEN' &&
                          !widget.session.isJoined &&
                          !_isSubmitting)
                      ? _handleConfirmJoin
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _remainingSlots > 0
                              ? 'Xác nhận tham gia'
                              : 'Đã hết chỗ',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
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

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0))
              : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? (isDark ? Colors.white : const Color(0xFF0F172A))
              : Colors.grey,
        ),
      ),
    );
  }

  Future<void> _handleConfirmJoin() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(socialSessionsProvider.notifier)
          .joinSession(sessionId: widget.session.id, ticketCount: _ticketCount);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Đăng ký thành công $_ticketCount vé buổi ${widget.session.title}!',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
