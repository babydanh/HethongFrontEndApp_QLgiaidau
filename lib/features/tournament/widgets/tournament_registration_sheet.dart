import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sport_pill.dart';
import 'package:intl/intl.dart';

class TournamentRegistrationSheet extends StatefulWidget {
  final Tournament tournament;

  const TournamentRegistrationSheet({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentRegistrationSheet> createState() => _TournamentRegistrationSheetState();
}

class _TournamentRegistrationSheetState extends State<TournamentRegistrationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký tham gia giải đấu thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatFee(double? fee) {
    if (fee == null || fee <= 0) {
      return "Miễn phí";
    }
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(fee)} VNĐ";
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return "Chưa cập nhật";
    }
    return DateFormat("dd/MM/yyyy").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Đăng ký tham gia",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.bgSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colors.border.withValues(alpha: 0.5), height: 1.0),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0 + viewInsets),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SportPill(sportKey: widget.tournament.sport),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.tournament.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.calendar_today_rounded,
                            "Thời gian đăng ký",
                            "${_formatDate(widget.tournament.registrationStartDate)} - ${_formatDate(widget.tournament.registrationEndDate)}",
                            colors,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.payments_outlined,
                            "Lệ phí tham gia",
                            _formatFee(widget.tournament.entryFee),
                            colors,
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                    if (widget.tournament.prizeDescription != null && widget.tournament.prizeDescription!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        "CƠ CẤU GIẢI THƯỞNG",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.tournament.prizeDescription!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      "THÔNG TIN ĐỘI / CÁ NHÂN",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _teamNameController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Tên đội thi đấu",
                        hintText: "Nhập tên đội của bạn",
                        prefixIcon: const Icon(Icons.group_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: colors.bgSurface,
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Vui lòng nhập tên đội" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Email liên hệ",
                        hintText: "Để BTC gửi thông báo",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: colors.bgSurface,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || !value.contains("@") ? "Email không hợp lệ" : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Xác nhận đăng ký",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AppColorsExtension colors, {bool isHighlight = false}) {
    final highlightColor = const Color(0xFF2979FF);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlight ? highlightColor.withValues(alpha: 0.1) : colors.bgSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isHighlight ? highlightColor : colors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? highlightColor : colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
