import '../extraction/rule_extractor.dart';

/// Whether the rules left enough gaps to be worth running the LLM. Skipping it
/// when the rules already found everything saves time and battery.
bool rulesLeftGaps(ExtractedCoupon rules, String text) {
  if (text.trim().length < 10) return false;
  return rules.merchant == null ||
      rules.expiresAt == null ||
      rules.discountType == null ||
      rules.uncertain.isNotEmpty;
}

/// Combines the rule result with the LLM's. Rules win wherever they are
/// confident; the LLM only fills fields the rules left empty or flagged as
/// uncertain. Fields taken from the LLM are listed in `aiFilled`.
ExtractedCoupon mergeExtraction(ExtractedCoupon rules, ExtractedCoupon? llm) {
  if (llm == null) return rules;

  final uncertain = {...rules.uncertain};
  final ai = <String>{};

  T? pick<T>(String field, T? fromRules, T? fromLlm) {
    final ruleIsSure = fromRules != null && !rules.uncertain.contains(field);
    if (ruleIsSure || fromLlm == null) return fromRules;
    ai.add(field);
    uncertain.remove(field);
    if (llm.uncertain.contains(field)) uncertain.add(field);
    return fromLlm;
  }

  final merchant = pick('merchant', rules.merchant, llm.merchant);
  final expiresAt = pick('expiresAt', rules.expiresAt, llm.expiresAt);
  final validFrom = pick('validFrom', rules.validFrom, llm.validFrom);
  final minSpend = pick('minSpend', rules.minSpend, llm.minSpend);
  final code = pick('codeValue', rules.codeValue, llm.codeValue);
  final conditions = pick('conditions', rules.conditions, llm.conditions);

  // Discount type and value travel together.
  final useLlmDiscount = rules.discountType == null && llm.discountType != null;
  if (useLlmDiscount) ai.add('discount');

  // The rules derive their title from the discount, so it is only missing when
  // they found no discount.
  final title = rules.title ?? llm.title;
  if (rules.title == null && llm.title != null) ai.add('title');

  return ExtractedCoupon(
    merchant: merchant,
    title: title,
    expiresAt: expiresAt,
    validFrom: validFrom,
    discountType: useLlmDiscount ? llm.discountType : rules.discountType,
    discountValue: useLlmDiscount ? llm.discountValue : rules.discountValue,
    minSpend: minSpend,
    codeValue: code,
    conditions: conditions,
    uncertain: uncertain,
    aiFilled: ai,
  );
}
