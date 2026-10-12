import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/ui/theme.dart';
import 'package:tempusfugit/ui/urgency_colors.dart';
import 'package:tempusfugit/ui/widgets/merchant_avatar.dart';

import 'support/contrast.dart';

void main() {
  // WCAG 2.2 AA: 4.5:1 for text, 3:1 for graphics and large text.
  const text = 4.5;

  test('the contrast helper matches known WCAG values', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.01));
    // #767676 on white is the classic AA threshold (4.54:1).
    expect(contrastRatio(const Color(0xFF767676), Colors.white), closeTo(4.54, 0.02));
  });

  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      final theme = buildTheme(brightness);
      final scheme = theme.colorScheme;
      final urgency = theme.extension<UrgencyColors>()!;

      test('every urgency level has AA text contrast on its container', () {
        final pairs = {
          'urgent': urgency.urgent,
          'soon': urgency.soon,
          'ok': urgency.ok,
          'muted': urgency.muted,
        };
        for (final e in pairs.entries) {
          expect(contrastRatio(e.value.onContainer, e.value.container),
              greaterThanOrEqualTo(text),
              reason: '${e.key} on its container');
        }
      });

      test('urgency containers stand out from the page background', () {
        // A coloured chip has to be visible on the surface it sits on.
        for (final p in [urgency.urgent, urgency.soon, urgency.ok]) {
          expect(contrastRatio(p.container, scheme.surface), greaterThan(1.1));
        }
      });

      test('body text, secondary text, links and errors are readable on the surface', () {
        expect(contrastRatio(scheme.onSurface, scheme.surface), greaterThanOrEqualTo(text));
        expect(contrastRatio(scheme.onSurfaceVariant, scheme.surface), greaterThanOrEqualTo(text));
        expect(contrastRatio(scheme.primary, scheme.surface), greaterThanOrEqualTo(text));
        expect(contrastRatio(scheme.error, scheme.surface), greaterThanOrEqualTo(text));
      });

      test('text on cards (surfaceContainerLow) is readable', () {
        expect(contrastRatio(scheme.onSurface, scheme.surfaceContainerLow), greaterThanOrEqualTo(text));
        expect(contrastRatio(scheme.onSurfaceVariant, scheme.surfaceContainerLow), greaterThanOrEqualTo(text));
      });

      test('the AI and uncertain hints are readable on the form surface', () {
        // Used for the helper text under fields (see coupon_form_page.dart).
        expect(contrastRatio(scheme.tertiary, scheme.surface), greaterThanOrEqualTo(text));
        expect(contrastRatio(scheme.secondary, scheme.surface), greaterThanOrEqualTo(text));
      });

      test('filled buttons have AA contrast', () {
        expect(contrastRatio(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(text));
        expect(contrastRatio(scheme.onSecondaryContainer, scheme.secondaryContainer),
            greaterThanOrEqualTo(text));
      });

      test('merchant avatar letters have AA contrast for any name', () {
        final names = [
          for (var i = 0; i < 400; i++) 'Negozio $i',
          'Zara', 'Esselunga', "McDonald's", 'H&M', 'IKEA', 'Bar Centrale', 'à',
        ];
        for (final n in names) {
          final c = avatarColors(n, brightness);
          expect(contrastRatio(c.foreground, c.background), greaterThanOrEqualTo(text),
              reason: n);
        }
      });
    });
  }

  test('the barcode card keeps dark-on-light in both themes', () {
    expect(contrastRatio(codeInk, codeSurface), closeTo(21, 0.01));
  });

  test('avatar colours are stable per name and differ across names', () {
    expect(avatarColors('Lidl', Brightness.light).background,
        avatarColors('lidl', Brightness.light).background);
    final hues = {
      for (final n in ['Zara', 'Esselunga', 'IKEA', 'Lidl', 'Coop', 'Conad'])
        avatarColors(n, Brightness.light).background,
    };
    expect(hues.length, greaterThan(3));
  });

  test('avatar letters', () {
    expect(avatarLetter('zara'), 'Z');
    expect(avatarLetter('  -- ikea'), 'I');
    expect(avatarLetter('èclair'), 'È');
    expect(avatarLetter(''), '?');
    expect(avatarLetter('€€'), '?');
  });
}
