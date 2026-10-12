import 'package:flutter/material.dart';

/// A container colour with the colour to draw on top of it.
@immutable
class UrgencyPair {
  const UrgencyPair(this.container, this.onContainer);
  final Color container;
  final Color onContainer;

  static UrgencyPair lerp(UrgencyPair a, UrgencyPair b, double t) =>
      UrgencyPair(
        Color.lerp(a.container, b.container, t)!,
        Color.lerp(a.onContainer, b.onContainer, t)!,
      );
}

/// Colours of the four urgency levels, as a theme extension so every widget
/// reads them from the theme instead of hard-coding `Colors.red`.
///
/// Urgent, ok and muted come from the [ColorScheme] roles; "soon" (amber) has
/// no role in a teal scheme, so it is defined here per brightness. All pairs
/// are checked for WCAG AA contrast in `test/ui_contrast_test.dart`.
@immutable
class UrgencyColors extends ThemeExtension<UrgencyColors> {
  const UrgencyColors({
    required this.urgent,
    required this.soon,
    required this.ok,
    required this.muted,
    required this.caution,
  });

  final UrgencyPair urgent;
  final UrgencyPair soon;
  final UrgencyPair ok;
  final UrgencyPair muted;

  /// Text/border colour for "check this value" hints on the page surface.
  final Color caution;

  factory UrgencyColors.fromScheme(ColorScheme s) {
    final dark = s.brightness == Brightness.dark;
    return UrgencyColors(
      urgent: UrgencyPair(s.errorContainer, s.onErrorContainer),
      soon: dark
          ? const UrgencyPair(Color(0xFF5A3A00), Color(0xFFFFDDB0))
          : const UrgencyPair(Color(0xFFFFE2B8), Color(0xFF4D2F00)),
      ok: UrgencyPair(s.primaryContainer, s.onPrimaryContainer),
      muted: UrgencyPair(s.surfaceContainerHighest, s.onSurfaceVariant),
      caution: dark ? const Color(0xFFFFB95C) : const Color(0xFF8A4B00),
    );
  }

  @override
  UrgencyColors copyWith({
    UrgencyPair? urgent,
    UrgencyPair? soon,
    UrgencyPair? ok,
    UrgencyPair? muted,
    Color? caution,
  }) => UrgencyColors(
    urgent: urgent ?? this.urgent,
    soon: soon ?? this.soon,
    ok: ok ?? this.ok,
    muted: muted ?? this.muted,
    caution: caution ?? this.caution,
  );

  @override
  UrgencyColors lerp(ThemeExtension<UrgencyColors>? other, double t) {
    if (other is! UrgencyColors) return this;
    return UrgencyColors(
      urgent: UrgencyPair.lerp(urgent, other.urgent, t),
      soon: UrgencyPair.lerp(soon, other.soon, t),
      ok: UrgencyPair.lerp(ok, other.ok, t),
      muted: UrgencyPair.lerp(muted, other.muted, t),
      caution: Color.lerp(caution, other.caution, t)!,
    );
  }
}
