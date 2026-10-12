import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/extraction/rule_extractor.dart';
import 'package:tempusfugit/llm/llm_merge.dart';

void main() {
  group('mergeExtraction', () {
    test('without an LLM result the rules pass through unchanged', () {
      const rules = ExtractedCoupon(merchant: 'Lidl');
      expect(mergeExtraction(rules, null), same(rules));
    });

    test('confident rule fields are never overwritten', () {
      const rules = ExtractedCoupon(
        merchant: 'Lidl',
        discountType: DiscountType.percent,
        discountValue: 20,
        title: 'Sconto 20%',
      );
      final llm = ExtractedCoupon(
        merchant: 'Coop',
        discountType: DiscountType.amount,
        discountValue: 5,
        title: 'Altro',
        expiresAt: DateTime(2026, 12, 31),
      );
      final m = mergeExtraction(rules, llm);
      expect(m.merchant, 'Lidl');
      expect(m.discountType, DiscountType.percent);
      expect(m.discountValue, 20);
      expect(m.title, 'Sconto 20%');
      expect(m.expiresAt, DateTime(2026, 12, 31));
      expect(m.aiFilled, {'expiresAt'});
    });

    test('empty rule fields are filled by the LLM and listed in aiFilled', () {
      const rules = ExtractedCoupon();
      final llm = ExtractedCoupon(
        merchant: 'Conad',
        title: '2x1 il martedì',
        discountType: DiscountType.twoForOne,
        minSpend: 30,
        codeValue: 'ABC123',
        conditions: 'Escluso festivi.',
        uncertain: const {'expiresAt'},
        expiresAt: DateTime(2027, 1, 5),
      );
      final m = mergeExtraction(rules, llm);
      expect(m.merchant, 'Conad');
      expect(m.discountType, DiscountType.twoForOne);
      expect(m.title, '2x1 il martedì');
      expect(m.minSpend, 30);
      expect(m.codeValue, 'ABC123');
      expect(m.conditions, 'Escluso festivi.');
      expect(m.expiresAt, DateTime(2027, 1, 5));
      expect(m.aiFilled, {
        'merchant',
        'title',
        'discount',
        'minSpend',
        'codeValue',
        'conditions',
        'expiresAt',
      });
      expect(m.uncertain, {'expiresAt'});
    });

    test('a field the rules were unsure about is replaced by the LLM', () {
      final rules = ExtractedCoupon(
        expiresAt: DateTime(2026, 11, 1),
        uncertain: const {'expiresAt'},
      );
      final llm = ExtractedCoupon(
        expiresAt: DateTime(2026, 12, 31),
        uncertain: const {'expiresAt'},
      );
      final m = mergeExtraction(rules, llm);
      expect(m.expiresAt, DateTime(2026, 12, 31));
      expect(m.aiFilled, contains('expiresAt'));
      expect(m.uncertain, contains('expiresAt'));
    });

    test('an uncertain rule field stays when the LLM has nothing better', () {
      final rules = ExtractedCoupon(
        merchant: 'Bar Centrale',
        uncertain: const {'merchant'},
      );
      const llm = ExtractedCoupon(title: 'Caffè');
      final m = mergeExtraction(rules, llm);
      expect(m.merchant, 'Bar Centrale');
      expect(m.uncertain, contains('merchant'));
      expect(m.aiFilled, isNot(contains('merchant')));
    });

    test('an LLM-provided merchant clears the rule-uncertainty flag', () {
      final rules = ExtractedCoupon(
        merchant: 'Riga a caso',
        uncertain: const {'merchant'},
      );
      const llm = ExtractedCoupon(merchant: 'Conad');
      final m = mergeExtraction(rules, llm);
      expect(m.merchant, 'Conad');
      expect(m.uncertain, isNot(contains('merchant')));
    });
  });

  group('rulesLeftGaps', () {
    const text = 'Lidl buono sconto 10 euro valido fino al 31/12/2026';

    test('no gaps when merchant, expiry and discount are all found', () {
      final full = ExtractedCoupon(
        merchant: 'Lidl',
        expiresAt: DateTime(2026, 12, 31),
        discountType: DiscountType.amount,
      );
      expect(rulesLeftGaps(full, text), isFalse);
    });

    test('gap when anything is missing or uncertain', () {
      expect(
        rulesLeftGaps(const ExtractedCoupon(merchant: 'Lidl'), text),
        isTrue,
      );
      final unsure = ExtractedCoupon(
        merchant: 'Lidl',
        expiresAt: DateTime(2026, 12, 31),
        discountType: DiscountType.amount,
        uncertain: const {'expiresAt'},
      );
      expect(rulesLeftGaps(unsure, text), isTrue);
    });

    test('no point running the model on near-empty text', () {
      expect(rulesLeftGaps(const ExtractedCoupon(), '  ab '), isFalse);
      expect(rulesLeftGaps(const ExtractedCoupon(), ''), isFalse);
    });
  });
}
