import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempusfugit/features/settings/settings_page.dart';
import 'package:tempusfugit/llm/llm_extractor.dart';
import 'package:tempusfugit/llm/llm_settings.dart';
import 'package:tempusfugit/providers.dart';

import 'fake_llm.dart';

void main() {
  late FakeLlm llm;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    llm = FakeLlm();
  });

  Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [llmExtractorProvider.overrideWithValue(llm)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('off by default; the switch is remembered', (tester) async {
    llm.statusValue = const LlmReady(LlmSource.downloaded);
    final container = await pumpSettings(tester);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(container.read(llmEnabledProvider).value, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('llm_enabled'),
      isTrue,
    );
  });

  testWidgets('shows the unavailable state with the reason', (tester) async {
    llm.statusValue = const LlmUnavailable(
      'Disponibile solo su Android e iOS.',
    );
    await pumpSettings(tester);

    expect(
      find.textContaining('Non disponibile su questo dispositivo'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Disponibile solo su Android e iOS.'),
      findsOneWidget,
    );
    expect(find.text('Scarica modello'), findsNothing);
  });

  testWidgets('the system model needs no download', (tester) async {
    llm.statusValue = const LlmReady(LlmSource.system);
    await pumpSettings(tester);

    expect(find.textContaining('modello del sistema'), findsOneWidget);
    expect(find.text('Scarica modello'), findsNothing);
    expect(find.text('Elimina modello'), findsNothing);
  });

  testWidgets(
    'download shows progress, then the ready state, and turns the AI on',
    (tester) async {
      llm.statusValue = const LlmNeedsDownload();
      final done = Completer<void>();
      llm.onDownload = (onProgress) async {
        onProgress?.call(40);
        await done.future;
      };
      final container = await pumpSettings(tester);

      expect(find.text('Scarica modello'), findsOneWidget);
      await tester.tap(find.text('Scarica modello'));
      await tester.pump();
      await tester.pump();

      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Annulla'), findsOneWidget);
      expect(find.text('Scarica modello'), findsNothing);

      llm.statusValue = const LlmReady(LlmSource.downloaded);
      done.complete();
      await tester.pumpAndSettle();

      expect(llm.downloadCalls, 1);
      expect(find.textContaining('modello scaricato'), findsOneWidget);
      expect(find.text('Elimina modello'), findsOneWidget);
      expect(container.read(llmEnabledProvider).value, isTrue);
    },
  );

  testWidgets('a failed download shows the error and allows a retry', (
    tester,
  ) async {
    llm.statusValue = const LlmNeedsDownload();
    llm.onDownload = (_) async => throw StateError('rete assente');
    await pumpSettings(tester);

    await tester.tap(find.text('Scarica modello'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Download non riuscito'), findsOneWidget);
    expect(find.text('Scarica modello'), findsOneWidget);
  });

  testWidgets('cancel reaches the extractor', (tester) async {
    llm.statusValue = const LlmNeedsDownload();
    final done = Completer<void>();
    llm.onDownload = (onProgress) async {
      onProgress?.call(10);
      await done.future;
    };
    await pumpSettings(tester);

    await tester.tap(find.text('Scarica modello'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Annulla'));
    await tester.pump();

    expect(llm.cancelled, isTrue);
    done.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('deleting the model turns the AI off', (tester) async {
    llm.statusValue = const LlmReady(LlmSource.downloaded);
    final container = await pumpSettings(tester);
    await container.read(llmEnabledProvider.notifier).set(true);
    await tester.pumpAndSettle();

    llm.statusValue = const LlmNeedsDownload();
    await tester.tap(find.text('Elimina modello'));
    await tester.pumpAndSettle();

    expect(llm.deleteCalls, 1);
    expect(container.read(llmEnabledProvider).value, isFalse);
    expect(find.text('Scarica modello'), findsOneWidget);
  });
}
