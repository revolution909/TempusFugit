import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/coupon.dart';
import 'barcode_view.dart';

/// Full-screen code for the checkout: white background, max brightness, screen
/// kept on. Brightness and wakelock are restored on leaving.
class CassaPage extends StatefulWidget {
  const CassaPage({super.key, required this.coupon});

  final Coupon coupon;

  @override
  State<CassaPage> createState() => _CassaPageState();
}

class _CassaPageState extends State<CassaPage> {
  @override
  void initState() {
    super.initState();
    _apply(() async {
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
      await WakelockPlus.enable();
    });
  }

  @override
  void dispose() {
    _apply(() async {
      await ScreenBrightness().resetApplicationScreenBrightness();
      await WakelockPlus.disable();
    });
    super.dispose();
  }

  // Platform calls can fail (e.g. unsupported platform in tests); the code is
  // still usable without them.
  void _apply(Future<void> Function() action) {
    action().catchError((Object e) => debugPrint('Cassa mode: $e'));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coupon;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(c.merchant),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                if (c.codeValue != null)
                  CodeView(
                    value: c.codeValue!,
                    format: c.codeFormat,
                    height: 160,
                    textStyle: const TextStyle(
                        color: Colors.black, fontSize: 28, letterSpacing: 2),
                  )
                else
                  const Text('Nessun codice salvato per questo coupon.',
                      style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
