import 'dart:convert';

import '../domain/coupon.dart';
import '../extraction/rule_extractor.dart';

/// Longest slice of OCR text sent to the model. Apple's on-device model has a
/// ~4K-token window and small models degrade on long, noisy input anyway.
const maxPromptTextLength = 1500;

/// Builds the extraction prompt. Small models follow a fixed schema plus a
/// couple of examples far better than free-form instructions.
String buildCouponPrompt(String text, DateTime now) {
  final today = _isoDate(now);
  final body = text.length > maxPromptTextLength
      ? text.substring(0, maxPromptTextLength)
      : text;
  return '''Estrai i dati di un coupon dal testo. Rispondi SOLO con un oggetto JSON, senza altro testo.

Campi (usa null se il dato non è nel testo, non inventare nulla):
- merchant: negozio o marchio
- title: titolo breve dell'offerta
- expiresAt: ultimo giorno di validità, formato AAAA-MM-GG
- validFrom: primo giorno di validità, formato AAAA-MM-GG
- discountType: "percent", "amount", "twoForOne", "freebie" oppure "other"
- discountValue: numero (percentuale o euro), null per twoForOne e freebie
- minSpend: spesa minima in euro, numero
- promoCode: codice promozionale scritto nel testo
- conditions: condizioni d'uso, una frase

Oggi è $today. Se la data non indica l'anno, usa il prossimo anno in cui cade in futuro.

Esempio 1
Testo: "CONAD Buono sconto 5 euro su spesa minima 40 euro. Valido fino al 31/12/2026. Non cumulabile."
JSON: {"merchant":"Conad","title":"Buono sconto 5 €","expiresAt":"2026-12-31","validFrom":null,"discountType":"amount","discountValue":5,"minSpend":40,"promoCode":null,"conditions":"Non cumulabile."}

Esempio 2
Testo: "Pizzeria Da Gigi - 2x1 ogni martedì, escluso festivi. Codice: GIGI2X1"
JSON: {"merchant":"Pizzeria Da Gigi","title":"2x1 il martedì","expiresAt":null,"validFrom":null,"discountType":"twoForOne","discountValue":null,"minSpend":null,"promoCode":"GIGI2X1","conditions":"Escluso festivi."}

Ora il tuo turno.
Testo: ${jsonEncode(body)}
JSON:''';
}

/// Turns the model's raw reply into validated coupon fields, or null if
/// nothing usable came out. Never throws: small models produce malformed or
/// invented output often enough that every field is checked.
///
/// [sourceText] is the text the model was given. Names and codes must appear
/// in it (ignoring case and punctuation), which catches hallucinated brands
/// and promo codes. Dates cannot be grounded that way, so any date the model
/// produces is marked uncertain.
ExtractedCoupon? parseLlmResponse(
  String raw, {
  required String sourceText,
  required DateTime now,
}) {
  final jsonText = _firstJsonObject(raw);
  if (jsonText == null) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;

  final today = DateTime(now.year, now.month, now.day);
  final minDate = DateTime(today.year - 1, today.month, today.day);
  final maxDate = DateTime(today.year + 10, today.month, today.day);
  final grounded = _normalize(sourceText);

  final uncertain = <String>{};

  var expiresAt = _date(decoded['expiresAt'], minDate, maxDate);
  var validFrom = _date(decoded['validFrom'], minDate, maxDate);
  if (expiresAt != null && validFrom != null && validFrom.isAfter(expiresAt)) {
    validFrom = null;
  }
  if (expiresAt != null) uncertain.add('expiresAt');

  final merchant = _grounded(_string(decoded['merchant'], 2, 40), grounded);

  final promo = _string(decoded['promoCode'], 4, 25);
  final code =
      promo != null &&
          RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(promo) &&
          grounded.contains(_normalize(promo))
      ? promo
      : null;

  DiscountType? type = _discountType(decoded['discountType']);
  double? value = _number(decoded['discountValue']);
  if (type == DiscountType.percent) {
    if (value == null || value <= 0 || value > 100) type = value = null;
  } else if (type == DiscountType.amount) {
    if (value == null || value <= 0 || value >= 10000) type = value = null;
  } else {
    value = null;
  }
  if (type == DiscountType.other) type = null;

  final minSpend = _number(decoded['minSpend']);

  final result = ExtractedCoupon(
    merchant: merchant,
    title: _string(decoded['title'], 2, 60),
    expiresAt: expiresAt,
    validFrom: validFrom,
    discountType: type,
    discountValue: value,
    minSpend: minSpend != null && minSpend > 0 && minSpend < 100000
        ? minSpend
        : null,
    codeValue: code,
    conditions: _string(decoded['conditions'], 3, 200),
    uncertain: uncertain,
  );
  return result.isEmpty && result.title == null && result.conditions == null
      ? null
      : result;
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// First balanced `{...}` in [raw], ignoring braces inside JSON strings. The
/// model may wrap the object in a code fence or add chatter around it.
String? _firstJsonObject(String raw) {
  final start = raw.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < raw.length; i++) {
    final c = raw[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return raw.substring(start, i + 1);
    }
  }
  return null;
}

String? _string(Object? v, int min, int max) {
  if (v is! String) return null;
  final s = v.trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return s.length < min || s.length > max ? null : s;
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9à-ÿ]'), '');

String? _grounded(String? value, String groundedSource) {
  if (value == null) return null;
  final n = _normalize(value);
  return n.isNotEmpty && groundedSource.contains(n) ? value : null;
}

double? _number(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim().replaceAll(',', '.'));
  return null;
}

DateTime? _date(Object? v, DateTime min, DateTime max) {
  if (v is! String) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final date = DateTime(y, mo, d);
  if (date.year != y || date.month != mo || date.day != d) return null;
  return date.isBefore(min) || date.isAfter(max) ? null : date;
}

DiscountType? _discountType(Object? v) {
  if (v is! String) return null;
  switch (v.trim().toLowerCase()) {
    case 'percent':
    case 'percentage':
    case 'percentuale':
      return DiscountType.percent;
    case 'amount':
    case 'importo':
    case 'euro':
      return DiscountType.amount;
    case 'twoforone':
    case '2x1':
      return DiscountType.twoForOne;
    case 'freebie':
    case 'omaggio':
      return DiscountType.freebie;
    case 'other':
    case 'altro':
      return DiscountType.other;
    default:
      return null;
  }
}
