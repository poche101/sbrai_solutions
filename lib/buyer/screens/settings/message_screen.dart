import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/message_model.dart';
import 'package:sbrai_solutions/buyer/screens/settings/chat_screen.dart';

class MessageScreen extends StatefulWidget {
  // Pass the list of messages into the screen to make it fully dynamic
  final List<MessageModel> initialMessages;

  const MessageScreen({super.key, this.initialMessages = const []});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late List<MessageModel> _allMessages;
  List<MessageModel> _filteredMessages = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with data passed from the parent or an API
    _allMessages = widget.initialMessages;
    _filteredMessages = _allMessages;
  }

  void _filterMessages(String query) {
    setState(() {
      _filteredMessages = _allMessages
          .where(
            (m) =>
                m.senderName.toLowerCase().contains(query.toLowerCase()) ||
                (m.subTitle?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    });
  }

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
            child: _filteredMessages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredMessages.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      return _buildMessageCard(_filteredMessages[index]);
                    },
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
    return const Center(
      child: Text(
        "No conversations found",
        style: TextStyle(color: Colors.grey),
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
              builder: (context) => ChatScreen(
                userName: message.senderName,
                userInitial: message.senderName.isNotEmpty
                    ? message.senderName[0]
                    : '?',
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
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: message.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(message.imageUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: message.isVendor
                  ? Icon(Icons.image_outlined, color: Colors.grey.shade400)
                  : CircleAvatar(
                      backgroundColor: Colors.blueGrey.shade50,
                      child: Text(
                        message.senderName.isNotEmpty
                            ? message.senderName[0]
                            : '',
                        style: TextStyle(color: Colors.orange.shade300),
                      ),
                    ),
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
