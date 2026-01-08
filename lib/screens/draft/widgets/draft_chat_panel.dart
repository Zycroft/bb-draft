import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/socket_service.dart';

/// Real-time chat panel for the draft room.
class DraftChatPanel extends StatefulWidget {
  final String draftId;

  const DraftChatPanel({
    super.key,
    required this.draftId,
  });

  @override
  State<DraftChatPanel> createState() => _DraftChatPanelState();
}

class _DraftChatPanelState extends State<DraftChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessageItem> _messages = [];
  StreamSubscription<ChatMessage>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Add welcome message
    _messages.add(_ChatMessageItem(
      id: 'system-welcome',
      userId: 'system',
      message: 'Welcome to the draft room! Good luck!',
      timestamp: DateTime.now(),
      isSystem: true,
    ));

    // Listen for chat messages
    // Note: In a real implementation, you'd get this from the DraftProvider
    // or inject a SocketService
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add message locally (optimistic update)
    setState(() {
      _messages.add(_ChatMessageItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'me',
        message: message,
        timestamp: DateTime.now(),
        isSystem: false,
        isMe: true,
      ));
    });

    // Scroll to bottom
    _scrollToBottom();

    // Clear input
    _messageController.clear();

    // In a real implementation, send via socket
    // _socketService.sendChatMessage(widget.draftId, message);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addPickNotification(String teamName, String playerName, String position) {
    setState(() {
      _messages.add(_ChatMessageItem(
        id: 'pick-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'system',
        message: '$teamName drafted $playerName ($position)',
        timestamp: DateTime.now(),
        isSystem: true,
        isPickNotification: true,
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.chat, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Draft Room Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              // Connected users indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _ChatMessageBubble(message: message);
                  },
                ),
        ),
        // Quick actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey[100],
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChatChip(
                  label: 'Nice pick!',
                  onTap: () {
                    _messageController.text = 'Nice pick!';
                    _sendMessage();
                  },
                ),
                const SizedBox(width: 8),
                _QuickChatChip(
                  label: 'Good luck!',
                  onTap: () {
                    _messageController.text = 'Good luck everyone!';
                    _sendMessage();
                  },
                ),
                const SizedBox(width: 8),
                _QuickChatChip(
                  label: 'My turn?',
                  onTap: () {
                    _messageController.text = 'Is it my turn?';
                    _sendMessage();
                  },
                ),
                const SizedBox(width: 8),
                _QuickChatChip(
                  label: 'brb',
                  onTap: () {
                    _messageController.text = 'brb, auto-pick is on';
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ),
        // Message input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
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
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: Icon(Icons.send, color: Colors.green[700]),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green[50],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Start the conversation!',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageItem {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final bool isSystem;
  final bool isMe;
  final bool isPickNotification;

  _ChatMessageItem({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.isSystem = false,
    this.isMe = false,
    this.isPickNotification = false,
  });
}

class _ChatMessageBubble extends StatelessWidget {
  final _ChatMessageItem message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.userId.isNotEmpty ? message.userId[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.userId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (message.isPickNotification)
            Icon(
              Icons.sports_baseball,
              size: 14,
              color: Colors.green[600],
            ),
          const SizedBox(width: 4),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: message.isPickNotification
                    ? Colors.green[50]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 12,
                  color: message.isPickNotification
                      ? Colors.green[700]
                      : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChatChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChatChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
      ),
    );
  }
}
