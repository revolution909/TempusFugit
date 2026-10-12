import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_builtin_ai/flutter_edge_ai_builtin_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../extraction/rule_extractor.dart';
import 'coupon_prompt.dart';
import 'llm_extractor.dart';

/// [LlmExtractor] backed by `flutter_edge_ai`. This is the ONLY file that
/// touches that package: it is brand new and its API may still move, so
/// everything else in the app talks to the [LlmExtractor] interface.
///
/// Model choice, in order:
///  1. the model the OS ships (Gemini Nano / Apple Foundation Models) when the
///     device supports it: nothing to download;
///  2. otherwise a small `.litertlm` model the user downloads on request.
class EdgeAiExtractor implements LlmExtractor {
  /// Hugging Face repo of the downloadable model. Qwen3-0.6B is small enough
  /// for mid-range phones. Verify its license and gating on the model page
  /// before shipping; Gemma 3 1B is the alternative but is gated.
  static const modelRepo = 'litert-community/Qwen3-0.6B';

  static const _installedKey = 'llm_downloaded_model';

  /// Whole context window (prompt + reply). `.litertlm` needs at least 1024;
  /// the prompt with its two examples plus up to 1500 characters of coupon
  /// text fits comfortably in 2048.
  static const _contextTokens = 2048;
  static const _maxReplyTokens = 300;
  static const _replyTimeout = Duration(seconds: 45);
  static const _idleUnload = Duration(minutes: 1);

  Future<void>? _init;
  InferenceModel? _model;
  LlmSource? _modelSource;
  bool _systemInstalled = false;
  Timer? _unloadTimer;
  CancelToken? _cancel;

  /// Calls queue up here: on-device inference is one-at-a-time.
  Future<void> _queue = Future.value();

  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureInit() {
    return _init ??=
        FlutterEdgeAi.initialize(
          inferenceEngines: [LiteRtLmEngine(), BuiltInAiEngine()],
        ).catchError((Object e) {
          _init = null; // allow a retry later
          throw e;
        });
  }

  @override
  Future<LlmStatus> status() async {
    if (!_mobile) {
      return const LlmUnavailable('Disponibile solo su Android e iOS.');
    }
    try {
      await _ensureInit();
      if (await BuiltInAi.availability() == BuiltInAiAvailability.available) {
        return const LlmReady(LlmSource.system);
      }
      if (await _hasDownloadedModel()) {
        return const LlmReady(LlmSource.downloaded);
      }
      return const LlmNeedsDownload();
    } catch (e) {
      debugPrint('LLM status failed: $e');
      return LlmUnavailable(e.toString());
    }
  }

  Future<bool> _hasDownloadedModel() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_installedKey) != true) return false;
    final files = await FlutterEdgeAi.listInstalledModels();
    return files.any((f) => f.endsWith('.litertlm'));
  }

  @override
  Future<ExtractedCoupon?> extract(String text, {required DateTime now}) {
    final completer = Completer<ExtractedCoupon?>();
    _queue = _queue.then((_) async {
      completer.complete(await _extractNow(text, now));
    });
    return completer.future;
  }

  Future<ExtractedCoupon?> _extractNow(String text, DateTime now) async {
    InferenceModelSession? session;
    try {
      final st = await status();
      if (st is! LlmReady) return null;
      final model = await _loadModel(st.source);
      if (model == null) return null;

      session = await model.createSession(
        temperature: 0,
        topK: 1,
        maxOutputTokens: _maxReplyTokens,
        enableThinking: false,
      );
      await session.addQueryChunk(
        Message.text(text: buildCouponPrompt(text, now), isUser: true),
      );
      final reply = await session.getResponse().timeout(_replyTimeout);
      return parseLlmResponse(reply, sourceText: text, now: now);
    } on TimeoutException {
      try {
        await session?.stopGeneration();
      } catch (_) {}
      return null;
    } catch (e) {
      debugPrint('LLM extraction failed: $e');
      return null;
    } finally {
      try {
        await session?.close();
      } catch (_) {}
      _scheduleUnload();
    }
  }

  Future<InferenceModel?> _loadModel(LlmSource source) async {
    _unloadTimer?.cancel();
    if (_model != null && !_model!.isClosed && _modelSource == source) {
      return _model;
    }
    await _unload();

    if (source == LlmSource.system) {
      final spec = BuiltInAiModels.forCurrentPlatform;
      if (spec == null) return null;
      if (!_systemInstalled) {
        await FlutterEdgeAi.installModel(
          modelType: ModelType.general,
          fileType: ModelFileType.builtIn,
        ).fromBundled(spec.name).install();
        _systemInstalled = true;
      }
    } else if (!FlutterEdgeAi.hasActiveModel()) {
      // The downloaded file exists but no model is active (e.g. state lost).
      debugPrint('LLM: downloaded model present but not active');
      return null;
    }

    _model = await FlutterEdgeAi.getActiveModel(
      maxTokens: _contextTokens,
      // CPU is the safe default across phones; GPU drivers vary widely.
      preferredBackend: PreferredBackend.cpu,
    );
    _modelSource = source;
    return _model;
  }

  /// Frees the model's memory shortly after the last use.
  void _scheduleUnload() {
    _unloadTimer?.cancel();
    _unloadTimer = Timer(_idleUnload, () => unawaited(_unload()));
  }

  Future<void> _unload() async {
    final m = _model;
    _model = null;
    _modelSource = null;
    try {
      await m?.close();
    } catch (_) {}
  }

  @override
  Future<void> downloadModel({ModelDownloadProgress? onProgress}) async {
    await _ensureInit();
    final token = _cancel = CancelToken();
    final resolved = await FlutterEdgeAi.resolveHuggingFace(
      modelRepo,
      fileType: ModelFileType.litertlm,
    );
    await FlutterEdgeAi.installModel(
          modelType: resolved.modelType ?? ModelType.qwen3,
          fileType: resolved.fileType,
        )
        .fromNetwork(resolved.url)
        .withProgress((p) => onProgress?.call(p))
        .withCancelToken(token)
        .install();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_installedKey, true);
  }

  @override
  void cancelDownload() => _cancel?.cancel('Annullato dall\'utente');

  @override
  Future<void> deleteModel() async {
    await _ensureInit();
    await _unload();
    for (final f in await FlutterEdgeAi.listInstalledModels()) {
      if (f.endsWith('.litertlm')) await FlutterEdgeAi.uninstallModel(f);
    }
    await FlutterEdgeAi.clearActiveInferenceIdentity();
    _systemInstalled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_installedKey);
  }
}
