import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/settings_service.dart';

// ─── نموذج رسالة الدردشة ─────────────────────────────────────────────────────────
// يمثل رسالة واحدة سواء من المستخدم أو من مساعد الذكاء الاصطناعي.
class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

// ─── شاشة الدردشة الرئيسية ──────────────────────────────────────────────────────
// تعرض المحادثة أمام المستخدم وتدير إرسال واستقبال الرسائل.
class ChatScreen extends StatefulWidget {
  final String? initialTopic;

  const ChatScreen({super.key, this.initialTopic});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  
  @override
  bool get wantKeepAlive => true;
  
  late List<Message> _messages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final isArabic = _settings.locale.languageCode == 'ar';
    _messages = [
      Message(
        text: isArabic 
          ? "مرحباً! أنا مساعد LearnMate الذكي. كيف يمكنني مساعدتك في الدراسة اليوم؟" 
          : "Hello! I am LearnMate AI. How can I help you study today?", 
        isUser: false
      ),
    ];

    if (widget.initialTopic != null && widget.initialTopic!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialTopic!;
        _sendMessage();
      });
    }
  }

  // ─── إرسال رسالة المستخدم إلى الخدمة ──────────────────────────────────────────
  // تضيف الرسالة إلى واجهة المستخدم ثم تطلب رد الذكاء الاصطناعي من GroqService.
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    final response = await _groqService.sendMessage(text);

    setState(() {
      _messages.add(Message(text: response, isUser: false));
      _isLoading = false;
    });
    
    _scrollToBottom();
  }

  // ─── التمرير التلقائي إلى أسفل المحادثة ──────────────────────────────────────
  // هذا يحافظ على ظهور آخر رسالة في الشاشة بعد الإضافة.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            elevation: 0,
            title: Text(
              isArabic ? 'دردشة LearnMate' : 'LearnMate Chat', 
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg, isDark);
                  },
                ),
              ),
              if (_isLoading) _buildTypingIndicator(isDark, isArabic),
              _buildMessageInput(isDark, isArabic),
            ],
          ),
        );
      }
    );
  }

  // ─── بناء فقاعة الرسالة ─────────────────────────────────────────────────────────
  // تعرض الرسائل بشكل مختلف للمستخدم والمساعد داخل واجهة المحادثة.
  Widget _buildMessageBubble(Message message, bool isDark) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser 
            ? AppColors.primary 
            : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: !message.isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, bool isArabic) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 5)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'LearnMate يفكر...' : 'LearnMate is thinking...',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: isArabic ? 'اسأل LearnMate أي شيء...' : 'Ask LearnMate anything...',
                  hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
