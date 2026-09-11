part of '../screens/club_detail_screen.dart';

class _JoinQuestionsDialog extends StatefulWidget {
  final List<String> questions;
  final String title;
  final String instruction;
  final String requiredMessage;
  final String cancelLabel;
  final String submitLabel;

  const _JoinQuestionsDialog({
    required this.questions,
    required this.title,
    required this.instruction,
    required this.requiredMessage,
    required this.cancelLabel,
    required this.submitLabel,
  });

  @override
  State<_JoinQuestionsDialog> createState() => _JoinQuestionsDialogState();
}

class _JoinQuestionsDialogState extends State<_JoinQuestionsDialog> {
  late final List<TextEditingController> _controllers;
  late final List<String?> _validationErrors;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = widget.questions
        .map((_) => TextEditingController())
        .toList(growable: false);
    _validationErrors = List<String?>.filled(widget.questions.length, null);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _close([Map<String, dynamic>? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    var isValid = true;
    for (var i = 0; i < _controllers.length; i++) {
      final isEmpty = _controllers[i].text.trim().isEmpty;
      _validationErrors[i] = isEmpty ? widget.requiredMessage : null;
      if (isEmpty) isValid = false;
    }
    if (!isValid) {
      setState(() {});
      return;
    }

    final result = <String, dynamic>{
      for (var i = 0; i < widget.questions.length; i++)
        widget.questions[i]: _controllers[i].text.trim(),
    };
    setState(() => _isSubmitting = true);

    // Cho TextField/FocusScope hoàn tất frame hiện tại trước khi tháo route.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _close(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.instruction),
            const SizedBox(height: 16),
            ...List.generate(
              widget.questions.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[index],
                  maxLines: 2,
                  onChanged: (_) {
                    if (_validationErrors[index] != null) {
                      setState(() => _validationErrors[index] = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: widget.questions[index],
                    border: const OutlineInputBorder(),
                    errorText: _validationErrors[index],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _close,
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
