import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/intelligence/domain/ai_context_builder.dart';
import 'package:life_os/features/intelligence/providers/ai_notifier.dart';

// ---------------------------------------------------------------------------
// Chat Screen
// ---------------------------------------------------------------------------

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.notifier,
    required this.conversationId,
    required this.title,
    this.moduleSummary,
  });

  final AINotifier notifier;
  final int conversationId;
  final String title;

  /// Optional live context from LifeOS modules, used to build the
  /// AI system prompt. When null, no context is injected.
  final ModuleSummary? moduleSummary;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<String>? _streamSub;

  List<AiMessage> _messages = [];
  bool _isStreaming = false;
  String _streamBuffer = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    widget.notifier.onStateChanged = _onNotifierStateChanged;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    widget.notifier.onStateChanged = null;
    super.dispose();
  }

  void _onNotifierStateChanged(AIState state) {
    if (!mounted) return;
    setState(() {
      _messages = state.messages;
      _isStreaming = state.isStreaming;
      _streamBuffer = state.streamBuffer;
    });
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    final messages = await widget.notifier.dao
        .getMessagesForConversation(widget.conversationId);
    setState(() => _messages = messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isStreaming) return;
    _textController.clear();
    setState(() => _errorMessage = null);

    final stream = widget.notifier.sendMessage(
      widget.conversationId,
      text,
      context: widget.moduleSummary,
    );

    _streamSub?.cancel();
    _streamSub = stream.listen(
      (_) {},
      onError: (e) {
        setState(() => _errorMessage = 'Error al enviar el mensaje');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      key: const ValueKey('chat_screen'),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // Message list
          // -----------------------------------------------------------------
          Expanded(
            child: _messages.isEmpty && !_isStreaming
                ? Center(
                    child: Semantics(
                      label: 'Escribe tu primer mensaje',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hola! Soy tu asistente de LifeOS.',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Escribe tu primer mensaje.',
                            style:
                                TextStyle(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    key: const ValueKey('messages_list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount:
                        _messages.length + (_isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isStreaming && index == _messages.length) {
                        return _MessageBubble(
                          key: const ValueKey('streaming_bubble'),
                          role: 'assistant',
                          content: _streamBuffer,
                          isStreaming: true,
                          primaryColor: primaryColor,
                          theme: theme,
                        );
                      }
                      final msg = _messages[index];
                      return _MessageBubble(
                        key: ValueKey('message_${msg.id}'),
                        role: msg.role,
                        content: msg.content,
                        isStreaming: false,
                        primaryColor: primaryColor,
                        theme: theme,
                      );
                    },
                  ),
          ),

          // -----------------------------------------------------------------
          // Error message
          // -----------------------------------------------------------------
          if (_errorMessage != null)
            Semantics(
              label: _errorMessage,
              child: Container(
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),

          // -----------------------------------------------------------------
          // Input bar
          // -----------------------------------------------------------------
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Escribe tu mensaje',
                      child: TextField(
                        key: const ValueKey('message_input'),
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu mensaje...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Enviar mensaje',
                    button: true,
                    child: IconButton(
                      key: const ValueKey('send_button'),
                      onPressed: _isStreaming ? null : _send,
                      icon: _isStreaming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.send_rounded, color: primaryColor),
                      tooltip: 'Enviar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.role,
    required this.content,
    required this.isStreaming,
    required this.primaryColor,
    required this.theme,
  });

  final String role;
  final String content;
  final bool isStreaming;
  final Color primaryColor;
  final ThemeData theme;

  bool get _isUser => role == 'user';

  @override
  Widget build(BuildContext context) {
    final bubbleColor = _isUser
        ? primaryColor
        : theme.colorScheme.surfaceContainerHighest;
    final textColor =
        _isUser ? Colors.white : theme.colorScheme.onSurface;

    return Semantics(
      label: '${_isUser ? "Tu" : "Asistente"}: $content',
      child: Align(
        alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(_isUser ? 18 : 4),
              bottomRight: Radius.circular(_isUser ? 4 : 18),
            ),
          ),
          child: isStreaming
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        content,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _TypingIndicator(color: textColor),
                  ],
                )
              : Text(
                  content,
                  style: TextStyle(color: textColor),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator (animated dots)
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});

  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dots = ['.', '..', '...'][(_controller.value * 3).floor() % 3];
        return Text(dots, style: TextStyle(color: widget.color));
      },
    );
  }
}
