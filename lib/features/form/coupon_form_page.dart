import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/coupon.dart';
import '../../extraction/rule_extractor.dart';
import '../../providers.dart';

/// Pre-filled values for a new coupon coming from a scan, photo or pasted text.
class CouponDraft {
  const CouponDraft({
    this.extracted,
    this.codeValue,
    this.codeFormat,
    this.imagePath,
    this.source = CouponSource.manual,
    this.kind = CouponKind.digital,
  });

  final ExtractedCoupon? extracted;
  final String? codeValue;
  final String? codeFormat;
  final String? imagePath;
  final CouponSource source;
  final CouponKind kind;
}

/// Single confirmation / edit screen. Fields the extractor was unsure about are
/// marked so the user knows what to double-check.
class CouponFormPage extends ConsumerStatefulWidget {
  const CouponFormPage({super.key, this.existing, this.draft});

  final Coupon? existing;
  final CouponDraft? draft;

  @override
  ConsumerState<CouponFormPage> createState() => _CouponFormPageState();
}

class _CouponFormPageState extends ConsumerState<CouponFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _merchant;
  late final TextEditingController _code;
  late final TextEditingController _discountValue;
  late final TextEditingController _minSpend;
  late final TextEditingController _conditions;
  late final TextEditingController _tag;
  late CouponKind _kind;
  late DiscountType _discountType;
  DateTime? _expiresAt;
  DateTime? _validFrom;
  String? _codeFormat;
  late Set<String> _uncertain;
  List<String> _knownMerchants = const [];
  final _merchantFocus = FocusNode();
  String? _originalCode;
  String? _extractedMerchant;

  static final _dateFormat = DateFormat('EEE d MMM y', 'it');

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    final d = widget.draft;
    final x = d?.extracted;

    _kind = c?.kind ?? d?.kind ?? CouponKind.digital;
    _discountType = c?.discountType ?? x?.discountType ?? DiscountType.other;
    _expiresAt = c?.expiresAt ?? x?.expiresAt;
    _validFrom = c?.validFrom ?? x?.validFrom;
    _codeFormat = c?.codeFormat ?? d?.codeFormat;
    _uncertain = {...?x?.uncertain};

    _title = TextEditingController(text: c?.title ?? x?.title ?? '');
    _merchant = TextEditingController(text: c?.merchant ?? x?.merchant ?? '');
    _code = TextEditingController(text: c?.codeValue ?? d?.codeValue ?? '');
    _discountValue = TextEditingController(
        text: _fmtNum(c?.discountValue ?? x?.discountValue));
    _minSpend = TextEditingController(text: _fmtNum(c?.minSpend ?? x?.minSpend));
    _conditions = TextEditingController(text: c?.conditions ?? x?.conditions ?? '');
    _tag = TextEditingController(text: c?.tag ?? '');
    _originalCode = c?.codeValue ?? d?.codeValue;
    _extractedMerchant = x?.merchant;
    _merchant.addListener(() {
      if (_uncertain.contains('merchant') && _merchant.text != _extractedMerchant) {
        setState(() => _uncertain.remove('merchant'));
      }
    });

    ref.read(couponRepositoryProvider).merchants().then((m) {
      if (mounted) setState(() => _knownMerchants = m);
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _merchant, _code, _discountValue, _minSpend, _conditions, _tag]) {
      c.dispose();
    }
    _merchantFocus.dispose();
    super.dispose();
  }

  static String _fmtNum(double? v) {
    if (v == null) return '';
    return (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString())
        .replaceAll('.', ',');
  }

  static double? _parseNum(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  InputDecoration _decoration(String label, {String? field, String? hint, Widget? suffix}) {
    final unsure = field != null && _uncertain.contains(field);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
      helperText: unsure ? 'Letto automaticamente: controlla' : null,
      helperStyle: TextStyle(color: Colors.orange.shade800),
      enabledBorder: unsure
          ? OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade700, width: 2))
          : null,
    );
  }

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final initial = (from ? _validFrom : _expiresAt) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _validFrom = picked;
      } else {
        _expiresAt = picked;
        _uncertain.remove('expiresAt');
      }
    });
  }

  void _setExpiry(DateTime? d) => setState(() {
        _expiresAt = d;
        _uncertain.remove('expiresAt');
      });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    final draft = widget.draft;
    final discountValue = _discountType == DiscountType.percent ||
            _discountType == DiscountType.amount
        ? _parseNum(_discountValue.text)
        : null;
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final base = Coupon(
      id: existing?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      merchant: _merchant.text.trim(),
      kind: _kind,
      createdAt: existing?.createdAt ?? DateTime.now(),
      category: existing?.category,
      tag: orNull(_tag),
      codeValue: orNull(_code),
      codeFormat: orNull(_code) == null ? null : _codeFormat,
      discountType: _discountType,
      discountValue: discountValue,
      minSpend: _parseNum(_minSpend.text),
      conditions: orNull(_conditions),
      validFrom: _validFrom,
      expiresAt: _expiresAt,
      status: existing?.status ?? CouponStatus.active,
      imagePath: existing?.imagePath ?? draft?.imagePath,
      source: existing?.source ?? draft?.source ?? CouponSource.manual,
    );
    await ref.read(couponRepositoryProvider).upsert(base);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Modifica coupon' : 'Nuovo coupon')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<CouponKind>(
              segments: const [
                ButtonSegment(
                    value: CouponKind.physical,
                    icon: Icon(Icons.receipt_long),
                    label: Text('Fisico')),
                ButtonSegment(
                    value: CouponKind.digital,
                    icon: Icon(Icons.qr_code_2),
                    label: Text('Digitale')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            RawAutocomplete<String>(
              textEditingController: _merchant,
              focusNode: _merchantFocus,
              optionsBuilder: (v) => v.text.isEmpty
                  ? const Iterable<String>.empty()
                  : _knownMerchants.where(
                      (m) => m.toLowerCase().contains(v.text.toLowerCase())),
              fieldViewBuilder: (context, controller, focus, onSubmit) {
                return TextFormField(
                  controller: controller,
                  focusNode: focus,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Negozio / marchio *', field: 'merchant'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Indica il negozio' : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 360),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final o in options)
                          ListTile(
                            dense: true,
                            title: Text(o),
                            onTap: () => onSelected(o),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: _decoration('Titolo', hint: 'es. Sconto 20% su tutto'),
              validator: (v) {
                if ((v == null || v.trim().isEmpty) && _merchant.text.trim().isEmpty) {
                  return 'Inserisci un titolo';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<DiscountType>(
                    initialValue: _discountType,
                    decoration: _decoration('Sconto'),
                    items: const [
                      DropdownMenuItem(value: DiscountType.percent, child: Text('Percentuale %')),
                      DropdownMenuItem(value: DiscountType.amount, child: Text('Importo €')),
                      DropdownMenuItem(value: DiscountType.twoForOne, child: Text('2x1')),
                      DropdownMenuItem(value: DiscountType.freebie, child: Text('Omaggio')),
                      DropdownMenuItem(value: DiscountType.other, child: Text('Altro')),
                    ],
                    onChanged: (v) => setState(() => _discountType = v!),
                  ),
                ),
                if (_discountType == DiscountType.percent ||
                    _discountType == DiscountType.amount) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _discountValue,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _decoration(
                          _discountType == DiscountType.percent ? 'Valore %' : 'Valore €'),
                      validator: (v) => v != null && v.trim().isNotEmpty && _parseNum(v) == null
                          ? 'Numero non valido'
                          : null,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text('Scadenza', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDate(from: false),
              child: InputDecorator(
                decoration: _decoration('Valido fino a', field: 'expiresAt',
                    suffix: const Icon(Icons.calendar_today)),
                child: Text(_expiresAt == null
                    ? 'Nessuna scadenza'
                    : _dateFormat.format(_expiresAt!)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                    label: const Text('+7 giorni'),
                    onPressed: () => _setExpiry(today.add(const Duration(days: 7)))),
                ActionChip(
                    label: const Text('+30 giorni'),
                    onPressed: () => _setExpiry(DateTime(today.year, today.month, today.day + 30))),
                ActionChip(
                    label: const Text('Fine mese'),
                    onPressed: () => _setExpiry(DateTime(today.year, today.month + 1, 0))),
                ActionChip(
                    label: const Text('Fine anno'),
                    onPressed: () => _setExpiry(DateTime(today.year, 12, 31))),
                if (_expiresAt != null)
                  ActionChip(
                      label: const Text('Nessuna'), onPressed: () => _setExpiry(null)),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(from: true),
              child: InputDecorator(
                decoration: _decoration('Valido dal (facoltativo)',
                    suffix: _validFrom == null
                        ? const Icon(Icons.calendar_today)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _validFrom = null))),
                child: Text(_validFrom == null ? '—' : _dateFormat.format(_validFrom!)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              decoration: _decoration('Codice',
                  hint: 'numero del codice a barre o codice promo',
                  suffix: _codeFormat == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_codeFormat!, style: Theme.of(context).textTheme.labelSmall),
                        )),
              onChanged: (_) {
                // Hand-edited code no longer matches the scanned symbology.
                if (_codeFormat != null && _code.text != _originalCode) {
                  setState(() => _codeFormat = null);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minSpend,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('Spesa minima € (facoltativo)'),
              validator: (v) => v != null && v.trim().isNotEmpty && _parseNum(v) == null
                  ? 'Numero non valido'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conditions,
              maxLines: 3,
              decoration: _decoration('Condizioni (facoltativo)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tag,
              decoration: _decoration('Associato a (facoltativo)',
                  hint: 'es. regalo di Anna, ordine #123'),
            ),
          ],
        ),
      ),
      // Always reachable, even with the keyboard open or on a short screen.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(editing ? 'Salva modifiche' : 'Salva coupon'),
          ),
        ),
      ),
    );
  }
}
