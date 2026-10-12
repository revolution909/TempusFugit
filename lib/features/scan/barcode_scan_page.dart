import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../extraction/extraction_pipeline.dart';
import '../../ui/feedback.dart';
import '../../ui/tokens.dart';

/// Live camera view that returns the first barcode / QR code it sees.
///
/// Only the code inside the frame is read, so a code at the edge of the
/// picture (or on the next coupon) is not picked up by mistake.
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        _done = true;
        haptic();
        Navigator.of(context).pop(FoundCode(v, b.format.name));
        return;
      }
    }
  }

  /// A wide frame: most coupons carry a 1D barcode, which is wider than tall.
  static Rect _frameFor(Size area) {
    final width = (area.width - 2 * Gap.xl).clamp(0.0, 420.0);
    final height = width * 0.6;
    return Rect.fromCenter(
      center: Offset(area.width / 2, area.height * 0.45),
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // The camera picture is always dark: keep the bars and text legible on it.
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Inquadra il codice'),
          actions: [_TorchButton(controller: _controller)],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final frame = _frameFor(constraints.biggest);
            return Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  scanWindow: frame,
                  errorBuilder: (context, error) => _CameraError(
                    denied:
                        error.errorCode ==
                        MobileScannerErrorCode.permissionDenied,
                    code: error.errorCode.name,
                    onRetry: _controller.start,
                  ),
                ),
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _FramePainter(frame)),
                  ),
                ),
                Positioned(
                  left: Gap.l,
                  right: Gap.l,
                  top: frame.bottom + Gap.xl,
                  child: Text(
                    'Il codice viene letto in automatico',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Flash button that shows the real state of the torch and is hidden when the
/// phone has none.
class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }
        final on = state.torchState == TorchState.on;
        return IconButton(
          tooltip: on ? 'Spegni la torcia' : 'Accendi la torcia',
          isSelected: on,
          icon: const Icon(Icons.flash_off),
          selectedIcon: const Icon(Icons.flash_on),
          onPressed: controller.toggleTorch,
        );
      },
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({
    required this.denied,
    required this.code,
    required this.onRetry,
  });

  final bool denied;
  final String code;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: Gap.l),
            Text(
              denied
                  ? 'Serve il permesso della fotocamera per scansionare i '
                        'codici. Puoi darlo dalle impostazioni del telefono.'
                  : 'Fotocamera non disponibile ($code).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: Gap.l),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims everything outside [frame] and draws the four corners of the frame.
class _FramePainter extends CustomPainter {
  _FramePainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(Corner.large),
    );
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(scrim, Paint()..color = Colors.black54);

    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const arm = 28.0;
    const r = Corner.large;
    final l = frame.left, t = frame.top, rr = frame.right, b = frame.bottom;
    final path = Path()
      // top-left
      ..moveTo(l, t + arm)
      ..lineTo(l, t + r)
      ..arcToPoint(Offset(l + r, t), radius: const Radius.circular(r))
      ..lineTo(l + arm, t)
      // top-right
      ..moveTo(rr - arm, t)
      ..lineTo(rr - r, t)
      ..arcToPoint(Offset(rr, t + r), radius: const Radius.circular(r))
      ..lineTo(rr, t + arm)
      // bottom-right
      ..moveTo(rr, b - arm)
      ..lineTo(rr, b - r)
      ..arcToPoint(Offset(rr - r, b), radius: const Radius.circular(r))
      ..lineTo(rr - arm, b)
      // bottom-left
      ..moveTo(l + arm, b)
      ..lineTo(l + r, b)
      ..arcToPoint(Offset(l, b - r), radius: const Radius.circular(r))
      ..lineTo(l, b - arm);
    canvas.drawPath(path, corner);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.frame != frame;
}
