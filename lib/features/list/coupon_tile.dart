import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../domain/coupon.dart';
import '../../ui/tokens.dart';
import '../../ui/urgency.dart';
import '../../ui/widgets/merchant_avatar.dart';
import '../../ui/widgets/urgency_chip.dart';
import '../detail/coupon_detail_page.dart';

/// One coupon in the list: a card that opens the detail with a container
/// transform, reveals "used" / "delete" on swipe, and offers the same actions
/// on long press (and as screen-reader actions) for people who cannot swipe.
class CouponTile extends StatelessWidget {
  const CouponTile({
    super.key,
    required this.coupon,
    required this.now,
    required this.onToggleUsed,
    required this.onDelete,
    required this.onMore,
  });

  final Coupon coupon;
  final DateTime now;
  final VoidCallback onToggleUsed;
  final VoidCallback onDelete;

  /// Long press: opens the full action menu.
  final VoidCallback onMore;

  String get _subtitle {
    final discount = coupon.discountLabel;
    return [
      coupon.merchant,
      if (discount.isNotEmpty) discount,
      coupon.kind == CouponKind.physical ? 'fisico' : 'digitale',
    ].join(' · ');
  }

  String get _spokenLabel =>
      [coupon.title, _subtitle, expiryText(coupon, now)].join(', ');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(Corner.large);
    final usedLabel = coupon.isUsed ? 'Riattiva' : 'Segna come usato';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.xs),
      child: Slidable(
        key: ValueKey(coupon.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.32,
          children: [
            SlidableAction(
              onPressed: (_) => onToggleUsed(),
              icon: coupon.isUsed ? Icons.undo : Icons.check,
              label: coupon.isUsed ? 'Riattiva' : 'Usato',
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              borderRadius: radius,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.32,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              icon: Icons.delete_outline,
              label: 'Elimina',
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              borderRadius: radius,
            ),
          ],
        ),
        child: OpenContainer<void>(
          transitionType: ContainerTransitionType.fade,
          transitionDuration: Motion.of(context, Motion.container),
          tappable: false,
          closedElevation: 0,
          openElevation: 0,
          closedColor: scheme.surfaceContainerLow,
          openColor: scheme.surface,
          middleColor: scheme.surface,
          closedShape: RoundedRectangleBorder(borderRadius: radius),
          openBuilder: (context, _) => CouponDetailPage(couponId: coupon.id),
          closedBuilder: (context, open) => Semantics(
            container: true,
            button: true,
            label: _spokenLabel,
            onTap: open,
            onLongPress: onMore,
            customSemanticsActions: {
              CustomSemanticsAction(label: usedLabel): onToggleUsed,
              const CustomSemanticsAction(label: 'Elimina'): onDelete,
            },
            // The container transform builds this child in an overlay with no
            // Material above it, so the ink needs its own transparent one.
            child: ExcludeSemantics(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: open,
                  onLongPress: onMore,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 88),
                    child: Padding(
                      padding: const EdgeInsets.all(Gap.l),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MerchantAvatar(name: coupon.merchant),
                          const SizedBox(width: Gap.l),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coupon.title,
                                  style: text.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _subtitle,
                                  style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: Gap.s),
                                UrgencyChip(coupon: coupon, now: now),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
