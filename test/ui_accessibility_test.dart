// Automated accessibility checks on every screen, in light and dark, plus a
// no-overflow check at the largest text size on a small phone.
//
// These use Flutter's own guidelines (tap-target size, labels, text contrast).
// They catch a lot, but they are no substitute for TalkBack / VoiceOver on a
// real device.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/llm/llm_extractor.dart';

import 'support/app_harness.dart';

typedef Scene = Future<void> Function(WidgetTester tester, AppHarness h);

/// Scroll to the end: the last rows then sit above the floating button. The
/// text-contrast guideline samples a node's whole rectangle, so a header left
/// under the button would be measured against the button's colour.
Future<void> _list(WidgetTester tester, AppHarness h) async {
  await tester.fling(find.byType(CustomScrollView), const Offset(0, -2000), 3000);
  await tester.pumpAndSettle();
}

Future<void> _empty(WidgetTester tester, AppHarness h) async {}

Future<void> _addSheet(WidgetTester tester, AppHarness h) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> _detail(WidgetTester tester, AppHarness h) async {
  await tester.ensureVisible(find.text('Buono 5 €'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Buono 5 €'));
  await tester.pumpAndSettle();
}

Future<void> _checkout(WidgetTester tester, AppHarness h) async {
  await _detail(tester, h);
  await tester.tap(find.text('Mostra in cassa'));
  await tester.pumpAndSettle();
}

Future<void> _form(WidgetTester tester, AppHarness h) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Inserisci a mano'));
  await tester.pumpAndSettle();
}

Future<void> _emptyForm(WidgetTester tester, AppHarness h) async {
  await tester.tap(find.text('Aggiungi il primo coupon'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Inserisci a mano'));
  await tester.pumpAndSettle();
}

Future<void> _settings(WidgetTester tester, AppHarness h) async {
  await tester.tap(find.byTooltip('Impostazioni'));
  await tester.pumpAndSettle();
}

Future<void> _longPressMenu(WidgetTester tester, AppHarness h) async {
  await tester.longPress(find.text('Sconto 20% su tutto'));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, AppHarness h) async {
  await tester.enterText(find.byType(TextField), 'zzz');
  // The focus ring is a border (primary on surface is checked in ui_contrast_test); the
  // text-contrast guideline would sample it as if it were text.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

final _coupons = [
  sample('1', title: 'Sconto 20% su tutto', merchant: 'Zara', daysLeft: 1, type: DiscountType.percent, value: 20, code: 'ZARA20'),
  sample('2', title: 'Buono 5 €', merchant: 'Esselunga', daysLeft: 2, kind: CouponKind.physical, code: '4006381333931', format: 'ean13'),
  sample('3', title: 'Offerta 2x1', merchant: 'Pizzeria Da Gigi', daysLeft: 6, type: DiscountType.twoForOne, value: null),
  sample('4', title: 'Sconto 15%', merchant: 'Decathlon', daysLeft: 18, type: DiscountType.percent, value: 15),
  sample('5', title: 'Senza data', merchant: 'Feltrinelli'),
  sample('6', title: 'Scaduto', merchant: 'H&M', daysLeft: -4),
];

void main() {
  late AppHarness h;

  setUpAll(AppHarness.init);

  final scenes = <String, ({Scene go, bool seeded, LlmStatus? llm})>{
    'list': (go: _list, seeded: true, llm: null),
    'list with search and no result': (go: _search, seeded: true, llm: null),
    'empty list': (go: _empty, seeded: false, llm: null),
    'add sheet': (go: _addSheet, seeded: true, llm: null),
    'long-press menu': (go: _longPressMenu, seeded: true, llm: null),
    'detail': (go: _detail, seeded: true, llm: null),
    'checkout': (go: _checkout, seeded: true, llm: null),
    'form': (go: _form, seeded: true, llm: null),
    'form from empty': (go: _emptyForm, seeded: false, llm: null),
    'settings': (go: _settings, seeded: true, llm: const LlmNeedsDownload()),
  };

  Future<void> open(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required double scale,
    required Size size,
  }) async {
    final s = scenes[name]!;
    h = AppHarness();
    if (s.seeded) await h.seed(_coupons);
    if (s.llm != null) h.llm.statusValue = s.llm!;
    await h.pump(tester, size: size, textScale: scale, brightness: brightness);
    await s.go(tester, h);
  }

  for (final brightness in Brightness.values) {
    group('guidelines, ${brightness.name} theme', () {
      for (final name in scenes.keys) {
        testWidgets(name, (tester) async {
          final handle = tester.ensureSemantics();
          await open(tester, name,
              brightness: brightness, scale: 1.0, size: const Size(360, 780));

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
          await h.unmount(tester);
        });
      }
    });
  }

  group('largest text on a small phone: nothing overflows or is cut off', () {
    for (final brightness in Brightness.values) {
      for (final name in scenes.keys) {
        testWidgets('$name (${brightness.name})', (tester) async {
          await open(tester, name,
              brightness: brightness, scale: 2.0, size: const Size(360, 640));
          // An overflow is reported as an exception during layout.
          expect(tester.takeException(), isNull);
          await h.unmount(tester);
        });
      }
    }
  });
}
