import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/features/list/coupon_tile.dart';

import 'support/app_harness.dart';

/// The merged semantics node of a list row (the one a screen reader focuses).
final _rowSemantics = find.descendant(
  of: find.byType(CouponTile),
  matching: find.byWidgetPredicate(
    (w) => w is Semantics && (w.properties.button ?? false) && w.properties.label != null,
  ),
);

void main() {
  late AppHarness h;

  setUpAll(AppHarness.init);
  setUp(() => h = AppHarness());

  group('grouping and filters', () {
    testWidgets('active coupons are grouped by urgency, soonest group first',
        (tester) async {
      await h.seed([
        sample('a', title: 'Presto', daysLeft: 1),
        sample('b', title: 'Settimana', daysLeft: 6),
        sample('c', title: 'Mese', daysLeft: 20),
        sample('d', title: 'Lontano', daysLeft: 60),
        sample('e', title: 'Senza data'),
      ]);
      await h.pump(tester, size: const Size(360, 1800));

      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(find.text('Scadono presto · 1'), findsOneWidget);
      expect(find.text('Questa settimana · 1'), findsOneWidget);
      expect(find.text('Questo mese · 1'), findsOneWidget);
      expect(find.text('Più avanti · 1'), findsOneWidget);
      expect(find.text('Senza scadenza · 1'), findsOneWidget);
      expect(y('Scadono presto · 1'), lessThan(y('Questa settimana · 1')));
      expect(y('Questa settimana · 1'), lessThan(y('Questo mese · 1')));
      expect(y('Questo mese · 1'), lessThan(y('Più avanti · 1')));
      expect(y('Più avanti · 1'), lessThan(y('Senza scadenza · 1')));
      await h.unmount(tester);
    });

    testWidgets('group headers are announced as headers', (tester) async {
      await h.seed([sample('a', daysLeft: 1)]);
      final handle = tester.ensureSemantics();
      await h.pump(tester);

      final node = tester.getSemantics(find.text('Scadono presto · 1'));
      expect(node.flagsCollection.isHeader, isTrue);
      handle.dispose();
      await h.unmount(tester);
    });

    testWidgets('tabs show expired and used coupons with counts', (tester) async {
      await h.seed([
        sample('a', title: 'Attivo', daysLeft: 5),
        sample('b', title: 'Vecchio', daysLeft: -3),
        sample('c', title: 'Consumato', daysLeft: 5, status: CouponStatus.used),
      ]);
      await h.pump(tester);

      expect(find.text('Attivi (1)'), findsOneWidget);
      expect(find.text('Scaduti (1)'), findsOneWidget);
      expect(find.text('Usati (1)'), findsOneWidget);

      await tester.tap(find.text('Scaduti (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Vecchio'), findsOneWidget);
      expect(find.text('Attivo'), findsNothing);

      await tester.tap(find.text('Usati (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Consumato'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('each empty tab explains itself', (tester) async {
      await h.seed([sample('a', daysLeft: 5)]);
      await h.pump(tester);

      await tester.tap(find.text('Scaduti (0)'));
      await tester.pumpAndSettle();
      expect(find.text('Nessun coupon scaduto'), findsOneWidget);

      await tester.tap(find.text('Usati (0)'));
      await tester.pumpAndSettle();
      expect(find.text('Nessun coupon usato'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('with only expired coupons the active tab says so', (tester) async {
      await h.seed([sample('a', daysLeft: -2)]);
      await h.pump(tester);
      expect(find.text('Nessun coupon attivo'), findsOneWidget);
      await h.unmount(tester);
    });
  });

  group('search', () {
    testWidgets('filters by merchant, ignoring case and accents', (tester) async {
      await h.seed([
        sample('a', merchant: 'Zara', title: 'Sconto', daysLeft: 3),
        sample('b', merchant: 'Bar Centrale', title: 'Caffè in omaggio', daysLeft: 4),
      ]);
      await h.pump(tester);

      await tester.enterText(find.byType(TextField), 'CAFFE');
      await tester.pumpAndSettle();
      expect(find.text('Caffè in omaggio'), findsOneWidget);
      expect(find.text('Sconto'), findsNothing);

      await tester.tap(find.byTooltip('Cancella ricerca'));
      await tester.pumpAndSettle();
      expect(find.text('Sconto'), findsOneWidget);
      expect(find.text('Caffè in omaggio'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('no match shows a message that quotes the query', (tester) async {
      await h.seed([sample('a', daysLeft: 3)]);
      await h.pump(tester);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('Nessun risultato'), findsOneWidget);
      expect(find.textContaining('«zzzz»'), findsOneWidget);
      await h.unmount(tester);
    });
  });

  group('swipe and long press', () {
    testWidgets('swipe right marks as used; Annulla brings it back', (tester) async {
      await h.seed([sample('a', title: 'Da usare', daysLeft: 5)]);
      await h.pump(tester);

      await tester.drag(find.text('Da usare'), const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usato'));
      await tester.pumpAndSettle();

      expect(find.text('Segnato come usato'), findsOneWidget);
      expect(find.text('Attivi (0)'), findsOneWidget);
      expect(find.text('Usati (1)'), findsOneWidget);
      expect((await h.repo.get('a'))!.isUsed, isTrue);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect((await h.repo.get('a'))!.isUsed, isFalse);
      expect(find.text('Attivi (1)'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('swipe left deletes; Annulla restores it intact', (tester) async {
      await h.seed([
        sample('a', title: 'Da eliminare', daysLeft: 5, code: 'ABC123', tag: 'regalo'),
      ]);
      await h.pump(tester);

      await tester.drag(find.text('Da eliminare'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.text('Coupon eliminato'), findsOneWidget);
      expect(await h.repo.get('a'), isNull);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      final back = (await h.repo.get('a'))!;
      expect(back.title, 'Da eliminare');
      expect(back.codeValue, 'ABC123');
      expect(back.tag, 'regalo');
      await h.unmount(tester);
    });

    testWidgets('a used coupon offers "Riattiva" instead', (tester) async {
      await h.seed([sample('a', title: 'Gia usato', daysLeft: 5, status: CouponStatus.used)]);
      await h.pump(tester);
      await tester.tap(find.text('Usati (1)'));
      await tester.pumpAndSettle();

      await tester.drag(find.text('Gia usato'), const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riattiva'));
      await tester.pumpAndSettle();

      expect((await h.repo.get('a'))!.isUsed, isFalse);
      expect(find.text('Coupon riattivato'), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('long press offers the same actions without swiping', (tester) async {
      await h.seed([sample('a', title: 'Lungo', daysLeft: 5)]);
      await h.pump(tester);

      await tester.longPress(find.text('Lungo'));
      await tester.pumpAndSettle();
      expect(find.text('Segna come usato'), findsOneWidget);
      expect(find.text('Modifica'), findsOneWidget);
      expect(find.text('Elimina'), findsOneWidget);

      await tester.tap(find.text('Segna come usato'));
      await tester.pumpAndSettle();
      expect((await h.repo.get('a'))!.isUsed, isTrue);
      await h.unmount(tester);
    });

    testWidgets('long press → Modifica opens the form for that coupon',
        (tester) async {
      await h.seed([sample('a', title: 'Da modificare', merchant: 'Coop', daysLeft: 5)]);
      await h.pump(tester);

      await tester.longPress(find.text('Da modificare'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifica'));
      await tester.pumpAndSettle();

      expect(find.text('Modifica coupon'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Titolo'), findsOneWidget);
      await h.unmount(tester);
    });
  });

  group('accessibility semantics', () {
    testWidgets('a row is one button with a full spoken label', (tester) async {
      await h.seed([
        sample('a',
            title: 'Buono 5 €',
            merchant: 'Esselunga',
            daysLeft: 2,
            kind: CouponKind.physical),
      ]);
      final handle = tester.ensureSemantics();
      await h.pump(tester);

      final data = tester.getSemantics(_rowSemantics).getSemanticsData();
      expect(data.label, contains('Buono 5 €'));
      expect(data.label, contains('Esselunga'));
      expect(data.label, contains('fisico'));
      expect(data.label, contains('Scade tra 2 giorni'));
      expect(data.flagsCollection.isButton, isTrue);
      handle.dispose();
      await h.unmount(tester);
    });

    testWidgets('swipe actions are exposed as screen-reader actions', (tester) async {
      await h.seed([sample('a', title: 'Azioni', daysLeft: 5)]);
      final handle = tester.ensureSemantics();
      await h.pump(tester);

      final data = tester.getSemantics(_rowSemantics).getSemanticsData();
      final labels = data.customSemanticsActionIds!
          .map((id) => CustomSemanticsAction.getAction(id)!.label)
          .toSet();
      expect(labels, {'Segna come usato', 'Elimina'});
      handle.dispose();
      await h.unmount(tester);
    });

    testWidgets('urgency is conveyed by an icon and text, not colour alone',
        (tester) async {
      await h.seed([
        sample('a', title: 'Urgente', daysLeft: 1),
        sample('b', title: 'Settimana', daysLeft: 6),
        sample('c', title: 'Lontano', daysLeft: 30),
      ]);
      await h.pump(tester, size: const Size(360, 1400));

      expect(find.byIcon(Icons.priority_high), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
      expect(find.text('Scade domani'), findsOneWidget);
      expect(find.text('Scade tra 6 giorni'), findsOneWidget);
      await h.unmount(tester);
    });
  });
}
