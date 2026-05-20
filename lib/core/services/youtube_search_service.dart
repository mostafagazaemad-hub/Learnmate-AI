import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';

class YouTubeSearchService {
  /// Searches YouTube and returns the 11-character Video ID
  /// [index] allows fetching a different result (e.g. 0 for top, 1 for next)
  static Future<String?> fetchVideoId(String searchQuery, {int index = 0}) async {
    if (ApiConstants.youtubeApiKey == 'YOUR_YOUTUBE_API_KEY' || ApiConstants.youtubeApiKey.isEmpty) {
      debugPrint('YouTube API Key not set. Falling back.');
      return null;
    }

    try {
      final String encodedQuery = Uri.encodeComponent(searchQuery);
      
      // build the correct search URL:
      // maxResults=10: to have a pool of videos to choose from
      final String url = 'https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=10&q=$encodedQuery&type=video&key=${ApiConstants.youtubeApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['items'] != null && data['items'].isNotEmpty) {
          // Wrap index to stay within bounds
          final actualIndex = index % (data['items'] as List).length;
          final String videoId = data['items'][actualIndex]['id']['videoId'];
          debugPrint('Successfully found video ID at index $actualIndex: $videoId');
          return videoId;
        } else {
          debugPrint('No videos found.');
          return null;
        }
      } else {
        debugPrint('YouTube API Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Connection error in YouTube API: $e');
      return null;
    }
  }
}
