import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/team_notifier.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final Team? teamToEdit;

  const AddTeamScreen({
    super.key, 
    required this.tournamentId,
    this.teamToEdit,
  });

  @override
  ConsumerState<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends ConsumerState<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _memberControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.teamToEdit != null) {
      _nameController.text = widget.teamToEdit!.name;
      _emailController.text = widget.teamToEdit!.contactEmail;
      for (final member in widget.teamToEdit!.members) {
        _memberControllers.add(TextEditingController(text: member));
      }
    }
    
    if (_memberControllers.isEmpty) {
      _memberControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    for (final c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  void _removeMemberField(int index) {
    if (_memberControllers.length > 1) {
      setState(() {
        _memberControllers[index].dispose();
        _memberControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final members = _memberControllers
          .map((c) => c.text.trim())
          .where((m) => m.isNotEmpty)
          .toList();

      if (widget.teamToEdit == null) {
        final id = const Uuid().v4();
        final team = Team(
          id: id,
          name: _nameController.text.trim(),
          members: members,
          contactEmail: _emailController.text.trim(),
          qrCode: 'VDV_${id.substring(0, 6).toUpperCase()}',
          createdAt: DateTime.now(),
        );

        await ref.read(teamServiceProvider(widget.tournamentId)).addTeam(team);
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Thêm đội thành công!'),
              backgroundColor: context.colors.success,
            ),
          );
          context.pop();
        }
      } else {
        final updatedTeam = widget.teamToEdit!.copyWith(
          name: _nameController.text.trim(),
          members: members,
          contactEmail: _emailController.text.trim(),
        );

        await ref.read(teamServiceProvider(widget.tournamentId)).updateTeam(updatedTeam);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Cập nhật đội thành công!'),
              backgroundColor: context.colors.success,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: context.colors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        title: Text(widget.teamToEdit == null ? 'Thêm đội / VĐV' : 'Sửa thông tin đội'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Tên đội
            Text('Tên đội / VĐV *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
            const SizedBox(height: 8),
            AppTextFormField(
              controller: _nameController,
              hint: 'VD: Đội Sấm sét',
              prefixIcon: Icons.group,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 24),

            // Thành viên
            Row(
              children: [
                Text('Thành viên',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addMemberField,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_memberControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextFormField(
                        controller: _memberControllers[index],
                        hint: 'Tên thành viên ${index + 1}',
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                    if (_memberControllers.length > 1)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: context.colors.error, size: 20),
                        onPressed: () => _removeMemberField(index),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Email
            Text('Email liên hệ (tùy chọn)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
            const SizedBox(height: 8),
            AppTextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hint: 'email@example.com',
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 40),

            // Submit
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTeam,
                child: _isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Lưu đội',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
