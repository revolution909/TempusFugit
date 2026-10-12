import 'package:flutter/material.dart';

import '../../domain/coupon.dart';

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

Color urgencyColor(Urgency u) {
  switch (u) {
    case Urgency.urgent:
      return Colors.red.shade700;
    case Urgency.soon:
      return Colors.orange.shade800;
    case Urgency.ok:
      return Colors.green.shade700;
    case Urgency.expired:
    case Urgency.used:
    case Urgency.none:
      return Colors.grey.shade600;
  }
}

class ExpiryChip extends StatelessWidget {
  const ExpiryChip({super.key, required this.coupon, this.now});

  final Coupon coupon;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final at = now ?? DateTime.now();
    final color = urgencyColor(urgencyOf(coupon, at));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        expiryText(coupon, at),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
