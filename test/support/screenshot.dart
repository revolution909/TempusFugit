import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Directory screenshots are written to, from `SCREENSHOT_DIR`. When unset the
/// screenshot tests are skipped, so they never slow down the normal suite.
String? get screenshotDir => Platform.environment['SCREENSHOT_DIR'];

/// Loads the SDK's Roboto and Material Icons so screenshots show real text and
/// icons instead of the default test font's solid blocks.
Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$dir/$f');
      if (file.existsSync()) {
        loader.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// Sizes the test surface like a phone. [logical] is in logical pixels.
void usePhone(
  WidgetTester tester, {
  Size logical = const Size(360, 780),
  double textScale = 1.0,
}) {
  // The test binding draws shadows as solid black blocks; a phone draws soft
  // ones. Switched back on after the shot, as the binding requires.
  if (screenshotDir != null) debugDisableShadows = false;
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}

void useBrightness(WidgetTester tester, Brightness brightness) {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
}

/// Renders the whole app surface to `<screenshotDir>/<name>.png`.
Future<void> shoot(WidgetTester tester, String name) async {
  final dir = screenshotDir;
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary = tester.binding.renderViews.first.debugLayer;
    // The root layer is an OffsetLayer; render it as an image.
    final layer = boundary as OffsetLayer;
    final view = tester.view;
    final image = await layer.toImage(
      Offset.zero & (view.physicalSize),
      pixelRatio: 1.0,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$dir/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}
