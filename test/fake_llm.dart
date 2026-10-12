import 'dart:async';

import 'package:tempusfugit/extraction/rule_extractor.dart';
import 'package:tempusfugit/llm/llm_extractor.dart';

/// Scriptable [LlmExtractor] for tests.
class FakeLlm implements LlmExtractor {
  LlmStatus statusValue = const LlmReady(LlmSource.downloaded);

  /// When set, [extract] waits for it, so tests control when the result lands.
  Completer<ExtractedCoupon?>? gate;
  ExtractedCoupon? result;
  Object? error;

  int extractCalls = 0;
  int downloadCalls = 0;
  int deleteCalls = 0;
  bool cancelled = false;

  /// Lets a test drive a download: gets the progress callback, returns when done.
  Future<void> Function(ModelDownloadProgress? onProgress)? onDownload;

  @override
  Future<LlmStatus> status() async => statusValue;

  @override
  Future<ExtractedCoupon?> extract(String text, {required DateTime now}) async {
    extractCalls++;
    if (error != null) throw error!;
    if (gate != null) return gate!.future;
    return result;
  }

  @override
  Future<void> downloadModel({ModelDownloadProgress? onProgress}) async {
    downloadCalls++;
    await onDownload?.call(onProgress);
  }

  @override
  void cancelDownload() => cancelled = true;

  @override
  Future<void> deleteModel() async => deleteCalls++;
}
