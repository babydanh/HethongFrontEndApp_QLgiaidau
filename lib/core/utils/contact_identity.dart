/// Shared login-identifier and contact-privacy helpers.
///
/// Mirrors Backend `src/common/utils/phone.ts`: the server stays the source of
/// truth (it normalizes what the client sends); these helpers only decide what
/// the user typed and how contact data is shown.
library;

enum ContactKind { email, phone, invalid }

const _mask = '•';
final _separators = RegExp(r'[\s.\-()]');
final _vnMobile = RegExp(r'^(?:\+84|0)[35789]\d{8}$');
final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// `0987…`, `84987…`, `+84987…` (spaces, dots, dashes, brackets allowed) ->
/// `+84987654321`; null for anything else, landlines included.
String? normalizeVnPhone(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(_separators, '');
  if (RegExp(r'^84\d{9}$').hasMatch(digits)) digits = '+$digits';
  if (!_vnMobile.hasMatch(digits)) return null;
  return '+84${digits.substring(digits.length - 9)}';
}

/// Input containing `@` is an email; otherwise it must be a VN mobile number.
ContactKind classifyIdentifier(String raw) {
  final trimmed = raw.trim();
  if (trimmed.contains('@')) {
    return _email.hasMatch(trimmed) ? ContactKind.email : ContactKind.invalid;
  }
  return normalizeVnPhone(trimmed) == null
      ? ContactKind.invalid
      : ContactKind.phone;
}

/// `+84987654321` -> `+84 98• ••• 321`. Values the API already masked are
/// kept; unparseable values are never echoed.
String? maskPhone(String? v) {
  if (v == null || v.isEmpty) return null;
  if (v.contains(_mask)) return v;
  final e164 = normalizeVnPhone(v);
  if (e164 == null) return _mask * 3;
  final d = e164.substring(e164.length - 9);
  return '+84 ${d.substring(0, 2)}$_mask ${_mask * 3} ${d.substring(6)}';
}

/// `abc@gmail.com` -> `a••@gmail.com`; values without a local part and `@`
/// are never echoed.
String? maskEmail(String? v) {
  if (v == null || v.isEmpty) return null;
  final at = v.lastIndexOf('@');
  if (at < 1) return _mask * 3;
  return '${v[0]}${_mask * 2}${v.substring(at)}';
}

/// Masked contact line for a person: email first, then phone, else empty.
String displayContact({String? email, String? phone}) {
  final trimmedEmail = email?.trim() ?? '';
  if (trimmedEmail.isNotEmpty) return maskEmail(trimmedEmail)!;
  return maskPhone(phone?.trim()) ?? '';
}
