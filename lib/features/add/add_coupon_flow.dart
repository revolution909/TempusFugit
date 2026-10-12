import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/coupon.dart';
import '../../extraction/extraction_pipeline.dart';
import '../../providers.dart';
import '../form/coupon_form_page.dart';
import '../scan/barcode_scan_page.dart';

enum _AddChoice { barcode, photo, gallery, clipboard, manual }

/// Entry point of the "add coupon" flow: pick how to capture, run extraction,
/// then land on the confirmation form.
Future<void> showAddCouponSheet(BuildContext context, WidgetRef ref) async {
  final choice = await showModalBottomSheet<_AddChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option(
              context,
              Icons.qr_code_scanner,
              'Scansiona codice',
              'Barcode o QR, lettura immediata',
              _AddChoice.barcode,
            ),
            _option(
              context,
              Icons.photo_camera,
              'Fotografa il coupon',
              'Legge codice, negozio, sconto e scadenza',
              _AddChoice.photo,
            ),
            _option(
              context,
              Icons.photo_library,
              'Da galleria / screenshot',
              'Importa un\'immagine già salvata',
              _AddChoice.gallery,
            ),
            _option(
              context,
              Icons.content_paste,
              'Incolla testo',
              'Es. un codice promo copiato da email o chat',
              _AddChoice.clipboard,
            ),
            _option(
              context,
              Icons.edit,
              'Inserisci a mano',
              null,
              _AddChoice.manual,
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case _AddChoice.barcode:
      final code = await Navigator.of(context).push<FoundCode>(
        MaterialPageRoute(builder: (_) => const BarcodeScanPage()),
      );
      if (code == null || !context.mounted) return;
      await _openForm(
        context,
        CouponDraft(
          codeValue: code.value,
          codeFormat: code.format,
          source: CouponSource.barcodeScan,
          kind: CouponKind.physical,
        ),
      );
    case _AddChoice.photo:
      await _fromImage(context, ref, ImageSource.camera);
    case _AddChoice.gallery:
      await _fromImage(context, ref, ImageSource.gallery);
    case _AddChoice.clipboard:
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (!context.mounted) return;
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gli appunti sono vuoti.')),
        );
        return;
      }
      final result = ref.read(extractionPipelineProvider).fromText(text);
      await _openForm(
        context,
        _draftFrom(result, CouponSource.manual, CouponKind.digital, null),
        noDataHint: result.extracted.isEmpty,
      );
    case _AddChoice.manual:
      await _openForm(context, const CouponDraft());
  }
}

Widget _option(
  BuildContext context,
  IconData icon,
  String title,
  String? subtitle,
  _AddChoice value,
) => ListTile(
  leading: Icon(icon),
  title: Text(title),
  subtitle: subtitle == null ? null : Text(subtitle),
  onTap: () => Navigator.of(context).pop(value),
);

Future<void> _fromImage(
  BuildContext context,
  WidgetRef ref,
  ImageSource source,
) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 92,
  );
  if (picked == null || !context.mounted) return;

  // Show progress while barcode + OCR + rules run.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  ScanResult result;
  String savedPath;
  try {
    savedPath = await _persistImage(picked.path);
    result = await ref.read(extractionPipelineProvider).fromImage(savedPath);
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
  if (!context.mounted) return;

  final isCamera = source == ImageSource.camera;
  await _openForm(
    context,
    _draftFrom(
      result,
      isCamera ? CouponSource.photo : CouponSource.gallery,
      isCamera ? CouponKind.physical : CouponKind.digital,
      savedPath,
    ),
    noDataHint: result.codeValue == null && result.extracted.isEmpty,
  );
}

CouponDraft _draftFrom(
  ScanResult r,
  CouponSource source,
  CouponKind kind,
  String? imagePath,
) => CouponDraft(
  extracted: r.extracted,
  rawText: r.rawText,
  codeValue: r.codeValue,
  codeFormat: r.codeFormat,
  imagePath: imagePath,
  source: source,
  kind: kind,
);

/// Copies the picked image out of the (temporary) picker cache so the original
/// stays available on the coupon.
Future<String> _persistImage(String path) async {
  final dir = Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'coupons'),
  );
  await dir.create(recursive: true);
  final dest = p.join(dir.path, '${const Uuid().v4()}${p.extension(path)}');
  await File(path).copy(dest);
  return dest;
}

Future<void> _openForm(
  BuildContext context,
  CouponDraft draft, {
  bool noDataHint = false,
}) async {
  if (noDataHint) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Non ho riconosciuto dati nel testo: compila a mano.'),
      ),
    );
  }
  await Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute(builder: (_) => CouponFormPage(draft: draft)));
}
