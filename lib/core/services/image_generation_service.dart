import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import 'groq_service.dart';

class ImageGenerationService {
  static const String _falSdxlUrl = 'https://fal.run/fal-ai/fast-sdxl';
  static final GroqService _groqService = GroqService();

  /// Generate educational illustrations using FAL AI with Pixabay fallback
  static Future<List<String>> generateIllustrations(String prompt) async {
    try {
      debugPrint('Generating illustrations for: $prompt');
      
      final int seed = DateTime.now().millisecondsSinceEpoch % 1000000;
      final response = await http.post(
        Uri.parse(_falSdxlUrl),
        headers: {
          'Authorization': 'Key ${ApiConstants.falApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "prompt": "Professional educational illustration, $prompt, clean minimalist design, high quality, 4k, academic style, white background",
          "negative_prompt": "text, watermark, messy, blurry, low resolution, ugly",
          "seed": seed,
          "sync_mode": true
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['images'] != null && data['images'].isNotEmpty) {
          List<String> urls = [];
          for (var img in data['images']) {
            urls.add(img['url']);
          }
          if (urls.isNotEmpty) return urls;
        }
      }
      
      debugPrint('FAL AI Illustration failed (${response.statusCode}): ${response.body}');
      
      // Fallback to Pixabay if FAL AI fails (e.g. exhausted balance)
      return await _fetchFromPixabayMultiple(prompt);
    } catch (e) {
      debugPrint('Error generating illustration: $e');
      return await _fetchFromPixabayMultiple(prompt);
    }
  }

  /// Fallback: Fetch relevant high-quality images from Pixabay
  static Future<List<String>> _fetchFromPixabayMultiple(String query) async {
    try {
      // 1. Get English keywords via Groq to ensure Pixabay finds relevant images
      debugPrint('Translating query for Pixabay: $query');
      final String englishQuery = await _groqService.generateImageSearchQuery(query);
      debugPrint('Pixabay English Query: $englishQuery');

      final String encodedQuery = Uri.encodeComponent(englishQuery);
      final String url = 'https://pixabay.com/api/?key=${ApiConstants.pixabayApiKey}&q=$encodedQuery&image_type=illustration&per_page=5&safesearch=true';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<String> urls = [];
        if (data['totalHits'] > 0) {
          for (var hit in data['hits']) {
            urls.add(hit['largeImageURL']);
          }
          return urls;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Pixabay Fallback Error: $e');
      return [];
    }
  }
}
