import 'dart:ui';

/// Colours of a schedule match card that depend on the division's gender
/// restriction. Mirrors the web `schedule-card-style.ts` (GENDER_TINTS):
/// blue / pink / teal / orange, none of which is the amber, violet or rose
/// already used for selection, draft and live, so a tint is never mistaken
/// for a state.
typedef ScheduleGenderTint = ({
  /// Full-height left stripe.
  Color stripe,

  /// Card outline.
  Color border,

  /// Header bar fill.
  Color header,

  /// Header bar text.
  Color headerText,
});

const _male = (
  stripe: Color(0xFF2563EB),
  border: Color(0xFF93C5FD),
  header: Color(0xFFDBEAFE),
  headerText: Color(0xFF1E3A8A),
);

const _female = (
  stripe: Color(0xFFEC4899),
  border: Color(0xFFF9A8D4),
  header: Color(0xFFFCE7F3),
  headerText: Color(0xFF831843),
);

const _mixed = (
  stripe: Color(0xFF0D9488),
  border: Color(0xFF5EEAD4),
  header: Color(0xFFCCFBF1),
  headerText: Color(0xFF134E4A),
);

const _flexible = (
  stripe: Color(0xFFEA580C),
  border: Color(0xFFFDBA74),
  header: Color(0xFFFFEDD5),
  headerText: Color(0xFF7C2D12),
);

/// Tint for a division's `genderRestriction`; no restriction (or an unknown
/// value) reads as "flexible".
ScheduleGenderTint scheduleGenderTint(String? genderRestriction) {
  return switch (genderRestriction?.trim().toUpperCase()) {
    'MALE' => _male,
    'FEMALE' => _female,
    'MIXED' => _mixed,
    _ => _flexible,
  };
}
