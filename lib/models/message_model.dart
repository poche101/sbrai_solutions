import 'package:sbrai_solutions/models/chat_model.dart';

class MessageModel {
  final String senderName;
  final String? subTitle;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String? imageUrl;
  final bool isVendor;
  final ChatThread thread;

  MessageModel({
    required this.senderName,
    this.subTitle,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.imageUrl,
    this.isVendor = false,
    required this.thread,
  });

  /// Factory constructor to create MessageModel from ChatThread
  /// This properly handles both Buyer and Vendor perspectives
  factory MessageModel.fromChatThread(
    ChatThread thread, {
    required int currentUserId,
    required bool isVendor,
  }) {
    final otherParticipant = thread.otherParticipantFor(
      currentUserId: currentUserId,
      isVendor: isVendor,
    );

    // 🚀 Dynamic lookup directly from the thread's underlying map data
    // This bypasses the strict static getter restriction on the ChatThread type.
    String? fallbackAdImage;
    try {
      // If your model exposes an inner map property (commonly named: json, map, or attributes)
      final dynamic rawData =
          (thread as dynamic).json ?? (thread as dynamic).map;
      if (rawData != null && rawData is Map) {
        fallbackAdImage =
            rawData['ad_image_url'] ??
            rawData['ad_image'] ??
            rawData['product_image'] ??
            rawData['ad']?['image_url'];
      }
    } catch (_) {
      // Quietly fall back if property names do not exist dynamically
    }

    return MessageModel(
      senderName: otherParticipant?.name ?? 'Unknown User',
      subTitle: thread.adTitle,
      lastMessage: thread.latestMessage?.body ?? '',
      time: _formatTime(thread.updatedAt),
      unreadCount: thread.unreadCount,

      // Use the dynamically discovered image, falling back to user avatar, then null
      imageUrl: fallbackAdImage ?? otherParticipant?.avatarUrl,

      isVendor: otherParticipant?.isVendor ?? false,
      thread: thread,
    );
  }

  /// Helper method to format time for chat list
  static String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Optional: toMap method (useful for debugging or caching)
  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'subTitle': subTitle,
      'lastMessage': lastMessage,
      'time': time,
      'unreadCount': unreadCount,
      'imageUrl': imageUrl,
      'isVendor': isVendor,
      'threadId': thread.id,
    };
  }
}
