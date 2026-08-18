import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class DriverChatScreen extends StatefulWidget {
  final String currentUserId;
  final String userName;

  const DriverChatScreen({
    super.key,
    required this.currentUserId,
    required this.userName,
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final messages = await _api.fetchChatMessages();
      if (!mounted) return;
      setState(() {
        _messages.addAll(messages);
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _poll() async {
    if (_messages.isEmpty) return;

    try {
      final newMessages =
          await _api.fetchChatMessages(sinceId: _messages.last.id);

      if (newMessages.isEmpty || !mounted) return;

      setState(() => _messages.addAll(newMessages));
      _scrollToBottom();
    } catch (_) {
      // Quiet failure - just try again on the next tick.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputController.clear();

    try {
      await _api.sendChatMessage(
        senderUserId: widget.currentUserId,
        senderName: widget.userName,
        body: text,
      );
      await _poll();
    } catch (_) {
      // Put the text back so nothing typed is lost.
      _inputController.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(color: AppColors.yellow),
        title: const Text(
          'Driver Chat',
          style: TextStyle(color: AppColors.yellow),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.yellow,
                      ),
                    )
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Nobody\'s said anything yet.',
                            style: TextStyle(color: AppColors.yellow),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe =
                                message.senderUserId == widget.currentUserId;
                            return _MessageBubble(
                              message: message,
                              isMe: isMe,
                              timeLabel: _timeLabel(message.createdAt),
                            );
                          },
                        ),
            ),
            _buildInputRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.mainLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: AppColors.yellow),
              cursorColor: AppColors.yellow,
              maxLength: 2000,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Say something...',
                hintStyle: TextStyle(color: AppColors.mainLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.yellow,
                    ),
                  )
                : const Icon(Icons.send, color: AppColors.yellow),
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String timeLabel;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.mainLight : AppColors.main,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              message.body,
              style: const TextStyle(color: AppColors.yellow),
            ),
            const SizedBox(height: 2),
            Text(
              timeLabel,
              style: const TextStyle(
                color: AppColors.mainLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
