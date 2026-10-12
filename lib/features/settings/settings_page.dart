import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../llm/llm_extractor.dart';
import '../../llm/llm_settings.dart';
import '../../providers.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/section_header.dart';

/// Turns the on-device AI reading on or off and manages its model.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int? _progress; // 0..100 while downloading
  String? _error;

  Future<void> _download() async {
    final extractor = ref.read(llmExtractorProvider);
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      await extractor.downloadModel(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) ref.read(llmEnabledProvider.notifier).set(true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Download non riuscito: $e');
    } finally {
      if (mounted) {
        setState(() => _progress = null);
        ref.invalidate(llmStatusProvider);
      }
    }
  }

  Future<void> _delete() async {
    await ref.read(llmExtractorProvider).deleteModel();
    await ref.read(llmEnabledProvider.notifier).set(false);
    ref.invalidate(llmStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(llmEnabledProvider).value ?? false;
    final status = ref.watch(llmStatusProvider);
    final downloading = _progress != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          const SectionHeader('Lettura intelligente'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.l),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text:
                        'Un modello AI sul telefono legge il testo del coupon e '
                        'compila i campi che le regole non riconoscono '
                        '(negozio, scadenza, sconto). I campi suggeriti hanno '
                        "l'icona ",
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 18,
                      semanticLabel: 'stelline',
                    ),
                  ),
                  const TextSpan(
                    text:
                        " e la scritta «Suggerito dall'AI»: controllali "
                        'prima di salvare.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gap.s),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: Gap.l),
            title: const Text("Usa l'AI sul telefono"),
            value: enabled,
            onChanged: downloading
                ? null
                : (v) => ref.read(llmEnabledProvider.notifier).set(v),
          ),
          const SizedBox(height: Gap.s),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.l),
            child: status.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Stato non disponibile: $e'),
              data: (s) => _StatusCard(
                status: s,
                progress: _progress,
                error: _error,
                onDownload: _download,
                onCancel: () => ref.read(llmExtractorProvider).cancelDownload(),
                onDelete: _delete,
              ),
            ),
          ),
          const SectionHeader('Privacy'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(Icons.lock_outline)),
                SizedBox(width: Gap.m),
                Expanded(
                  child: Text(
                    'Il testo dei coupon non lascia mai il telefono. '
                    "L'unico traffico di rete è il download del modello, "
                    'una volta sola.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.progress,
    required this.error,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  final LlmStatus status;
  final int? progress;
  final String? error;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (progress != null) {
      children.addAll([
        const Text('Download del modello in corso…'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress! / 100),
        const SizedBox(height: 4),
        Text('$progress%'),
        TextButton(onPressed: onCancel, child: const Text('Annulla')),
      ]);
    } else {
      switch (status) {
        case LlmUnavailable(:final reason):
          children.add(
            Text(
              'Non disponibile su questo dispositivo.${reason == null ? '' : '\n$reason'}',
            ),
          );
        case LlmNeedsDownload():
          children.addAll([
            const Text(
              'Serve scaricare un modello (circa 300–600 MB, una sola volta). '
              'Meglio con il Wi-Fi.',
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Scarica modello'),
            ),
          ]);
        case LlmReady(:final source):
          children.add(
            Text(
              source == LlmSource.system
                  ? 'Pronto: usa il modello del sistema, nessun download.'
                  : 'Pronto: modello scaricato su questo telefono.',
            ),
          );
          if (source == LlmSource.downloaded) {
            children.add(
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Elimina modello'),
              ),
            );
          }
      }
    }

    if (error != null) {
      children.addAll([
        const SizedBox(height: 8),
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
