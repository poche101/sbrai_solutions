import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/message_model.dart';
import 'package:sbrai_solutions/models/chat_model.dart';
import 'package:sbrai_solutions/screens/chat_screen.dart';
import 'package:sbrai_solutions/services/chat_service.dart';

class MessageScreen extends StatefulWidget {
  final int currentUserId;
  final bool isVendor;

  const MessageScreen({
    super.key,
    required this.currentUserId,
    required this.isVendor,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late final ChatService _service;

  List<MessageModel> _allMessages = [];
  List<MessageModel> _filteredMessages = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ChatService(currentUserId: widget.currentUserId);
    _loadThreads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<ChatThread> allThreads = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore && page <= 5) {
        final result = await _service.getChats(page: page);
        allThreads.addAll(result.data);
        hasMore = result.hasMore;
        page++;
      }

      if (mounted) {
        final messages = allThreads
            .map(
              (thread) => MessageModel.fromChatThread(
                thread,
                currentUserId: widget.currentUserId,
                isVendor: widget.isVendor,
              ),
            )
            .toList();
        setState(() {
          _allMessages = messages;
          _filteredMessages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e
              .toString()
              .replaceFirst(RegExp(r'ChatApiException\(\d+\):\s*'), '')
              .trim();
          _isLoading = false;
        });
      }
    }
  }

  void _filterMessages(String query) {
    setState(() {
      _filteredMessages = query.isEmpty
          ? _allMessages
          : _allMessages
                .where(
                  (m) =>
                      m.senderName.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (m.subTitle?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false),
                )
                .toList();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF7043)),
                  )
                : _error != null
                ? _buildError()
                : _filteredMessages.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFFFF7043),
                    onRefresh: _loadThreads,
                    child: ListView.builder(
                      itemCount: _filteredMessages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) =>
                          _buildMessageCard(_filteredMessages[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Messages',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black54),
          onPressed: _loadThreads,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _filterMessages,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'No conversations yet',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Messages will appear here',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load messages',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadThreads,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: message.thread.id,
                currentUserId: widget.currentUserId,
                otherPartyName: message.senderName,
                otherPartyInitial: message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                adTitle: message.subTitle ?? message.thread.adTitle ?? '',
                otherPartyId: message.thread.otherParticipant?.id ?? 0,
                service: _service,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(message),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(message),
                    if (message.subTitle != null) _buildSubtitle(message),
                    const SizedBox(height: 4),
                    _buildBottomRow(message),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(MessageModel message) {
    String? finalUrl = message.imageUrl;

    // 🚀 If path is relative, prefix it with your live storage domain location
    if (finalUrl != null && !finalUrl.startsWith('http')) {
      finalUrl = 'https://sbraisolutions.com/storage/$finalUrl';
    }

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: finalUrl != null && finalUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                finalUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                ),
              ),
            )
          : Center(
              child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
            ),
    );
  }

  Widget _buildTopRow(MessageModel message) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  message.senderName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (message.isVendor) ...[
                const SizedBox(width: 6),
                _buildVendorBadge(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          message.time,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildVendorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Vendor',
        style: TextStyle(color: Colors.white, fontSize: 9),
      ),
    );
  }

  Widget _buildSubtitle(MessageModel message) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        message.subTitle!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _buildBottomRow(MessageModel message) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: message.unreadCount > 0 ? Colors.black87 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        if (message.unreadCount > 0)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFF7043),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${message.unreadCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
