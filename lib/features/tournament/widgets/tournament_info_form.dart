import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/extensions/animation_extensions.dart';
import 'package:app_quanly_giaidau/core/widgets/form_section.dart';

class TournamentInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final FocusNode nameFocusNode;

  const TournamentInfoForm({
    super.key,
    required this.nameController,
    required this.descController,
    required this.nameFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSection(
          title: 'Tên giải đấu *',
          child: TextFormField(
            controller: nameController,
            focusNode: nameFocusNode,
            style: TextStyle(color: context.colors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'VD: Giải Cầu lông Mùa hè 2025',
              prefixIcon: Icon(Icons.edit, color: AppTheme.primaryLight),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên giải đấu';
              }
              return null;
            },
          ),
        ).slideInFromBottom(delay: 0.ms),

        FormSection(
          title: 'Mô tả (tùy chọn)',
          child: TextFormField(
            controller: descController,
            style: TextStyle(color: context.colors.textPrimary),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Thông tin thêm về giải đấu, địa điểm, thời gian...',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(Icons.notes, color: context.colors.textSecondary),
              ),
            ),
          ),
        ).slideInFromBottom(delay: 300.ms),
      ],
    );
  }
}
