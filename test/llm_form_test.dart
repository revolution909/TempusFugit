import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempusfugit/data/database.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/extraction/rule_extractor.dart';
import 'package:tempusfugit/features/form/coupon_form_page.dart';
import 'package:tempusfugit/llm/llm_extractor.dart';
import 'package:tempusfugit/providers.dart';

import 'fake_llm.dart';

const aiHint = "Suggerito dall'AI: controlla";

void main() {
  late AppDatabase db;
  late FakeLlm llm;

  setUpAll(() async {
    await initializeDateFormatting('it');
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'llm_enabled': true});
    db = AppDatabase(NativeDatabase.memory());
    llm = FakeLlm();
  });

  // Text the rules cannot make sense of: merchant, expiry and discount are gaps.
  const vagueText =
      'Offerta speciale per te, passa in negozio questa settimana';
  CouponDraft vagueDraft({String? codeValue, String? codeFormat}) =>
      CouponDraft(
        rawText: vagueText,
        extracted: RuleExtractor().extract(
          vagueText,
          now: DateTime(2026, 10, 12),
        ),
        codeValue: codeValue,
        codeFormat: codeFormat,
      );

  Future<void> pumpForm(WidgetTester tester, CouponDraft draft) async {
    // Tall screen: the form is a lazy ListView, so fields below the fold would
    // not be built (and could not be found) on the default 600px surface.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          llmExtractorProvider.overrideWithValue(llm),
        ],
        child: MaterialApp(home: CouponFormPage(draft: draft)),
      ),
    );
    // Let the async enabled-flag / status lookups complete.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  String text(WidgetTester tester, String label) => tester
      .widget<TextFormField>(find.widgetWithText(TextFormField, label))
      .controller!
      .text;

  Future<void> finish(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final aiResult = ExtractedCoupon(
    merchant: 'Bella Napoli',
    title: '2x1 il martedì',
    discountType: DiscountType.twoForOne,
    expiresAt: DateTime(2031, 1, 5),
    minSpend: 30,
    conditions: 'Escluso festivi.',
    codeValue: 'NAPOLI2X1',
    uncertain: const {'expiresAt'},
  );

  testWidgets('the form opens at once; the AI result fills the gaps later', (
    tester,
  ) async {
    llm.gate = Completer();
    await pumpForm(tester, vagueDraft());

    expect(llm.extractCalls, 1);
    expect(find.text("L'AI sta leggendo il testo…"), findsOneWidget);
    expect(text(tester, 'Negozio / marchio *'), '');

    llm.gate!.complete(aiResult);
    await finish(tester);

    expect(find.text("L'AI sta leggendo il testo…"), findsNothing);
    expect(text(tester, 'Negozio / marchio *'), 'Bella Napoli');
    expect(text(tester, 'Titolo'), '2x1 il martedì');
    expect(text(tester, 'Spesa minima (facoltativo)'), '30');
    expect(text(tester, 'Condizioni (facoltativo)'), 'Escluso festivi.');
    expect(text(tester, 'Codice'), 'NAPOLI2X1');
    expect(find.textContaining('2031'), findsOneWidget);
    expect(find.text(aiHint), findsWidgets);
    await unmount(tester);
  });

  testWidgets('a field the user already edited is never overwritten', (
    tester,
  ) async {
    llm.gate = Completer();
    await pumpForm(tester, vagueDraft());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Negozio / marchio *'),
      'Mio Negozio',
    );
    await tester.pump();
    llm.gate!.complete(aiResult);
    await finish(tester);

    expect(text(tester, 'Negozio / marchio *'), 'Mio Negozio');
    expect(text(tester, 'Titolo'), '2x1 il martedì'); // untouched: still filled
    await unmount(tester);
  });

  testWidgets('an expiry chosen by the user is kept', (tester) async {
    llm.gate = Completer();
    await pumpForm(tester, vagueDraft());

    await tester.tap(find.text('+7 giorni'));
    await tester.pump();
    llm.gate!.complete(aiResult);
    await finish(tester);

    expect(find.textContaining('2031'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a scanned barcode is not replaced by a code the AI read', (
    tester,
  ) async {
    llm.result = aiResult;
    await pumpForm(
      tester,
      vagueDraft(codeValue: '8001234567890', codeFormat: 'ean13'),
    );
    await finish(tester);

    expect(text(tester, 'Codice'), '8001234567890');
    expect(text(tester, 'Negozio / marchio *'), 'Bella Napoli');
    await unmount(tester);
  });

  testWidgets('leaving the screen before the result arrives is harmless', (
    tester,
  ) async {
    llm.gate = Completer();
    await pumpForm(tester, vagueDraft());

    await unmount(tester);
    llm.gate!.complete(aiResult);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the AI is never called when the setting is off', (tester) async {
    SharedPreferences.setMockInitialValues({'llm_enabled': false});
    llm.result = aiResult;
    await pumpForm(tester, vagueDraft());
    await finish(tester);

    expect(llm.extractCalls, 0);
    expect(text(tester, 'Negozio / marchio *'), '');
    await unmount(tester);
  });

  testWidgets('the AI is never called when no model is ready', (tester) async {
    llm.statusValue = const LlmNeedsDownload();
    llm.result = aiResult;
    await pumpForm(tester, vagueDraft());
    await finish(tester);

    expect(llm.extractCalls, 0);
    await unmount(tester);
  });

  testWidgets('the AI is skipped when the rules already found everything', (
    tester,
  ) async {
    const full = 'Lidl buono sconto 10 € valido fino al 31/12/2026';
    final draft = CouponDraft(
      rawText: full,
      extracted: RuleExtractor().extract(full, now: DateTime(2026, 10, 12)),
    );
    llm.result = aiResult;
    await pumpForm(tester, draft);
    await finish(tester);

    expect(llm.extractCalls, 0);
    expect(text(tester, 'Negozio / marchio *'), 'Lidl');
    await unmount(tester);
  });

  testWidgets('an extractor that throws leaves the rule-based form intact', (
    tester,
  ) async {
    llm.error = StateError('model crashed');
    await pumpForm(tester, vagueDraft());
    await finish(tester);

    expect(llm.extractCalls, 1);
    expect(find.text("L'AI sta leggendo il testo…"), findsNothing);
    expect(tester.takeException(), isNull);
    expect(text(tester, 'Negozio / marchio *'), '');
    await unmount(tester);
  });

  testWidgets('a null result changes nothing', (tester) async {
    llm.result = null;
    await pumpForm(tester, vagueDraft());
    await finish(tester);

    expect(text(tester, 'Negozio / marchio *'), '');
    expect(find.text(aiHint), findsNothing);
    await unmount(tester);
  });

  testWidgets('editing an existing coupon never runs the AI', (tester) async {
    final existing = Coupon(
      id: 'x',
      title: 't',
      merchant: 'm',
      kind: CouponKind.digital,
      createdAt: DateTime(2026, 1, 1),
    );
    llm.result = aiResult;
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          llmExtractorProvider.overrideWithValue(llm),
        ],
        child: MaterialApp(
          home: CouponFormPage(existing: existing, draft: vagueDraft()),
        ),
      ),
    );
    await finish(tester);

    expect(llm.extractCalls, 0);
    await unmount(tester);
  });
}
