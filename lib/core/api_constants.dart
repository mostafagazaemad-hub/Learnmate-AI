/// API Constants for LearnMate AI Application
/// Contains all API keys and endpoint configurations
/// 
/// NOTE: API keys are now retrieved from environment variables
/// for better security in production.
class ApiConstants {
  // === API Endpoints ===
  static const String groqApiBaseUrl = 'https://api.groq.com/openai/v1';
  static const String pixabayApiUrl = 'https://pixabay.com/api';
  static const String youtubeApiUrl = 'https://www.googleapis.com/youtube/v3';

  // === API Keys (Retrieved from environment variables) ===
  // Pass these during build using --dart-define=KEY_NAME=value
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String falApiKey = String.fromEnvironment('FAL_API_KEY');
  static const String pixabayApiKey = String.fromEnvironment('PIXABAY_API_KEY');
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
  static const String hfToken = String.fromEnvironment('HF_TOKEN');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  // === API Configuration ===
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // milliseconds
}
