import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/llm/coupon_prompt.dart';

void main() {
  final now = DateTime(2026, 10, 12);
  const source =
      'Conad Buono sconto 5 euro su spesa minima 40 euro. '
      'Valido fino al 31/12/2026. Codice: CONAD5X';

  group('buildCouponPrompt', () {
    test('contains the date, the schema and the quoted text', () {
      final p = buildCouponPrompt(source, now);
      expect(p, contains('Oggi è 2026-10-12'));
      expect(p, contains('expiresAt'));
      expect(p, contains('"Conad Buono sconto 5 euro'));
      expect(p.trimRight(), endsWith('JSON:'));
    });

    test('truncates long text', () {
      final p = buildCouponPrompt('a' * 5000, now);
      expect(p, contains('a' * maxPromptTextLength));
      expect(p, isNot(contains('a' * (maxPromptTextLength + 1))));
    });

    test('escapes quotes and newlines so the text cannot break the prompt', () {
      final p = buildCouponPrompt('riga1\n"virgolette"', now);
      expect(p, contains(r'riga1\n\"virgolette\"'));
    });
  });

  group('parseLlmResponse', () {
    ExtractedCouponOrNull parse(String raw, {String text = source}) =>
        parseLlmResponse(raw, sourceText: text, now: now);

    test('parses a clean reply', () {
      final r = parse(
        '''{"merchant":"Conad","title":"Buono sconto 5 €",
        "expiresAt":"2026-12-31","validFrom":null,"discountType":"amount",
        "discountValue":5,"minSpend":40,"promoCode":"CONAD5X","conditions":null}''',
      )!;
      expect(r.merchant, 'Conad');
      expect(r.expiresAt, DateTime(2026, 12, 31));
      expect(r.discountType, DiscountType.amount);
      expect(r.discountValue, 5);
      expect(r.minSpend, 40);
      expect(r.codeValue, 'CONAD5X');
      expect(r.uncertain, contains('expiresAt'));
    });

    test('finds the object inside a code fence with chatter around it', () {
      final r = parse(
        'Ecco il risultato:\n```json\n{"merchant":"Conad"}\n```\nSpero sia utile {ok}',
      )!;
      expect(r.merchant, 'Conad');
    });

    test('braces inside strings do not confuse the extractor', () {
      final r = parse('{"title":"Offerta {speciale}","merchant":"Conad"}')!;
      expect(r.title, 'Offerta {speciale}');
    });

    test('returns null for non-JSON, truncated JSON and non-objects', () {
      expect(parse('non so'), isNull);
      expect(parse(''), isNull);
      expect(parse('{"merchant":"Conad"'), isNull);
      expect(parse('[1,2,3]'), isNull);
      expect(parse('{"merchant":}'), isNull);
    });

    test('returns null when everything is null', () {
      expect(
        parse('{"merchant":null,"expiresAt":null,"discountType":null}'),
        isNull,
      );
    });

    test('drops a merchant that is not in the source text', () {
      final r = parse('{"merchant":"Esselunga","title":"Sconto"}')!;
      expect(r.merchant, isNull);
      expect(r.title, 'Sconto');
    });

    test('merchant grounding ignores case and punctuation', () {
      final r = parse('{"merchant":"C.O.N.A.D"}')!;
      expect(r.merchant, 'C.O.N.A.D');
    });

    test('drops an invented promo code and accepts a grounded one', () {
      expect(
        parse('{"promoCode":"FAKE1234","title":"x1"}', text: source)!.codeValue,
        isNull,
      );
      expect(parse('{"promoCode":"conad5x"}')!.codeValue, 'conad5x');
    });

    test('rejects promo codes with bad characters or length', () {
      expect(parse('{"promoCode":"AB","title":"xx"}')!.codeValue, isNull);
      expect(parse('{"promoCode":"A B C D","title":"xx"}')!.codeValue, isNull);
    });

    test('rejects impossible and out-of-range dates', () {
      expect(
        parse('{"expiresAt":"2026-02-31","title":"xx"}')!.expiresAt,
        isNull,
      );
      expect(
        parse('{"expiresAt":"31/12/2026","title":"xx"}')!.expiresAt,
        isNull,
      );
      expect(
        parse('{"expiresAt":"2015-01-01","title":"xx"}')!.expiresAt,
        isNull,
      );
      expect(
        parse('{"expiresAt":"2090-01-01","title":"xx"}')!.expiresAt,
        isNull,
      );
    });

    test('drops validFrom when it is after expiresAt', () {
      final r = parse('{"validFrom":"2026-12-31","expiresAt":"2026-11-01"}')!;
      expect(r.validFrom, isNull);
      expect(r.expiresAt, DateTime(2026, 11, 1));
    });

    test('validates percentages and amounts together with their type', () {
      var r = parse(
        '{"discountType":"percent","discountValue":150,"title":"xx"}',
      )!;
      expect(r.discountType, isNull);
      expect(r.discountValue, isNull);

      r = parse('{"discountType":"percent","discountValue":20}')!;
      expect(r.discountType, DiscountType.percent);
      expect(r.discountValue, 20);

      r = parse('{"discountType":"amount","discountValue":"5,50"}')!;
      expect(r.discountValue, 5.5);

      r = parse('{"discountType":"amount","discountValue":-3,"title":"xx"}')!;
      expect(r.discountType, isNull);
    });

    test('twoForOne and freebie carry no value', () {
      final r = parse('{"discountType":"twoForOne","discountValue":2}')!;
      expect(r.discountType, DiscountType.twoForOne);
      expect(r.discountValue, isNull);
    });

    test('unknown discount types are dropped', () {
      expect(
        parse('{"discountType":"magic","title":"xx"}')!.discountType,
        isNull,
      );
      expect(
        parse('{"discountType":"other","title":"xx"}')!.discountType,
        isNull,
      );
    });

    test('ignores string "null", wrong types and over-long strings', () {
      final r = parse(
        '{"title":"null","merchant":42,"conditions":"${'x' * 300}","minSpend":"abc"}',
      );
      expect(r, isNull);
    });

    test('is lenient about number formats for minSpend', () {
      expect(parse('{"minSpend":"40,5"}')!.minSpend, 40.5);
      expect(parse('{"minSpend":0,"title":"xx"}')!.minSpend, isNull);
    });
  });
}

typedef ExtractedCouponOrNull = dynamic;
