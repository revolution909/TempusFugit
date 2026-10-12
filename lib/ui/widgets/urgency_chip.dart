import 'package:flutter/material.dart';

import '../../domain/coupon.dart';
import '../tokens.dart';
import '../urgency.dart';

/// Expiry label with an icon and a tonal background taken from the theme.
class UrgencyChip extends StatelessWidget {
  const UrgencyChip({super.key, required this.coupon, this.now});

  final Coupon coupon;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final at = now ?? DateTime.now();
    final level = urgencyOf(coupon, at);
    final colors = urgencyPair(context, level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 6),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(Corner.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(urgencyIcon(level), size: 16, color: colors.onContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              expiryText(coupon, at),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
