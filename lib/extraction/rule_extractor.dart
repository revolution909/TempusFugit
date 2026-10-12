import '../domain/coupon.dart';

/// Fields guessed from the text of a coupon. Anything the extractor could not
/// determine is null; fields it guessed with low confidence are named in
/// [uncertain] so the UI can highlight them for the user to double-check.
class ExtractedCoupon {
  const ExtractedCoupon({
    this.merchant,
    this.title,
    this.expiresAt,
    this.validFrom,
    this.discountType,
    this.discountValue,
    this.minSpend,
    this.codeValue,
    this.conditions,
    this.uncertain = const {},
    this.aiFilled = const {},
  });

  final String? merchant;
  final String? title;
  final DateTime? expiresAt;
  final DateTime? validFrom;
  final DiscountType? discountType;
  final double? discountValue;
  final double? minSpend;

  /// A printed promo code (not a barcode).
  final String? codeValue;
  final String? conditions;

  /// Fields guessed with low confidence (by the rules or by the LLM).
  final Set<String> uncertain;

  /// Fields whose value came from the on-device LLM rather than the rules, so
  /// the UI can say so: `merchant`, `title`, `expiresAt`, `validFrom`,
  /// `discount`, `minSpend`, `codeValue`, `conditions`.
  final Set<String> aiFilled;

  /// Whether any usable field was found.
  bool get isEmpty =>
      merchant == null &&
      expiresAt == null &&
      discountType == null &&
      minSpend == null &&
      codeValue == null;
}

/// Rule-based extraction (Italian + English) from OCR / pasted text. This is the
/// reliable baseline: it runs offline on every device. An on-device LLM can be
/// layered on top later for the fields this leaves empty.
class RuleExtractor {
  RuleExtractor({List<String>? knownMerchants})
      : _merchants = knownMerchants ?? defaultMerchants;

  final List<String> _merchants;

  static const defaultMerchants = <String>[
    'Esselunga', 'Coop', 'Conad', 'Carrefour', 'Lidl', 'Eurospin', 'Aldi',
    'Penny', 'Despar', 'Pam', 'Famila', 'Bennet', 'Md', 'Decathlon', 'IKEA',
    'Leroy Merlin', 'Zara', 'H&M', 'OVS', 'Calzedonia', 'Intimissimi',
    'Amazon', 'Zalando', 'MediaWorld', 'Unieuro', 'Euronics', 'Feltrinelli',
    'Mondadori', 'Sephora', 'Douglas', 'Kiko', 'Tigotà', 'Acqua e Sapone',
    "McDonald's", 'Burger King', 'Starbucks', 'KFC', 'Domino\'s', 'Autogrill',
    'Just Eat', 'Glovo', 'Deliveroo', 'Trenitalia', 'Italo', 'Booking',
    'Airbnb', 'Netflix', 'Spotify', 'Nike', 'Adidas', 'Foot Locker',
  ];

  static const _monthWords = <String, int>{
    // Italian
    'gennaio': 1, 'febbraio': 2, 'marzo': 3, 'aprile': 4, 'maggio': 5,
    'giugno': 6, 'luglio': 7, 'agosto': 8, 'settembre': 9, 'ottobre': 10,
    'novembre': 11, 'dicembre': 12,
    'gen': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mag': 5, 'giu': 6, 'lug': 7,
    'ago': 8, 'set': 9, 'sett': 9, 'ott': 10, 'nov': 11, 'dic': 12,
    // English
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5,
    'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10,
    'november': 11, 'december': 12,
    'jan': 1, 'sep': 9, 'sept': 9, 'oct': 10, 'dec': 12,
  };

  static final _numericWithYear =
      RegExp(r'(?<!\d)(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{4}|\d{2})(?!\d)');
  static final _numericNoYear = RegExp(r'(?<!\d)(\d{1,2})\s*/\s*(\d{1,2})(?![\d/])');
  static final _dayMonthWord = RegExp(
      r'(?<!\d)(\d{1,2})\s*(?:°|º|st|nd|rd|th)?\s+([A-Za-zÀ-ÿ]{3,9})\.?(?:,?\s+(\d{4}|\d{2})(?!\d))?');
  static final _monthWordDay = RegExp(
      r'([A-Za-z]{3,9})\.?\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4})(?!\d))?');

  static final _expiryKeyword = RegExp(
      r'scad|valid[oa]?\s+(?:fino|sino|entro|until|through|thru|till)|entro|fino\s+al|'
      r'expir|\bexp\b|until|through|use\s+by|utilizzabil\w*|da\s+utilizzare|da\s+consumare',
      caseSensitive: false);
  static final _fromKeyword = RegExp(
      r'\bdal\b|valid[oa]?\s+dal?\b|\bfrom\b|\bstarts?\b|a\s+partire\s+dal',
      caseSensitive: false);
  static final _rangeJoiner = RegExp(r'^\s*(?:al|a|to|-|–|fino\s+al)\s*$',
      caseSensitive: false);

  ExtractedCoupon extract(String text, {required DateTime now}) {
    final normalized = text.replaceAll('\r', '');
    final uncertain = <String>{};

    final dates = _extractDates(normalized, now);
    DateTime? expiresAt;
    DateTime? validFrom;
    if (dates.isNotEmpty) {
      final expiryDates = dates.where((d) => d.role == _Role.expiry).toList();
      final fromDates = dates.where((d) => d.role == _Role.from).toList();
      if (fromDates.isNotEmpty) validFrom = fromDates.first.date;
      if (expiryDates.isNotEmpty) {
        expiryDates.sort((a, b) => a.date.compareTo(b.date));
        expiresAt = expiryDates.last.date;
        if (expiryDates.last.yearGuessed) uncertain.add('expiresAt');
      } else {
        // No keyword: fall back to the latest date that is not in the past.
        final today = DateTime(now.year, now.month, now.day);
        final future = dates
            .where((d) => d.role != _Role.from && !d.date.isBefore(today))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        if (future.isNotEmpty) {
          expiresAt = future.last.date;
          uncertain.add('expiresAt');
        }
      }
    }

    final minSpendMatch = _minSpend.firstMatch(normalized);
    final minSpend =
        minSpendMatch == null ? null : _parseAmount(minSpendMatch.group(1)!);
    final withoutMinSpend = minSpendMatch == null
        ? normalized
        : normalized.replaceRange(
            minSpendMatch.start, minSpendMatch.end, ' ' * (minSpendMatch.end - minSpendMatch.start));

    final discount = _extractDiscount(withoutMinSpend);
    final code = _extractCode(normalized);
    final merchant = _extractMerchant(normalized, uncertain);

    final extracted = ExtractedCoupon(
      merchant: merchant,
      title: _suggestTitle(discount),
      expiresAt: expiresAt,
      validFrom: validFrom,
      discountType: discount?.$1,
      discountValue: discount?.$2,
      minSpend: minSpend,
      codeValue: code,
      conditions: _extractConditions(normalized),
      uncertain: uncertain,
    );
    return extracted;
  }

  // ---- dates ---------------------------------------------------------------

  List<_Dated> _extractDates(String text, DateTime now) {
    final raw = <_RawDate>[];
    final taken = <(int, int)>[];

    bool overlaps(int s, int e) => taken.any((t) => s < t.$2 && e > t.$1);
    void add(DateTime? d, int s, int e, {bool yearGuessed = false}) {
      if (d == null || overlaps(s, e)) return;
      taken.add((s, e));
      raw.add(_RawDate(d, s, e, yearGuessed));
    }

    for (final m in _numericWithYear.allMatches(text)) {
      add(_build(int.parse(m.group(1)!), int.parse(m.group(2)!), m.group(3), now).$1,
          m.start, m.end);
    }
    for (final m in _dayMonthWord.allMatches(text)) {
      final month = _monthWords[m.group(2)!.toLowerCase().replaceAll('.', '')];
      if (month == null) continue;
      final r = _build(int.parse(m.group(1)!), month, m.group(3), now);
      add(r.$1, m.start, m.end, yearGuessed: r.$2);
    }
    for (final m in _monthWordDay.allMatches(text)) {
      final month = _monthWords[m.group(1)!.toLowerCase()];
      if (month == null) continue;
      final r = _build(int.parse(m.group(2)!), month, m.group(3), now);
      add(r.$1, m.start, m.end, yearGuessed: r.$2);
    }
    for (final m in _numericNoYear.allMatches(text)) {
      final r = _build(int.parse(m.group(1)!), int.parse(m.group(2)!), null, now);
      add(r.$1, m.start, m.end, yearGuessed: true);
    }

    raw.sort((a, b) => a.start.compareTo(b.start));
    final result = <_Dated>[];
    var prevEnd = 0;
    _Role? prevRole;
    for (final d in raw) {
      final ctxStart = d.start - 40 > prevEnd ? d.start - 40 : prevEnd;
      final ctx = text.substring(ctxStart, d.start);
      _Role role;
      if (prevRole == _Role.from && _rangeJoiner.hasMatch(ctx)) {
        role = _Role.expiry;
      } else if (_expiryKeyword.hasMatch(ctx)) {
        role = _Role.expiry;
      } else if (_fromKeyword.hasMatch(ctx)) {
        role = _Role.from;
      } else {
        role = _Role.unknown;
      }
      result.add(_Dated(d.date, role, d.yearGuessed));
      prevEnd = d.end;
      prevRole = role;
    }
    return result;
  }

  /// Returns (date, yearGuessed). Null date if the combination is not valid.
  (DateTime?, bool) _build(int day, int month, String? yearText, DateTime now) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return (null, false);
    final today = DateTime(now.year, now.month, now.day);
    if (yearText != null) {
      var y = int.parse(yearText);
      if (y < 100) y += 2000;
      final d = DateTime(y, month, day);
      return d.month == month && d.day == day ? (d, false) : (null, false);
    }
    var d = DateTime(today.year, month, day);
    if (d.month != month || d.day != day) return (null, false);
    if (d.isBefore(today)) d = DateTime(today.year + 1, month, day);
    return d.month == month && d.day == day ? (d, true) : (null, false);
  }

  // ---- discount ------------------------------------------------------------

  static final _percent = RegExp(r'(\d{1,3}(?:[.,]\d+)?)\s*%');
  static final _discountWord = RegExp(
      r'buono|sconto|voucher|coupon|credito|regalo|risparmi\w*|di\s+sconto|\boff\b|gift',
      caseSensitive: false);
  static final _amountBefore =
      RegExp(r'(?:€|eur(?:o)?\b)\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false);
  static final _amountAfter =
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:€|eur(?:o)?\b)', caseSensitive: false);
  static final _nForM = RegExp(r'(?<!\d)([1-9])\s*(?:[x×]|per|\+)\s*([1-9])(?!\d)',
      caseSensitive: false);
  static final _freebie = RegExp(r'omaggio|gratis|gratuit\w+|\bfree\b', caseSensitive: false);
  static final _minSpend = RegExp(
      r'(?:spesa\s+minima|minimo\s+d[\x27’]?\s*acquisto|min\.?\s*(?:spesa|acquisto)|'
      r'acquisti?\s+(?:superior\w+|oltre)|(?:per|su)\s+una\s+spesa\s+(?:di|minima)|'
      r'a\s+partire\s+da|minimum\s+(?:spend|purchase)|min\.?\s*spend|spend\s+(?:over|at\s+least))'
      r'[^\d\n]{0,15}(\d+(?:[.,]\d{1,2})?)',
      caseSensitive: false);

  (DiscountType, double?)? _extractDiscount(String text) {
    for (final m in _percent.allMatches(text)) {
      final v = _parseAmount(m.group(1)!);
      if (v != null && v > 0 && v <= 100) return (DiscountType.percent, v);
    }
    for (final re in [_amountBefore, _amountAfter]) {
      for (final m in re.allMatches(text)) {
        final from = m.start - 30 < 0 ? 0 : m.start - 30;
        final to = m.end + 30 > text.length ? text.length : m.end + 30;
        if (_discountWord.hasMatch(text.substring(from, to))) {
          final v = _parseAmount(m.group(1)!);
          if (v != null && v > 0) return (DiscountType.amount, v);
        }
      }
    }
    for (final m in _nForM.allMatches(text)) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      if (a > b) return (DiscountType.twoForOne, null);
      if (a == b && a == 1 && m.group(0)!.contains('+')) {
        return (DiscountType.twoForOne, null);
      }
    }
    if (_freebie.hasMatch(text)) return (DiscountType.freebie, null);
    return null;
  }

  String? _suggestTitle((DiscountType, double?)? discount) {
    if (discount == null) return null;
    final label = Coupon(
      id: '',
      title: '',
      merchant: '',
      kind: CouponKind.digital,
      createdAt: DateTime(2000),
      discountType: discount.$1,
      discountValue: discount.$2,
    ).discountLabel;
    switch (discount.$1) {
      case DiscountType.percent:
        return 'Sconto ${label.replaceFirst('-', '')}';
      case DiscountType.amount:
        return 'Buono $label';
      case DiscountType.twoForOne:
        return 'Offerta 2x1';
      case DiscountType.freebie:
        return 'Omaggio';
      case DiscountType.other:
        return null;
    }
  }

  // ---- code ----------------------------------------------------------------

  static final _code = RegExp(
      r'(?:codice(?:\s+(?:promo(?:zionale)?|sconto|coupon|voucher))?|promo\s*code|'
      r'coupon\s*code|voucher\s*code|use\s+code|code)\s*[:\-–]?\s*([A-Za-z0-9][A-Za-z0-9\-]{3,24})',
      caseSensitive: false);

  String? _extractCode(String text) {
    for (final m in _code.allMatches(text)) {
      final c = m.group(1)!;
      final isUpper = c == c.toUpperCase();
      final hasDigit = RegExp(r'\d').hasMatch(c);
      if (!isUpper) continue;
      if (!hasDigit && c.length < 5) continue;
      return c;
    }
    return null;
  }

  // ---- merchant ------------------------------------------------------------

  static const _ignoredDomains = {
    'google', 'facebook', 'instagram', 'twitter', 'youtube', 'whatsapp', 'tiktok',
  };
  static final _domain =
      RegExp(r'(?:www\.)?([a-z0-9][a-z0-9\-]{1,30})\.(?:it|com|eu|net|org)\b',
          caseSensitive: false);
  static final _couponWords = RegExp(
      r'buono|sconto|coupon|voucher|scad|valid|codice|code|offerta|promo|regalo|gift|'
      r'euro|€|%|www|http|spesa|acquist|cumulabil',
      caseSensitive: false);

  String? _extractMerchant(String text, Set<String> uncertain) {
    final lower = text.toLowerCase();
    String? best;
    var bestIndex = text.length + 1;
    for (final name in _merchants) {
      final re = RegExp('(?<![A-Za-zÀ-ÿ])${RegExp.escape(name.toLowerCase())}(?![A-Za-zÀ-ÿ])');
      final m = re.firstMatch(lower);
      if (m != null && m.start < bestIndex) {
        best = name;
        bestIndex = m.start;
      }
    }
    if (best != null) return best;

    for (final m in _domain.allMatches(text)) {
      final host = m.group(1)!.toLowerCase();
      if (_ignoredDomains.contains(host)) continue;
      uncertain.add('merchant');
      return host[0].toUpperCase() + host.substring(1);
    }

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(3);
    for (final line in lines) {
      if (line.length < 2 || line.length > 30) continue;
      if (RegExp(r'\d').hasMatch(line) || _couponWords.hasMatch(line)) continue;
      final letters = RegExp(r'[A-Za-zÀ-ÿ]').allMatches(line).length;
      if (letters < line.length * 0.7) continue;
      uncertain.add('merchant');
      return line;
    }
    return null;
  }

  // ---- conditions ----------------------------------------------------------

  static final _conditionLine = RegExp(
      r'non\s+cumulabil\w*|cumulabil\w*|esclus\w*|valido\s+solo|solo\s+(?:in\s+)?(?:negozio|online|punti\s+vendita)|'
      r'una\s+volta|per\s+persona|not\s+valid|excluding|one\s+per',
      caseSensitive: false);

  String? _extractConditions(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && _conditionLine.hasMatch(l))
        .take(3)
        .toList();
    return lines.isEmpty ? null : lines.join(' ');
  }

  double? _parseAmount(String s) {
    final cleaned = s.replaceAll(RegExp(r'\.(?=\d{3}\b)'), '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}

enum _Role { expiry, from, unknown }

class _RawDate {
  _RawDate(this.date, this.start, this.end, this.yearGuessed);
  final DateTime date;
  final int start;
  final int end;
  final bool yearGuessed;
}

class _Dated {
  _Dated(this.date, this.role, this.yearGuessed);
  final DateTime date;
  final _Role role;
  final bool yearGuessed;
}
