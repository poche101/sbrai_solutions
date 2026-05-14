// ─────────────────────────────────────────────────────────────
//  screens/chat_list_screen.dart
//  Shows all chat threads for the logged-in user
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/chat_model.dart';
import '../services/chat_service.dart';
import 'package:sbrai_solutions/vendor/screen/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  /// Pass your auth token and current user ID here
  final String authToken;
  final int currentUserId;
  final bool isVendor;

  const ChatListScreen({
    super.key,
    required this.authToken,
    required this.currentUserId,
    required this.isVendor,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const _orange = Color(0xFFE85D22);

  late final ChatService _service;
  final List<ChatThread> _threads = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _service = ChatService(widget.authToken);
    _loadChats();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getChats(page: 1);
      setState(() {
        _threads
          ..clear()
          ..addAll(result.data);
        _currentPage = 1;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final result = await _service.getChats(page: _currentPage + 1);
      setState(() {
        _threads.addAll(result.data);
        _currentPage++;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _otherPartyName(ChatThread t) {
    if (widget.isVendor) {
      return t.buyer?.name ?? 'Buyer';
    }
    return t.vendor?.displayName ?? 'Vendor';
  }

  String _otherPartyInitial(ChatThread t) {
    if (widget.isVendor) {
      return t.buyer?.initial ?? '?';
    }
    return t.vendor?.initial ?? '?';
  }

  bool _isUnread(ChatThread t) {
    if (widget.isVendor) return !t.vendorRead;
    return !t.buyerRead;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
          ? _buildError()
          : _threads.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              color: _orange,
              onRefresh: _loadChats,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _threads.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _threads.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(color: _orange),
                      ),
                    );
                  }
                  return _buildThreadTile(_threads[index]);
                },
              ),
            ),
    );
  }

  Widget _buildThreadTile(ChatThread thread) {
    final name = _otherPartyName(thread);
    final initial = _otherPartyInitial(thread);
    final unread = _isUnread(thread);
    final lastMsg =
        thread.latestMessage?.body ??
        (thread.latestMessage?.imagePath != null ? '📷 Image' : '');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: thread.id,
            authToken: widget.authToken,
            currentUserId: widget.currentUserId,
            otherPartyName: name,
            otherPartyInitial: initial,
            adTitle: thread.ad?.title ?? '',
            otherPartyId: widget.isVendor ? thread.buyerId : thread.vendorId,
            service: _service,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          color: unread ? const Color(0xFFFFF4F0) : Colors.white,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: unread ? _orange : Colors.grey.shade200,
              child: Text(
                initial,
                style: TextStyle(
                  color: unread ? Colors.white : const Color(0xFFE85D22),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(thread.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: unread ? _orange : Colors.grey,
                          fontWeight: unread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (thread.ad != null)
                    Text(
                      thread.ad!.title,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          style: TextStyle(
                            fontSize: 13,
                            color: unread
                                ? Colors.black87
                                : Colors.grey.shade500,
                            fontWeight: unread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: _orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadChats,
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation by messaging a vendor',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
