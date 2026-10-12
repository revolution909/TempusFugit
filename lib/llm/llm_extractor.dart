import '../extraction/rule_extractor.dart';

/// Where the on-device model comes from.
enum LlmSource {
  /// The OS ships it (Gemini Nano, Apple Foundation Models): nothing to download.
  system,

  /// A model file the user downloaded.
  downloaded,
}

/// What the extractor can do on this device right now.
sealed class LlmStatus {
  const LlmStatus();
}

/// No usable model on this device, and none can be installed (e.g. unsupported
/// CPU architecture). The app falls back to the rules alone.
class LlmUnavailable extends LlmStatus {
  const LlmUnavailable([this.reason]);
  final String? reason;
}

/// A model can be used once the user downloads it.
class LlmNeedsDownload extends LlmStatus {
  const LlmNeedsDownload();
}

class LlmReady extends LlmStatus {
  const LlmReady(this.source);
  final LlmSource source;
}

/// Progress of a model download, 0..100.
typedef ModelDownloadProgress = void Function(int percent);

/// Runs the on-device model. The only contract the rest of the app depends on,
/// so the implementation (and the plugin behind it) can be swapped or faked.
///
/// Implementations must never throw from [extract]: any failure is a `null`
/// result, which leaves the user with the rule-based fields.
abstract class LlmExtractor {
  Future<LlmStatus> status();

  /// Reads [text] and returns the fields found, or null.
  Future<ExtractedCoupon?> extract(String text, {required DateTime now});

  /// Downloads the model. Throws on failure (the settings screen shows it).
  Future<void> downloadModel({ModelDownloadProgress? onProgress});

  /// Cancels a running [downloadModel].
  void cancelDownload();

  /// Removes a downloaded model to free space.
  Future<void> deleteModel();
}
