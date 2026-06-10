// ─────────────────────────────────────────────────────────────
//  screens/chat_screen.dart  (vendor)
//  Real-time chat screen connected to the Laravel API
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/chat_model.dart';
import 'package:sbrai_solutions/services/chat_service.dart';
import 'package:sbrai_solutions/vendor/widgets/message_bubble.dart';
import 'package:sbrai_solutions/vendor/widgets/chat_input_bar.dart';
import 'package:sbrai_solutions/screens/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final int currentUserId;
  final String otherPartyName;
  final String otherPartyInitial;
  final String adTitle;
  final int otherPartyId;
  final ChatService service;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherPartyName,
    required this.otherPartyInitial,
    required this.adTitle,
    required this.otherPartyId,
    required this.service,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _orange = Color(0xFFE85D22);

  final List<ChatMessageModel> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMore = false;
  bool _isStartingCall = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markRead();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _friendlyError(Object e) {
    return e
        .toString()
        .replaceFirst(RegExp(r'ChatApiException\(\d+\):\s*'), '')
        .trim();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _markRead() async {
    try {
      await widget.service.markRead(widget.chatId);
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await widget.service.getMessages(widget.chatId, page: 1);
      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(result.data.reversed);
          _currentPage = 1;
          _hasMore = result.hasMore;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await widget.service.getMessages(
        widget.chatId,
        page: _currentPage + 1,
      );
      if (mounted) {
        setState(() {
          _messages.insertAll(0, result.data.reversed);
          _currentPage++;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    final tempMsg = ChatMessageModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      body: text,
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      final sent = await widget.service.sendMessage(
        widget.chatId,
        message: text,
      );
      if (mounted) {
        final idx = _messages.indexWhere((m) => m.id == tempMsg.id);
        if (idx != -1) setState(() => _messages[idx] = sent);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == tempMsg.id));
        _showError('Failed to send message');
        _controller.text = text;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isSending = true);

    final tempMsg = ChatMessageModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      imagePath: picked.path,
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      final sent = await widget.service.sendMessage(
        widget.chatId,
        image: File(picked.path),
      );
      if (mounted) {
        final idx = _messages.indexWhere((m) => m.id == tempMsg.id);
        if (idx != -1) setState(() => _messages[idx] = sent);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == tempMsg.id));
        _showError('Failed to send image');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Call ───────────────────────────────────────────────────────────────────

  Future<int> _resolveUserId() async {
    if (widget.currentUserId != 0) return widget.currentUserId;
    try {
      final userData = await ApiService().getUserData();
      final id = int.tryParse(userData['id']?.toString() ?? '0') ?? 0;
      debugPrint('🔍 Resolved userId from cache: $id');
      return id;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _startCall(CallType callType) async {
    if (_isStartingCall) return;

    final uid = await _resolveUserId();
    if (uid == 0) {
      _showError('Could not identify user. Please log out and log in again.');
      return;
    }

    if (mounted) setState(() => _isStartingCall = true);

    final channelName =
        'chat_${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint(
      '📞 Starting ${callType.name} call — channel: $channelName, uid: $uid, receiver: ${widget.otherPartyId}',
    );

    try {
      // Fetch token
      final tokenResp = await widget.service.getCallToken(
        channelName: channelName,
        uid: uid,
      );

      debugPrint('✅ Token received successfully!');
      debugPrint('✅ Token length: ${tokenResp.token.length}');
      debugPrint(
        '✅ Token prefix: ${tokenResp.token.substring(0, tokenResp.token.length.clamp(0, 15))}...',
      );

      // Initiate call (non-fatal)
      try {
        await widget.service.initiateCall(
          receiverId: widget.otherPartyId,
          channelName: channelName,
          callerName: widget.otherPartyName,
          callType: callType,
        );
        debugPrint('✅ initiateCall sent successfully');
      } catch (e) {
        debugPrint('⚠️ initiateCall failed (non-fatal): $e');
      }

      if (!mounted) return;

      // Navigate to CallScreen with real token
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            session: CallSession(
              channelName: channelName,
              token: tokenResp.token, // ← This must now contain real token
              appId: tokenResp.appId,
              uid: uid,
              callType: callType,
              callerName: widget.otherPartyName,
              receiverId: widget.otherPartyId,
            ),
            service: widget.service,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ _startCall error: $e');
      debugPrint('❌ stack: $stack');
      if (mounted) {
        _showError(
          e is ChatApiException
              ? e.message
              : 'Could not start call. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingCall = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
          ? _buildError()
          : Column(
              children: [
                if (widget.adTitle.isNotEmpty) _buildAdBar(),
                if (_isLoadingMore)
                  const LinearProgressIndicator(color: _orange, minHeight: 2),
                Expanded(child: _buildMessageList()),
                ChatInputBar(
                  controller: _controller,
                  onSendText: _sendText,
                  onPickImage: _sendImage,
                  isSending: _isSending,
                ),
              ],
            ),
    );
  }

  // ... (All your other methods remain unchanged: _buildAppBar, _buildAdBar, _buildMessageList, _buildError)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF5F5F5),
            child: Text(
              widget.otherPartyInitial,
              style: const TextStyle(
                color: _orange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.otherPartyName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.adTitle.isNotEmpty)
                  Text(
                    widget.adTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.phone_outlined,
            color: _isStartingCall ? Colors.grey.shade400 : Colors.black,
          ),
          tooltip: 'Voice call',
          onPressed: _isStartingCall ? null : () => _startCall(CallType.audio),
        ),
        IconButton(
          icon: Icon(
            Icons.videocam_outlined,
            color: _isStartingCall ? Colors.grey.shade400 : Colors.black,
          ),
          tooltip: 'Video call',
          onPressed: _isStartingCall ? null : () => _startCall(CallType.video),
        ),
        if (_isStartingCall)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _orange,
                ),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
      ],
    );
  }

  Widget _buildAdBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey.shade50,
      width: double.infinity,
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Product: ${widget.adTitle}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
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
            Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Say hello to start the conversation!',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == widget.currentUserId;
        return MessageBubble(message: msg, isMe: isMe);
      },
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
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
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
}
