import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import 'groq_service.dart';
import 'youtube_search_service.dart';

class VideoService {
  /// Primary method: Find a high-quality educational video
  static Future<String?> generateVideo(String topic, {int index = 0}) async {
    try {
      debugPrint('Finding educational video for: $topic (Index: $index)');
      final groq = GroqService();
      
      // 1. Translate topic to English to get better and more accurate YouTube search results
      // (Optimization: If it's already optimized/translated, we could skip, but let's keep it simple)
      final englishTopic = await groq.translateToEnglish(topic);
      debugPrint('Translated Video Topic: $englishTopic');

      // 2. Try to get a specific Video ID using YouTube Data API
      // If the topic already contains "شرح" or similar, we use it directly or clean it.
      final String searchQuery = topic.contains('شرح') ? topic : '$englishTopic educational lesson explanation';
      final String? videoId = await YouTubeSearchService.fetchVideoId(searchQuery, index: index);

      if (videoId != null) {
        // Return direct embed for the specific video
        return 'https://www.youtube.com/embed/$videoId?rel=0&autoplay=1';
      }

      // 3. Fallback: Use YouTube search embed
      final encodedTopic = Uri.encodeComponent(searchQuery);
      return 'https://www.youtube.com/embed?listType=search&list=$encodedTopic&rel=0';
    } catch (e) {
      debugPrint('Error in video generation: $e');
      return await fetchVideo(topic);
    }
  }

  /// Fallback method: Search for a ready-made video on Pixabay
  static Future<String?> fetchVideo(String topic) async {
    try {
      final groq = GroqService();
      // Use English translation for Pixabay to ensure we get actual related results, not generic fallbacks
      final englishQuery = await groq.translateToEnglish(topic);
      debugPrint('Pixabay Video English Query: $englishQuery');

      final String encodedQuery = Uri.encodeComponent(englishQuery);
      final String url = 'https://pixabay.com/api/videos/?key=${ApiConstants.pixabayApiKey}&q=$encodedQuery&per_page=5&safesearch=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['totalHits'] > 0) {
          final hit = data['hits'][0];
          final videos = hit['videos'];
          
          // Selection order: large -> medium -> small -> tiny
          String? bestUrl = videos['large']?['url'] ?? 
                            videos['medium']?['url'] ?? 
                            videos['small']?['url'] ?? 
                            videos['tiny']?['url'];
          
          if (bestUrl != null) return bestUrl;
        }
      }
      
      // Secondary Fallback: Generic educational video
      final fallbackResponse = await http.get(
        Uri.parse('https://pixabay.com/api/videos/?key=${ApiConstants.pixabayApiKey}&q=education&per_page=3&safesearch=true')
      );
      
      if (fallbackResponse.statusCode == 200) {
        final Map<String, dynamic> fallbackData = jsonDecode(fallbackResponse.body);
        if (fallbackData['totalHits'] > 0) {
          final hit = fallbackData['hits'][0];
          return hit['videos']['medium']?['url'] ?? hit['videos']['small']?['url'];
        }
      }

      return null;
    } catch (e) {
      debugPrint('Pixabay Error: $e');
      return null;
    }
  }
}
