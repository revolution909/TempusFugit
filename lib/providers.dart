import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/coupon_repository.dart';
import 'data/database.dart';
import 'domain/coupon.dart';
import 'extraction/extraction_pipeline.dart';
import 'llm/edge_ai_extractor.dart';
import 'llm/llm_extractor.dart';
import 'notifications/notification_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final couponRepositoryProvider =
    Provider<CouponRepository>((ref) => CouponRepository(ref.watch(databaseProvider)));

final couponsProvider = StreamProvider<List<Coupon>>(
    (ref) => ref.watch(couponRepositoryProvider).watchAll());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final extractionPipelineProvider =
    Provider<ExtractionPipeline>((ref) => ExtractionPipeline());

final llmExtractorProvider =
    Provider<LlmExtractor>((ref) => EdgeAiExtractor());

/// What the on-device model can do right now. Invalidate after a download or
/// deletion to refresh it.
final llmStatusProvider = FutureProvider.autoDispose<LlmStatus>(
    (ref) => ref.watch(llmExtractorProvider).status());

/// Keeps the pending notifications in line with the coupon list. Watch it once
/// at the app root.
final reminderSyncProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  ref.listen(couponsProvider, (_, next) {
    final coupons = next.value;
    if (coupons != null) unawaited(service.sync(coupons));
  }, fireImmediately: true);
});
