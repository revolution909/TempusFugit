import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it');
  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init(
        onTap: (id) => openCouponFromNotification(container, id),
      );
  runApp(UncontrolledProviderScope(
    container: container,
    child: const TempusFugitApp(),
  ));
}
