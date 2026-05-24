/// API Constants for LearnMate AI Application
/// Contains all API keys and endpoint configurations
/// 
/// NOTE: API keys should be stored in environment variables or .env files,
/// not hardcoded in source files for security reasons.
class ApiConstants {
  // === API Endpoints ===
  static const String groqApiBaseUrl = 'https://api.groq.com/openai/v1';
  static const String pixabayApiUrl = 'https://pixabay.com/api';
  static const String youtubeApiUrl = 'https://www.googleapis.com/youtube/v3';

  // === API Keys (Use environment variables in production) ===
  // Replace these placeholders with actual keys from environment variables
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String falApiKey = 'YOUR_FAL_API_KEY_HERE';
  static const String pixabayApiKey = 'YOUR_PIXABAY_API_KEY_HERE';
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY_HERE';
  static const String hfToken = 'YOUR_HUGGINGFACE_TOKEN_HERE';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // === API Configuration ===
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // milliseconds
}
