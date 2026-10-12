import 'package:flutter/material.dart';

import '../domain/coupon.dart';
import 'urgency_colors.dart';

enum Urgency { none, expired, urgent, soon, ok, used }

Urgency urgencyOf(Coupon c, DateTime now) {
  if (c.isUsed) return Urgency.used;
  final days = c.daysLeft(now);
  if (days == null) return Urgency.none;
  if (c.isExpired(now)) return Urgency.expired;
  if (days <= 3) return Urgency.urgent;
  if (days <= 7) return Urgency.soon;
  return Urgency.ok;
}

String expiryText(Coupon c, DateTime now) {
  if (c.isUsed) return 'Usato';
  final days = c.daysLeft(now);
  if (days == null) return 'Senza scadenza';
  if (c.isExpired(now)) {
    final ago = -days;
    return ago <= 1 ? 'Scaduto ieri' : 'Scaduto da $ago giorni';
  }
  if (days == 0) return 'Scade oggi';
  if (days == 1) return 'Scade domani';
  return 'Scade tra $days giorni';
}

/// Icon per level. Colour alone must never carry the meaning (colour-blind
/// users, bright sunlight), so every level also has a distinct icon and text.
IconData urgencyIcon(Urgency u) => switch (u) {
  Urgency.urgent => Icons.priority_high,
  Urgency.soon => Icons.schedule,
  Urgency.ok => Icons.event_available,
  Urgency.none => Icons.all_inclusive,
  Urgency.expired => Icons.history,
  Urgency.used => Icons.check_circle_outline,
};

/// Colours for [u] from the current theme.
UrgencyPair urgencyPair(BuildContext context, Urgency u) {
  final c = Theme.of(context).extension<UrgencyColors>()!;
  return switch (u) {
    Urgency.urgent => c.urgent,
    Urgency.soon => c.soon,
    Urgency.ok => c.ok,
    Urgency.none || Urgency.expired || Urgency.used => c.muted,
  };
}
