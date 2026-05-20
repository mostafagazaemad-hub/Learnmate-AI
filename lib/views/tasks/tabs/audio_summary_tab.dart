import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/settings_service.dart';

class AudioSummaryTab extends StatefulWidget {
  final String topic;
  final Function(String)? onGenerated;
  final String? initialData;

  const AudioSummaryTab({
    super.key,
    required this.topic,
    this.onGenerated,
    this.initialData,
  });

  @override
  State<AudioSummaryTab> createState() => _AudioSummaryTabState();
}

class _AudioSummaryTabState extends State<AudioSummaryTab> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final FlutterTts _flutterTts = FlutterTts();
  final SettingsService _settings = SettingsService();
  final TextEditingController _customTopicController = TextEditingController();
  
  String? _script;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  
  // Progress tracking for Resume
  int _currentWordStart = 0;
  String _remainingText = "";

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.initialData != null) {
      _script = widget.initialData;
      _remainingText = _script ?? "";
    }
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _currentWordStart = 0;
          _remainingText = _script ?? "";
        });
      }
    });

    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (mounted && _isPlaying) {
        _currentWordStart = start;
        _remainingText = text.substring(start);
      }
    });
    
    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _customTopicController.dispose();
    super.dispose();
  }

  Future<void> _generateScript() async {
    setState(() => _isLoading = true);
    try {
      final targetTopic = _customTopicController.text.trim().isNotEmpty 
          ? _customTopicController.text.trim() 
          : widget.topic;

      final result = await _groqService.generatePodcastScript(targetTopic);
      
      setState(() {
        _script = result;
        _remainingText = result;
        _currentWordStart = 0;
        _isLoading = false;
      });
      
      if (widget.onGenerated != null) {
        widget.onGenerated!(result);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating podcast: $e')),
        );
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_script == null) return;

    if (_isPlaying) {
      if (_isPaused) {
        setState(() => _isPaused = false);
        await _flutterTts.speak(_remainingText); 
      } else {
        await _flutterTts.stop(); 
        setState(() {
          _isPaused = true;
        });
      }
    } else {
      setState(() {
        _isPlaying = true;
        _isPaused = false;
        _remainingText = _script!;
      });
      
      // Clean script for a smooth TTS experience
      String cleanText = _script!
          .replaceAll(RegExp(r'(Alex:|Sarah:)'), '') // Remove names
          .replaceAll(RegExp(r'[\*#_>]'), '')        // Remove Markdown symbols
          .replaceAll(RegExp(r'\[.*?\]'), '')       // Remove text in brackets [like this]
          .replaceAll(RegExp(r'\(.*?\)'), '')       // Remove text in parentheses (like this)
          .replaceAll(RegExp(r'\s+'), ' ')          // Normalize whitespace
          .trim();
          
      await _flutterTts.speak(cleanText);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        if (_script == null && !_isLoading) {
          return _buildGenerateState(isDark, isArabic);
        }

        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(isArabic ? 'جاري توليد النص الصوتي...' : 'Generating Audio Script...', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlayerCard(isArabic),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'النص الصوتي' : 'Audio Script',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
                  ),
                  IconButton(
                    onPressed: () {
                      _flutterTts.stop();
                      setState(() {
                        _script = null;
                        _isPlaying = false;
                      });
                      _customTopicController.clear();
                    },
                    icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                    tooltip: isArabic ? 'تغيير الموضوع' : 'Change Topic',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildScriptContainer(isDark),
              const SizedBox(height: 40),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPlayerCard(bool isArabic) {
    String status = '';
    if (_isPlaying) {
      status = _isPaused 
          ? (isArabic ? 'متوقف مؤقتاً' : 'Paused') 
          : (isArabic ? 'جاري التشغيل...' : 'Playing...');
    } else {
      status = isArabic ? 'جاهز للتشغيل' : 'Ready to play';
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5DD3), Color(0xFF8E81F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C5DD3).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'استمع إلى ملخص الموضوع' : 'Listen to Audio Summary',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _playerButton(Icons.replay_rounded, () async {
                await _flutterTts.stop();
                setState(() {
                   _isPlaying = false;
                   _isPaused = false;
                   _remainingText = _script!;
                });
                _toggleAudio();
              }),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: _toggleAudio,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(
                    _isPlaying && !_isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 48,
                    color: const Color(0xFF6C5DD3),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _playerButton(Icons.stop_rounded, () async {
                await _flutterTts.stop();
                setState(() {
                  _isPlaying = false;
                  _isPaused = false;
                  _remainingText = _script!;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 32),
    );
  }

  Widget _buildScriptContainer(bool isDark) {
    if (_script == null) return const SizedBox.shrink();

    final lines = _script!.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Column(
      children: lines.map((line) {
        final isAlex = line.startsWith('Alex:');
        final isSarah = line.startsWith('Sarah:');
        final cleanLine = line.replaceFirst(RegExp(r'^(Alex:|Sarah:)\s*'), '');

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Align(
            alignment: isAlex ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: isAlex 
                    ? (isDark ? const Color(0xFF1E293B) : Colors.blue.shade50)
                    : (isDark ? const Color(0xFF334155) : Colors.purple.shade50),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isAlex ? Radius.zero : const Radius.circular(20),
                  bottomRight: isSarah ? Radius.zero : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isAlex ? Colors.blue.withOpacity(0.3) : Colors.purple.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAlex ? 'Alex 🎙️' : 'Sarah 🎓',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isAlex ? Colors.blue : Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cleanLine,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenerateState(bool isDark, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.mic_rounded, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            isArabic ? 'ملخص صوتي مخصص' : 'Custom Audio Summary', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'حول أي موضوع دراسي إلى ملخص صوتي جذاب بأسلوب البودكاست.' : 'Convert any study topic into an engaging podcast-style audio summary.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _customTopicController,
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: isArabic ? 'الموضوع (اختياري)' : 'Topic (Optional)',
              labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              hintText: isArabic ? 'مثال: اشرح أساسيات بايثون ببساطة...' : 'e.g. Explain Python basics simply...',
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300)),
              prefixIcon: const Icon(Icons.subject_rounded, color: AppColors.primary),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generateScript,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(isArabic ? 'توليد الصوت' : 'Generate Audio', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}
