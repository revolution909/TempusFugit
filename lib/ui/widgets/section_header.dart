import 'package:flutter/material.dart';

import '../tokens.dart';

/// Heading of a group of items. Marked as a header for screen readers so they
/// can jump between groups.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.count,
    this.padding = const EdgeInsets.fromLTRB(Gap.l, Gap.xl, Gap.l, Gap.s),
  });

  final String title;
  final int? count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Padding(
        padding: padding,
        child: Text(
          count == null ? title : '$title · $count',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
