import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/notifications/notification_service.dart';

/// Notification service that records syncs instead of touching the platform.
class FakeNotifications extends NotificationService {
  final syncs = <List<Coupon>>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(List<Coupon> coupons, {DateTime? now}) async =>
      syncs.add(coupons);
}
