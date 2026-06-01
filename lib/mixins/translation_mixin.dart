import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';

/// A mixin to provide translation capabilities to StatefulWidget States.
mixin TranslationMixin<T extends StatefulWidget> on State<T> {
  final Map<String, String> _translationCache = {};
  final Map<String, String> translatedNames = {};
  final Map<String, String> translatedLocations = {};
  final Map<String, String> translatedDescriptions = {};

  bool isTranslating = false;

  // ── Use a string instead of a Locale object so equality is value-based ──
  String? _lastTranslatedLang;

  /// Checks if translation is needed based on locale change.
  /// Call this in didChangeDependencies() or after data is fetched.
  Future<void> translateIfNeeded({
    required List<dynamic> items,
    required Future<void> Function(String targetLang) onTranslate,
  }) async {
    if (!mounted) return;

    final targetLang = context.read<LanguageProvider>().locale.languageCode;

    // Skip only if the language is unchanged AND we have already translated
    // at least one item — this prevents skipping on first load.
    final alreadyDone =
        _lastTranslatedLang == targetLang &&
        (translatedNames.isNotEmpty ||
            translatedLocations.isNotEmpty ||
            translatedDescriptions.isNotEmpty);

    if (alreadyDone) return;

    _lastTranslatedLang = targetLang;

    if (targetLang == 'en') {
      if (mounted) {
        setState(() {
          translatedNames.clear();
          translatedLocations.clear();
          translatedDescriptions.clear();
        });
      }
      return;
    }

    await onTranslate(targetLang);
  }

  /// Helper to translate a single string with caching.
  Future<String?> translateText(String text, String targetLang) async {
    if (text.trim().isEmpty) return text;

    final cacheKey = '$text|$targetLang';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey];
    }

    try {
      final result = await TranslationService().translateText(text, targetLang);
      if (result != null) {
        _translationCache[cacheKey] = result;
      }
      return result;
    } catch (e) {
      debugPrint('❌ TranslationMixin Error: $e');
      return null;
    }
  }

  /// Forces a re-translation (useful after new data is loaded).
  /// Clears translated maps so new data gets freshly translated.
  void invalidateTranslation() {
    _lastTranslatedLang = null;
    translatedNames.clear();
    translatedLocations.clear();
    translatedDescriptions.clear();
  }
}
