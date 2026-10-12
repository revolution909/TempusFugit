import 'package:flutter/material.dart';

/// Colours of the avatar for [name] in the given [brightness]. The hue is
/// derived from the name so a merchant always gets the same colour; lightness
/// and saturation are fixed so the letter keeps AA contrast (tested).
({Color background, Color foreground}) avatarColors(
  String name,
  Brightness brightness,
) {
  final hash = name.toLowerCase().codeUnits.fold<int>(
    7,
    (a, b) => (a * 31 + b) & 0xFFFF,
  );
  final hue = (hash % 360).toDouble();
  final dark = brightness == Brightness.dark;
  return (
    background: HSLColor.fromAHSL(1, hue, 0.35, dark ? 0.28 : 0.86).toColor(),
    foreground: HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.90 : 0.22).toColor(),
  );
}

String avatarLetter(String name) {
  for (final r in name.runes) {
    final ch = String.fromCharCode(r);
    if (RegExp(r'[A-Za-z0-9À-ÿ]').hasMatch(ch)) return ch.toUpperCase();
  }
  return '?';
}

/// Round letter avatar for a merchant. Decorative: screen readers get the
/// merchant name from the surrounding row instead.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = avatarColors(name, Theme.of(context).brightness);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.background,
          shape: BoxShape.circle,
        ),
        child: Text(
          avatarLetter(name),
          style: TextStyle(
            color: colors.foreground,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
