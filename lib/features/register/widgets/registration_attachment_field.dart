import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/registration_attachment_provider.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _bytesPerMb = 1024 * 1024;

/// Backend hard limit (`MaxFileSizeValidator`); a field may only lower it.
const _maxAttachmentMb = 10;

/// File input for a FILE custom field of the advanced registration form.
///
/// Uploads right after the file is picked (like the Web form) and reports the
/// stored attachment through [onChanged]; [onUploadingChanged] lets the screen
/// lock its submit button while a file is in flight.
class RegistrationAttachmentField extends ConsumerStatefulWidget {
  const RegistrationAttachmentField({
    super.key,
    required this.tournamentId,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.onUploadingChanged,
    this.pickFile,
  });

  final String tournamentId;

  /// The form field definition (`id`, `label`, `required`, `maxFileSizeMb`...).
  final Map<String, dynamic> field;

  /// The attachment currently stored in `customResponses`, if any.
  final Object? value;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final ValueChanged<bool> onUploadingChanged;

  /// Picker override for tests; defaults to the platform file picker.
  final Future<PlatformFile?> Function()? pickFile;

  @override
  ConsumerState<RegistrationAttachmentField> createState() =>
      _RegistrationAttachmentFieldState();
}

class _RegistrationAttachmentFieldState
    extends ConsumerState<RegistrationAttachmentField> {
  bool _uploading = false;
  String? _pickedName;
  int _pickedSize = 0;
  String? _error;

  num get _maxMb {
    final configured = widget.field['maxFileSizeMb'];
    return configured is num && configured > 0 && configured < _maxAttachmentMb
        ? configured
        : _maxAttachmentMb;
  }

  static Future<PlatformFile?> _pickWithPlatform() async {
    final result = await FilePicker.pickFiles();
    return result == null || result.files.isEmpty ? null : result.files.first;
  }

  Future<void> _choose() async {
    if (_uploading) return;
    final l10n = AppLocalizations.of(context)!;
    final PlatformFile? chosen;
    try {
      chosen = await (widget.pickFile ?? _pickWithPlatform)();
    } catch (_) {
      if (mounted) setState(() => _error = l10n.regAttachmentFailed);
      return;
    }
    final picked = chosen;
    if (!mounted || picked == null) return;
    if (picked.size > _maxMb * _bytesPerMb) {
      setState(() => _error = l10n.regAttachmentTooLarge(_maxMb));
      return;
    }

    setState(() {
      _uploading = true;
      _pickedName = picked.name;
      _pickedSize = picked.size;
      _error = null;
    });
    widget.onUploadingChanged(true);
    try {
      final bytes = await picked.readAsBytes();
      final attachment = await ref
          .read(registrationAttachmentRepositoryProvider)
          .upload(
            tournamentId: widget.tournamentId,
            fieldId: widget.field['id']?.toString() ?? '',
            bytes: bytes,
            fileName: picked.name,
          );
      if (!mounted) return;
      widget.onChanged(attachment);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(e, l10n));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
        widget.onUploadingChanged(false);
      }
    }
  }

  String _errorMessage(Object error, AppLocalizations l10n) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return l10n.regAttachmentNetworkError;
        default:
          break;
      }
      final status = error.response?.statusCode;
      if (status == 413) return l10n.regAttachmentTooLarge(_maxMb);
      final data = error.response?.data;
      final reason = data is Map ? data['message'] : null;
      // The server is the source of truth for rules the app cannot know
      // (accepted file types, form not published...).
      if (status == 400 && reason is String && reason.isNotEmpty) return reason;
    }
    return l10n.regAttachmentFailed;
  }

  void _remove() {
    setState(() => _error = null);
    widget.onChanged(null);
  }

  @override
  void dispose() {
    // The screen may outlive this field (e.g. division switched mid-upload);
    // release its submit lock once the tree is unlocked.
    if (_uploading) {
      final release = widget.onUploadingChanged;
      scheduleMicrotask(() => release(false));
    }
    super.dispose();
  }

  static String _formatSize(num bytes) {
    if (bytes >= _bytesPerMb) {
      return '${(bytes / _bytesPerMb).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final value = widget.value is Map ? widget.value as Map : null;
    final label = widget.field['label']?.toString() ?? '';
    final help = widget.field['helpText']?.toString();
    final required = widget.field['required'] == true;
    final hasFile = _uploading || value != null;
    final name = _uploading
        ? _pickedName
        : value?['originalName']?.toString() ?? _pickedName;
    final size = _uploading
        ? _pickedSize
        : (value?['size'] is num ? value!['size'] as num : _pickedSize);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label${required ? ' *' : ''}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (help != null && help.isNotEmpty)
            Text(
              help,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          const SizedBox(height: 6),
          if (hasFile)
            Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatSize(size),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('regAttachmentRemove'),
                    tooltip: l10n.regAttachmentRemove,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _uploading ? null : _remove,
                  ),
                ],
              ),
            ),
          if (_uploading) ...[
            const SizedBox(height: 6),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 4),
            Text(
              l10n.regAttachmentUploading,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: TextStyle(fontSize: 12, color: colors.error)),
          ],
          const SizedBox(height: 6),
          OutlinedButton.icon(
            key: const Key('regAttachmentChoose'),
            onPressed: _uploading ? null : _choose,
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(l10n.regAttachmentChoose),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.regAttachmentMaxSize(_maxMb),
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
