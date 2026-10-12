import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/coupon.dart';
import '../../providers.dart';
import '../../ui/feedback.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import 'barcode_view.dart';

/// Full-screen code for the checkout: light surface (readers need dark bars on
/// light), max brightness, screen kept on. Brightness and wakelock are
/// restored on leaving. Always light, whatever the app theme.
class CassaPage extends ConsumerStatefulWidget {
  const CassaPage({super.key, required this.coupon});

  final Coupon coupon;

  @override
  ConsumerState<CassaPage> createState() => _CassaPageState();
}

class _CassaPageState extends ConsumerState<CassaPage> {
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

  Future<void> _markUsed() async {
    final c = widget.coupon;
    final repo = ref.read(couponRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await repo.setStatus(c.id, CouponStatus.used);
    haptic();
    navigator.pop();
    showUndoSnackBar(
      messenger,
      'Segnato come usato',
      () => repo.setStatus(c.id, c.status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coupon;
    return Theme(
      data: buildTheme(Brightness.light),
      child: Builder(
        builder: (context) {
          final text = Theme.of(context).textTheme;
          return Scaffold(
            backgroundColor: codeSurface,
            appBar: AppBar(
              backgroundColor: codeSurface,
              foregroundColor: codeInk,
              title: Text(c.merchant),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.title,
                        textAlign: TextAlign.center,
                        style: text.titleLarge?.copyWith(
                          color: codeInk,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Gap.xxl),
                      if (c.codeValue != null)
                        CodeView(
                          value: c.codeValue!,
                          format: c.codeFormat,
                          height: 160,
                          textStyle: text.headlineMedium?.copyWith(
                            color: codeInk,
                            letterSpacing: 2,
                          ),
                        )
                      else
                        Text(
                          'Nessun codice salvato per questo coupon.',
                          style: text.bodyLarge?.copyWith(color: codeInk),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: c.isUsed
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(Gap.l),
                      child: FilledButton.tonalIcon(
                        onPressed: _markUsed,
                        icon: const Icon(Icons.check),
                        label: const Text('Fatto: segna come usato'),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
