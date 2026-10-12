import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _enabledKey = 'llm_enabled';

/// Whether the user turned the on-device AI reading on. Off by default: it
/// needs a model and costs battery, so it is strictly opt-in.
class LlmEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> set(bool value) async {
    state = AsyncData(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {
      // Keep the in-memory value; it just won't survive a restart.
    }
  }
}

final llmEnabledProvider = AsyncNotifierProvider<LlmEnabledNotifier, bool>(
  LlmEnabledNotifier.new,
);
