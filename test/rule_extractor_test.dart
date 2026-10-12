import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/extraction/rule_extractor.dart';

void main() {
  final now = DateTime(2026, 10, 12);
  final x = RuleExtractor();

  group('dates', () {
    test('valido fino al dd/mm/yyyy', () {
      final r = x.extract('Valido fino al 31/12/2026', now: now);
      expect(r.expiresAt, DateTime(2026, 12, 31));
      expect(r.uncertain, isNot(contains('expiresAt')));
    });

    test('scade il with textual month', () {
      final r = x.extract('Il buono scade il 5 gennaio 2027.', now: now);
      expect(r.expiresAt, DateTime(2027, 1, 5));
    });

    test('abbreviated month and two-digit year', () {
      expect(x.extract('Scadenza: 15 dic 26', now: now).expiresAt,
          DateTime(2026, 12, 15));
      expect(x.extract('Scad. 03-11-26', now: now).expiresAt,
          DateTime(2026, 11, 3));
    });

    test('date range dal ... al ...', () {
      final r = x.extract('Valido dal 01/10/2026 al 30/11/2026', now: now);
      expect(r.validFrom, DateTime(2026, 10, 1));
      expect(r.expiresAt, DateTime(2026, 11, 30));
    });

    test('keyword on the previous line', () {
      final r = x.extract('Scadenza:\n20/11/2026', now: now);
      expect(r.expiresAt, DateTime(2026, 11, 20));
    });

    test('year-less date resolves to next occurrence and is flagged', () {
      final r = x.extract('Valido fino al 31/01', now: now);
      expect(r.expiresAt, DateTime(2027, 1, 31));
      expect(r.uncertain, contains('expiresAt'));
    });

    test('english formats', () {
      expect(x.extract('Expires Dec 31, 2026', now: now).expiresAt,
          DateTime(2026, 12, 31));
      expect(x.extract('Valid until 31 December 2026', now: now).expiresAt,
          DateTime(2026, 12, 31));
    });

    test('date without keyword is used but flagged; past dates ignored', () {
      final r = x.extract('Emesso 01/03/2026\n15/12/2026', now: now);
      expect(r.expiresAt, DateTime(2026, 12, 15));
      expect(r.uncertain, contains('expiresAt'));
      expect(x.extract('Emesso 01/03/2026', now: now).expiresAt, isNull);
    });

    test('prices are not parsed as dates', () {
      final r = x.extract('Buono da 5.50 € e 10.20 €', now: now);
      expect(r.expiresAt, isNull);
    });

    test('invalid dates are rejected', () {
      expect(x.extract('scade il 31/02/2026', now: now).expiresAt, isNull);
    });
  });

  group('discount', () {
    test('percent', () {
      final r = x.extract('Sconto del 20% su tutto', now: now);
      expect(r.discountType, DiscountType.percent);
      expect(r.discountValue, 20);
      expect(r.title, 'Sconto 20%');
    });

    test('amount with decimal comma', () {
      final r = x.extract('Buono sconto 5,50 €', now: now);
      expect(r.discountType, DiscountType.amount);
      expect(r.discountValue, 5.5);
    });

    test('minimum spend is not mistaken for the discount', () {
      final r = x.extract(
          'Buono sconto 10 € per acquisti superiori a 50 €', now: now);
      expect(r.discountType, DiscountType.amount);
      expect(r.discountValue, 10);
      expect(r.minSpend, 50);
    });

    test('2x1 and freebie', () {
      expect(x.extract('Offerta 2x1 il martedì', now: now).discountType,
          DiscountType.twoForOne);
      expect(x.extract('Un caffè in omaggio', now: now).discountType,
          DiscountType.freebie);
    });

    test('no discount found', () {
      expect(x.extract('Ciao mondo', now: now).discountType, isNull);
    });
  });

  group('code and merchant', () {
    test('promo code', () {
      expect(x.extract('Codice promo: SCONTO20', now: now).codeValue, 'SCONTO20');
      expect(x.extract('Use code SAVE10 at checkout', now: now).codeValue, 'SAVE10');
    });

    test('plain words after "codice" are not codes', () {
      expect(x.extract('codice fiscale richiesto', now: now).codeValue, isNull);
    });

    test('known merchant wins', () {
      final r = x.extract('ESSELUNGA\nBuono sconto 5 €', now: now);
      expect(r.merchant, 'Esselunga');
      expect(r.uncertain, isNot(contains('merchant')));
    });

    test('merchant from domain is flagged', () {
      final r = x.extract('Ordina su www.pizzabella.it con 10%', now: now);
      expect(r.merchant, 'Pizzabella');
      expect(r.uncertain, contains('merchant'));
    });

    test('merchant from first line is flagged', () {
      final r = x.extract('Bar Centrale\nUn caffè in omaggio', now: now);
      expect(r.merchant, 'Bar Centrale');
      expect(r.uncertain, contains('merchant'));
    });
  });

  test('full realistic coupon', () {
    const text = '''
Lidl
BUONO SCONTO 10 €
su una spesa minima di 60 €
Valido dal 01/10/2026 al 31/10/2026
Non cumulabile con altre promozioni
''';
    final r = x.extract(text, now: now);
    expect(r.merchant, 'Lidl');
    expect(r.discountType, DiscountType.amount);
    expect(r.discountValue, 10);
    expect(r.minSpend, 60);
    expect(r.validFrom, DateTime(2026, 10, 1));
    expect(r.expiresAt, DateTime(2026, 10, 31));
    expect(r.conditions, contains('Non cumulabile'));
  });

  test('empty text yields empty result', () {
    expect(x.extract('', now: now).isEmpty, isTrue);
  });
}
