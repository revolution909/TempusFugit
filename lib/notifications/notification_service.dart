import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/coupon.dart';
import 'reminder_planner.dart';

/// Schedules local expiry reminders. The set of pending notifications is always
/// recomputed from the coupon list ([sync]), so it can be called after any
/// change and on app resume.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this.planner = const ReminderPlanner(),
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderPlanner planner;
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'coupon_expiry',
      'Scadenze coupon',
      channelDescription: 'Avvisi prima che un coupon scada',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// [onTap] receives the coupon id stored in the notification payload.
  Future<void> init({required void Function(String couponId) onTap}) async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Could not resolve local timezone, reminders may be offset: $e');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested explicitly via [requestPermission].
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final id = r.payload;
        if (id != null && id.isNotEmpty) onTap(id);
      },
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  /// Replaces all pending reminders with the ones planned for [coupons].
  Future<void> sync(List<Coupon> coupons, {DateTime? now}) async {
    if (!_ready) return;
    final at = now ?? DateTime.now();
    final byId = {for (final c in coupons) c.id: c};
    await _plugin.cancelAllPendingNotifications();
    for (final r in planner.plan(coupons, at)) {
      final c = byId[r.couponId]!;
      await _plugin.zonedSchedule(
        id: r.id,
        title: '${c.merchant}: ${c.title}',
        body: _body(r.daysBefore),
        scheduledDate: tz.TZDateTime.from(r.fireAt, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: c.id,
      );
    }
  }

  static String _body(int daysBefore) {
    switch (daysBefore) {
      case 0:
        return 'Scade oggi: usalo prima di perderlo!';
      case 1:
        return 'Scade domani';
      default:
        return 'Scade tra $daysBefore giorni';
    }
  }
}
