import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/detail/coupon_detail_page.dart';
import 'features/list/coupon_list_page.dart';
import 'providers.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> openCouponFromNotification(ProviderContainer container, String id) async {
  final coupon = await container.read(couponRepositoryProvider).get(id);
  final nav = navigatorKey.currentState;
  if (coupon == null || nav == null) return;
  nav.push(MaterialPageRoute<void>(builder: (_) => CouponDetailPage(couponId: id)));
}

class TempusFugitApp extends ConsumerStatefulWidget {
  const TempusFugitApp({super.key});

  @override
  ConsumerState<TempusFugitApp> createState() => _TempusFugitAppState();
}

class _TempusFugitAppState extends ConsumerState<TempusFugitApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ask once at startup; the OS remembers the answer.
    ref.read(notificationServiceProvider).requestPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Time has passed: re-plan so the nearest reminders (iOS caps pending ones)
    // are always the ones scheduled.
    if (state == AppLifecycleState.resumed) {
      final coupons = ref.read(couponsProvider).value;
      if (coupons != null) {
        ref.read(notificationServiceProvider).sync(coupons);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
    return MaterialApp(
      title: 'TempusFugit',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      locale: const Locale('it'),
      supportedLocales: const [Locale('it'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const CouponListPage(),
    );
  }
}
