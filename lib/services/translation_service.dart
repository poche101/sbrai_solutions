import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class TranslationService {
  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// Translates [text] to the target [languageCode] (e.g., 'fr', 'es', 'en') via Laravel backend.
  Future<String> translateText(String text, String targetLanguageCode) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return text;

    try {
      debugPrint("🔍 [Flutter] Requesting Translation for: '$trimmedText' to '$targetLanguageCode'");
      
      final response = await _apiService.post('/translate', {
        'text': trimmedText,
        'target_language': targetLanguageCode,
      }, isProtected: false);

      final data = jsonDecode(response.body);
      debugPrint("🔍 [Flutter] Laravel Response Body: ${response.body}");
      
      final result = data['translated_text'];
      
      // Check if the result is identical to the input (often happens if target_lang == source_lang)
      if (result != null && result.trim() == trimmedText) {
        debugPrint("ℹ️ [Flutter] Translation result is identical to original. (Target was: $targetLanguageCode)");
      }
      
      return result ?? text;
    } catch (e) {
      debugPrint("❌ [Flutter] Translation Error: $e");
      return text;
    }
  }

  /// Detects the language of the given [text] via Laravel backend.
  Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'en';

    try {
      final response = await _apiService.post('/detect-language', {
        'text': text,
      }, isProtected: false);

      final data = jsonDecode(response.body);
      debugPrint("🔍 [Flutter] Language Detection Response: ${response.body}");
      
      return data['language'] ?? 'en';
    } catch (e) {
      debugPrint("❌ [Flutter] Detection Error: $e");
      return 'en';
    }
  }
}
