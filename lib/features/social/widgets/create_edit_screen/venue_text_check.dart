import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_place_input.dart';

/// What looks wrong in the venue name / venue address pair.
enum VenueTextHintCode {
  nameIsAddress,
  nameHasAddress,
  addressIsName,
  addressRepeatsName,
  sameText,
}

/// A hint plus the replacement for both fields ([next] is null when there is
/// nothing to apply, e.g. [VenueTextHintCode.sameText]).
class VenueTextHint {
  const VenueTextHint(this.code, [this.next]);

  final VenueTextHintCode code;
  final ({String name, String address})? next;
}

enum _Kind { name, address, mixed, unknown }

/// Whole words (tone-free) that mark a venue name.
final _nameSign = RegExp(
  r'\b(?:san|clb|cau lac bo|nha thi dau|trung tam|pickleball|tennis|cau long'
  r'|bong ban|bong da|cum san|khu the thao|san van dong)\b',
);

/// Address heads not covered by [looksLikeStreetAddress].
final _extraHead = RegExp(r'^(?:ngach|kiet|khu pho|ap|thon|xom)\b|^to \d');

/// Administrative words, matched as whole words only.
final _addressWord = RegExp(
  r'\b(?:phuong|xa|quan|huyen|thi xa|thanh pho|tinh|tp)\b',
);

/// "P.5", "Q.Tan Binh": the dot is lost after tone removal, so match raw text.
final _dottedAbbrev = RegExp(r'(?:^|\s)[pq]\.\s*[\p{L}\d]', unicode: true);

String _norm(String s) => VietnamAddressParser.removeVietnameseTones(s);

/// Classifies one comma-free segment. A leading digit is an address sign only
/// when the segment has no name sign ("Sân 79", "79 Sân Mộc" stay names).
_Kind _segmentKind(String seg) {
  final n = _norm(seg);
  if (n.isEmpty) return _Kind.unknown;
  final hasName = _nameSign.hasMatch(n);
  final isHead = RegExp(r'^\d').hasMatch(n)
      ? !hasName
      : _extraHead.hasMatch(n) || looksLikeStreetAddress(seg);
  if (isHead) return _Kind.address;
  if (hasName) return _Kind.name;
  if (_addressWord.hasMatch(n) || _dottedAbbrev.hasMatch(seg.toLowerCase())) {
    return _Kind.address;
  }
  return _Kind.unknown;
}

/// For [_Kind.mixed] the field is `head` (venue name) + `rest` (address).
({_Kind kind, String head, String rest}) _analyze(String text) {
  final segs = text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (segs.isEmpty) return (kind: _Kind.unknown, head: '', rest: '');
  final kinds = segs.map(_segmentKind).toList();
  final laterAddress = kinds.skip(1).contains(_Kind.address);
  if (kinds.first == _Kind.name) {
    return laterAddress
        ? (kind: _Kind.mixed, head: segs.first, rest: segs.skip(1).join(', '))
        : (kind: _Kind.name, head: text, rest: '');
  }
  final isAddress = kinds.first == _Kind.address || laterAddress;
  return (kind: isAddress ? _Kind.address : _Kind.unknown, head: '', rest: '');
}

/// Address text left after dropping a leading copy of [name] and the
/// separator after it; null when [address] does not start with [name].
String? _withoutLeadingName(String name, String address) {
  if (name.length < 3 || address.length <= name.length) return null;
  if (!address.toLowerCase().startsWith(name.toLowerCase())) return null;
  final rest = address.substring(name.length);
  final stripped = rest.replaceFirst(RegExp(r'^[\s,;:\-–—.]+'), '');
  // No separator after the name means a longer word ("Sân 7" vs "Sân 79").
  if (stripped.isEmpty || stripped.length == rest.length) return null;
  return stripped;
}

/// Spots a venue name typed as an address, an address typed as a name, or
/// one text repeated in both fields. Same rules as the Web form.
VenueTextHint? checkVenueFields(String name, String address) {
  final n = name.trim();
  final a = address.trim();
  if (n.isEmpty && a.isEmpty) return null;

  final normName = _norm(n);
  if (normName.isNotEmpty && normName == _norm(a)) {
    return const VenueTextHint(VenueTextHintCode.sameText);
  }

  final nameField = _analyze(n);
  if (nameField.kind == _Kind.mixed) {
    return VenueTextHint(VenueTextHintCode.nameHasAddress, (
      name: nameField.head,
      address: a.isEmpty ? nameField.rest : '${nameField.rest}, $a',
    ));
  }
  if (nameField.kind == _Kind.address) {
    return VenueTextHint(VenueTextHintCode.nameIsAddress, (
      name: a,
      address: n,
    ));
  }

  final trimmed = _withoutLeadingName(n, a);
  if (trimmed != null) {
    return VenueTextHint(VenueTextHintCode.addressRepeatsName, (
      name: n,
      address: trimmed,
    ));
  }

  if (a.isNotEmpty && _analyze(a).kind == _Kind.name) {
    return VenueTextHint(VenueTextHintCode.addressIsName, (
      name: a,
      address: n,
    ));
  }
  return null;
}
