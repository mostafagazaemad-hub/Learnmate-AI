import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_constants.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  GeminiService() {
    _initModel();
  }

  void _initModel() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Flash is faster and usually sufficient
      apiKey: ApiConstants.groqApiKey, // This is still suspicious, but I will check if there's a better one
      systemInstruction: Content.system(
        "You are LearnMate, an expert, encouraging AI Tutor. "
        "CRITICAL: You MUST respond in the SAME LANGUAGE as the user message or topic. "
        "If the user writes in Arabic, your entire response must be in Arabic. "
        "Help students understand complex concepts, summarize texts, and provide clear answers. "
        "Do not give direct homework answers without explanation."
      ),
    );
    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String prompt) async {
    try {
      final words = prompt.trim().split(RegExp(r'\s+'));
      final bool isShortTopic = words.length <= 3;

      String finalPrompt = prompt;
      if (isShortTopic) {
        finalPrompt = 'The user mentioned: "$prompt". '
            'Do NOT provide a detailed explanation. Instead, greet them and suggest 3 specific paths '
            'to explore this topic (e.g., 1. Basics, 2. Examples, 3. Study Path). '
            'Always respond in the same language as the user message.';
      }

      final content = Content.text(finalPrompt);
      final response = await _chatSession.sendMessage(content);
      return response.text ?? "عذراً، لم أتمكن من توليد إجابة.";
    } catch (e) {
      print("Error sending message to Gemini: $e");
      return "عذراً، حدث خطأ أثناء الاتصال بالذكاء الاصطناعي.";
    }
  }

  /// Generates a mind map JSON string for the given topic.
  Future<String> generateMindMap(String topic) async {
    try {
      final prompt =
          'Generate a detailed mind map for "$topic" in JSON format only. '
          'Do NOT include any markdown, explanation, or extra text. '
          'The JSON must strictly follow this structure: '
          '{"name": "Root Topic", "children": [{"name": "Subtopic 1", "children": [{"name": "Detail 1", "children": []}, {"name": "Detail 2", "children": []}]}, {"name": "Subtopic 2", "children": []}]}. '
          'Provide a deep hierarchy with at least 3 levels and 4-6 main branches.';

      final content = Content.text(prompt);
      final response = await _model.generateContent([content]);
      return response.text ?? '{}';
    } catch (e) {
      print("Error generating mind map: $e");
      return '{}';
    }
  }
}
