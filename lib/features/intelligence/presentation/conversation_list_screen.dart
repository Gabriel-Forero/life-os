import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/intelligence/presentation/chat_screen.dart';

// ---------------------------------------------------------------------------
// Conversation List Screen
// ---------------------------------------------------------------------------

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(aiNotifierProvider);
    final theme = Theme.of(context);

    void openConversation(AiConversation conversation) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            title: conversation.title,
          ),
        ),
      );
    }

    Future<void> newConversation() async {
      final result = await notifier.createConversation(title: 'Nueva conversacion');
      result.when(
        success: (conversationId) {
          final conv = notifier.state.conversations
              .where((c) => c.id == conversationId)
              .firstOrNull;
          if (conv != null && context.mounted) {
            openConversation(conv);
          }
        },
        failure: (_) {},
      );
    }

    return Scaffold(
      key: const ValueKey('conversation_list_screen'),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('new_conversation_button'),
        onPressed: newConversation,
        tooltip: 'Nueva conversacion',
        child: const Icon(Icons.add_comment_outlined),
      ),
      body: StreamBuilder<List<AiConversation>>(
        stream: notifier.dao.watchAllConversations(),
        initialData: notifier.state.conversations,
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Semantics(
                label: 'Sin conversaciones. Inicia una nueva.',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin conversaciones',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia una nueva conversacion con tu asistente.',
                      style: TextStyle(color: theme.colorScheme.outline),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const ValueKey('empty_new_conversation_button'),
                      onPressed: newConversation,
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva conversacion'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            key: const ValueKey('conversations_list'),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _ConversationTile(
                key: ValueKey('conversation_tile_${conv.id}'),
                conversation: conv,
                theme: theme,
                onTap: () => openConversation(conv),
                onDelete: () => notifier.deleteConversation(conv.id),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation tile
// ---------------------------------------------------------------------------

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  final AiConversation conversation;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Conversacion: ${conversation.title}',
      button: true,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.smart_toy_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatDate(conversation.updatedAt)),
        trailing: Semantics(
          label: 'Eliminar conversacion',
          button: true,
          child: IconButton(
            key: ValueKey('delete_conversation_${conversation.id}'),
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
