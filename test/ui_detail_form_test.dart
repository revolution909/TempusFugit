import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/extraction/rule_extractor.dart';
import 'package:tempusfugit/features/form/coupon_form_page.dart';
import 'package:tempusfugit/providers.dart';

import 'support/app_harness.dart';

void main() {
  late AppHarness h;

  setUpAll(AppHarness.init);
  setUp(() => h = AppHarness());

  Future<void> openDetail(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  group('detail', () {
    testWidgets('with a code: checkout and "used" actions are in the bottom bar',
        (tester) async {
      await h.seed([sample('a', title: 'Con codice', daysLeft: 5, code: '4006381333931', format: 'ean13')]);
      await h.pump(tester);
      await openDetail(tester, 'Con codice');

      expect(find.text('Mostra in cassa'), findsOneWidget);
      expect(find.text('Segna come usato'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('without a code there is nothing to show at the till', (tester) async {
      await h.seed([sample('a', title: 'Senza codice', daysLeft: 5)]);
      await h.pump(tester);
      await openDetail(tester, 'Senza codice');

      expect(find.text('Mostra in cassa'), findsNothing);
      expect(find.text('Segna come usato'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('a used coupon only offers to reactivate it', (tester) async {
      await h.seed([sample('a', title: 'Usato ieri', daysLeft: 5, code: 'ABC12345', status: CouponStatus.used)]);
      await h.pump(tester);
      await tester.tap(find.text('Usati (1)'));
      await tester.pumpAndSettle();
      await openDetail(tester, 'Usato ieri');

      expect(find.text('Riattiva'), findsOneWidget);
      expect(find.text('Mostra in cassa'), findsNothing);
      expect(find.text('Segna come usato'), findsNothing);
      await h.unmount(tester);
    });

    testWidgets('the banner says when it expires; no banner date without expiry',
        (tester) async {
      await h.seed([
        sample('a', title: 'Scade', daysLeft: 2),
        sample('b', title: 'Eterno'),
      ]);
      await h.pump(tester, size: const Size(360, 1200));

      await openDetail(tester, 'Scade');
      expect(find.text('Scade tra 2 giorni'), findsWidgets);
      expect(find.textContaining('20'), findsWidgets); // the formatted date
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await openDetail(tester, 'Eterno');
      expect(find.text('Senza scadenza'), findsWidgets);
      await h.unmount(tester);
    });

    testWidgets('mark as used from the detail, with undo', (tester) async {
      await h.seed([sample('a', title: 'Da usare', daysLeft: 5)]);
      await h.pump(tester);
      await openDetail(tester, 'Da usare');

      await tester.tap(find.text('Segna come usato'));
      await tester.pumpAndSettle();
      expect((await h.repo.get('a'))!.isUsed, isTrue);
      expect(find.text('Riattiva'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect((await h.repo.get('a'))!.isUsed, isFalse);
      await h.unmount(tester);
    });

    testWidgets('a valid barcode is drawn; the number is always shown',
        (tester) async {
      await h.seed([sample('a', title: 'Valido', daysLeft: 5, code: '4006381333931', format: 'ean13')]);
      await h.pump(tester);
      await openDetail(tester, 'Valido');

      expect(find.byType(BarcodeWidget), findsOneWidget);
      expect(find.text('4006381333931'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('an undrawable barcode falls back to the number, no empty box',
        (tester) async {
      // Wrong EAN-13 check digit: cannot be redrawn.
      await h.seed([sample('a', title: 'Rotto', daysLeft: 5, code: '4006381333932', format: 'ean13')]);
      await h.pump(tester);
      await openDetail(tester, 'Rotto');

      expect(find.byType(BarcodeWidget), findsNothing);
      expect(find.text('4006381333932'), findsOneWidget);
      expect(find.textContaining('leggi il numero alla cassa'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('a promo code is shown as text without a barcode', (tester) async {
      await h.seed([sample('a', title: 'Promo', daysLeft: 5, code: 'SCONTO20')]);
      await h.pump(tester);
      await openDetail(tester, 'Promo');

      expect(find.byType(BarcodeWidget), findsNothing);
      expect(find.text('SCONTO20'), findsOneWidget);
      expect(find.textContaining('leggi il numero'), findsNothing);
      await h.unmount(tester);
    });

    testWidgets('the code can be copied', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await h.seed([sample('a', title: 'Copia', daysLeft: 5, code: 'SCONTO20')]);
      await h.pump(tester);
      await openDetail(tester, 'Copia');

      await tester.tap(find.text('Copia codice'));
      await tester.pumpAndSettle();

      expect(copied, 'SCONTO20');
      expect(find.text('Codice copiato'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('a long code is scaled to one line instead of wrapping',
        (tester) async {
      await h.seed([sample('a', title: 'Lungo', daysLeft: 5, code: '4006381333931', format: 'ean13')]);
      await h.pump(tester, textScale: 2.0);
      await openDetail(tester, 'Lungo');

      final code = find.text('4006381333931');
      expect(code, findsOneWidget);
      // One line: the text box is not taller than a single scaled line.
      expect(tester.getSize(code).height, lessThan(80));
      await h.unmount(tester);
    });
  });

  group('checkout view', () {
    testWidgets('opens from the code card and from the button', (tester) async {
      await h.seed([sample('a', title: 'Cassa', daysLeft: 5, code: 'PROMO1234')]);
      await h.pump(tester);
      await openDetail(tester, 'Cassa');

      await tester.tap(find.text('PROMO1234'));
      await tester.pumpAndSettle();
      expect(find.text('Fatto: segna come usato'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mostra in cassa'));
      await tester.pumpAndSettle();
      expect(find.text('Fatto: segna come usato'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('"Fatto" marks it used and returns, with undo', (tester) async {
      await h.seed([sample('a', title: 'Cassa', daysLeft: 5, code: 'PROMO1234')]);
      await h.pump(tester);
      await openDetail(tester, 'Cassa');
      await tester.tap(find.text('Mostra in cassa'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fatto: segna come usato'));
      await tester.pumpAndSettle();

      expect((await h.repo.get('a'))!.isUsed, isTrue);
      expect(find.text('Fatto: segna come usato'), findsNothing);
      expect(find.text('Segnato come usato'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect((await h.repo.get('a'))!.isUsed, isFalse);
      await h.unmount(tester);
    });

    testWidgets('stays light in dark mode so readers can scan it', (tester) async {
      await h.seed([sample('a', title: 'Notte', daysLeft: 5, code: 'PROMO1234')]);
      await h.pump(tester, brightness: Brightness.dark);
      await openDetail(tester, 'Notte');
      await tester.tap(find.text('Mostra in cassa'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.backgroundColor, Colors.white);
      await h.unmount(tester);
    });
  });

  group('form', () {
    Future<void> openManualForm(WidgetTester tester) async {
      await tester.tap(find.text('Aggiungi il primo coupon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inserisci a mano'));
      await tester.pumpAndSettle();
    }

    testWidgets('the shop field has focus when adding by hand', (tester) async {
      await h.pump(tester);
      await openManualForm(tester);

      final field = tester.widget<EditableText>(find
          .descendant(
              of: find.widgetWithText(TextFormField, 'Negozio / marchio *'),
              matching: find.byType(EditableText))
          .first);
      expect(field.focusNode.hasFocus, isTrue);
      await h.unmount(tester);
    });

    testWidgets('leaving untouched needs no confirmation', (tester) async {
      await h.pump(tester);
      await openManualForm(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Scartare le modifiche?'), findsNothing);
      expect(find.text('Nuovo coupon'), findsNothing);
      await h.unmount(tester);
    });

    testWidgets('leaving with typed data asks first; both answers work',
        (tester) async {
      await h.pump(tester);
      await openManualForm(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Negozio / marchio *'), 'Coop');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Scartare le modifiche?'), findsOneWidget);

      await tester.tap(find.text('Continua a modificare'));
      await tester.pumpAndSettle();
      expect(find.text('Nuovo coupon'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scarta'));
      await tester.pumpAndSettle();
      expect(find.text('Nuovo coupon'), findsNothing);
      expect(await h.repo.getAll(), isEmpty);
      await h.unmount(tester);
    });

    testWidgets('a change of date or type also counts as an edit', (tester) async {
      await h.pump(tester);
      await openManualForm(tester);

      await tester.tap(find.text('+7 giorni'));
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Scartare le modifiche?'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('saving does not ask for confirmation', (tester) async {
      await h.pump(tester);
      await openManualForm(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Negozio / marchio *'), 'Coop');
      await tester.enterText(find.widgetWithText(TextFormField, 'Titolo'), 'Sconto');
      await tester.tap(find.text('Salva coupon'));
      await tester.pumpAndSettle();

      expect(find.text('Scartare le modifiche?'), findsNothing);
      expect((await h.repo.getAll()).single.merchant, 'Coop');
      await h.unmount(tester);
    });

    testWidgets('a scanned coupon is protected before the user types anything',
        (tester) async {
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = const Size(720, 1560);
      addTearDown(tester.view.reset);
      const text = 'Lidl buono sconto 10 € valido fino al 31/12/2026';
      final draft = CouponDraft(
        rawText: text,
        extracted: RuleExtractor().extract(text, now: DateTime(2026, 10, 12)),
        codeValue: '4006381333931',
        codeFormat: 'ean13',
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(h.db),
          llmExtractorProvider.overrideWithValue(h.llm),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CouponFormPage(draft: draft))),
                  child: const Text('apri'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Scartare le modifiche?'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('money fields accept only digits, comma and dot', (tester) async {
      await h.pump(tester, size: const Size(360, 1800));
      await openManualForm(tester);

      final minSpend = find.widgetWithText(TextFormField, 'Spesa minima (facoltativo)');
      await tester.ensureVisible(minSpend);
      await tester.enterText(minSpend, 'ab4c0,5x');
      await tester.pump();
      expect(tester.widget<TextFormField>(minSpend).controller!.text, '40,5');
      await h.unmount(tester);
    });

    testWidgets('percent shows a % suffix, amount shows a € prefix', (tester) async {
      await h.pump(tester);
      await openManualForm(tester);

      await tester.tap(find.text('Altro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Percentuale %').last);
      await tester.pumpAndSettle();
      expect(find.text('%'), findsOneWidget);

      await tester.tap(find.text('Percentuale %'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importo €').last);
      await tester.pumpAndSettle();
      expect(find.text('€ '), findsWidgets);
      await h.unmount(tester);
    });

    testWidgets('at very large text the discount fields stack, no overflow',
        (tester) async {
      await h.pump(tester, size: const Size(360, 640), textScale: 2.0);
      await openManualForm(tester);

      await tester.tap(find.text('Altro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Percentuale %').last);
      await tester.pumpAndSettle();

      final type = tester.getTopLeft(find.widgetWithText(DropdownButtonFormField<DiscountType>, 'Percentuale %'));
      final value = tester.getTopLeft(find.widgetWithText(TextFormField, 'Valore'));
      expect(value.dy, greaterThan(type.dy)); // below, not beside
      expect(tester.takeException(), isNull);
      await h.unmount(tester);
    });

    testWidgets('the back gesture on Android is not blocked once saved',
        (tester) async {
      await h.pump(tester);
      await openManualForm(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Negozio / marchio *'), 'Coop');
      await tester.enterText(find.widgetWithText(TextFormField, 'Titolo'), 'Sconto');
      await tester.tap(find.text('Salva coupon'));
      await tester.pumpAndSettle();

      // Back on the list: a system back press must not trigger a dialog.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Scartare le modifiche?'), findsNothing);
      await h.unmount(tester);
    });
  });
}
