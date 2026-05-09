// ─────────────────────────────────────────────────────────────
//  models/chat_models.dart
//  Data models for Chat, ChatMessage, and Call features
// ─────────────────────────────────────────────────────────────

class ChatThread {
  final int id;
  final int adId;
  final int buyerId;
  final int vendorId;
  final bool vendorRead;
  final bool buyerRead;
  final String? lastMessageAt;
  final ChatMessageModel? latestMessage;
  final ChatAd? ad;
  final ChatUser? buyer;
  final ChatVendor? vendor;

  const ChatThread({
    required this.id,
    required this.adId,
    required this.buyerId,
    required this.vendorId,
    required this.vendorRead,
    required this.buyerRead,
    this.lastMessageAt,
    this.latestMessage,
    this.ad,
    this.buyer,
    this.vendor,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'],
      adId: json['ad_id'],
      buyerId: json['buyer_id'],
      vendorId: json['vendor_id'],
      vendorRead: json['vendor_read'] ?? false,
      buyerRead: json['buyer_read'] ?? false,
      lastMessageAt: json['last_message_at'],
      latestMessage: json['latest_message'] != null
          ? ChatMessageModel.fromJson(json['latest_message'])
          : null,
      ad: json['ad'] != null ? ChatAd.fromJson(json['ad']) : null,
      buyer: json['buyer'] != null ? ChatUser.fromJson(json['buyer']) : null,
      vendor: json['vendor'] != null
          ? ChatVendor.fromJson(json['vendor'])
          : null,
    );
  }
}

class ChatMessageModel {
  final int id;
  final int chatId;
  final int senderId;
  final String? body;
  final String? imagePath;
  final String? readAt;
  final String? createdAt;
  final ChatUser? sender;

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.body,
    this.imagePath,
    this.readAt,
    this.createdAt,
    this.sender,
  });

  bool get isRead => readAt != null;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      body: json['body'],
      imagePath: json['image_path'],
      readAt: json['read_at'],
      createdAt: json['created_at'],
      sender: json['sender'] != null ? ChatUser.fromJson(json['sender']) : null,
    );
  }
}

class ChatAd {
  final int id;
  final String title;
  final String? type;

  const ChatAd({required this.id, required this.title, this.type});

  factory ChatAd.fromJson(Map<String, dynamic> json) {
    return ChatAd(
      id: json['id'],
      title: json['title'] ?? '',
      type: json['type'],
    );
  }
}

class ChatUser {
  final int id;
  final String name;
  final String? profilePhoto;

  const ChatUser({required this.id, required this.name, this.profilePhoto});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'],
      name: json['name'] ?? '',
      profilePhoto: json['profile_photo'],
    );
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

class ChatVendor {
  final int id;
  final String name;
  final String? businessName;
  final String? logoPath;

  const ChatVendor({
    required this.id,
    required this.name,
    this.businessName,
    this.logoPath,
  });

  factory ChatVendor.fromJson(Map<String, dynamic> json) {
    return ChatVendor(
      id: json['id'],
      name: json['name'] ?? '',
      businessName: json['business_name'],
      logoPath: json['logo_path'],
    );
  }

  String get displayName => businessName ?? name;
  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}

// ── Paginated Response Wrapper ─────────────────────────────────
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

// ── Agora Call Models ──────────────────────────────────────────
class AgoraTokenResponse {
  final String token;
  final String channelName;
  final int uid;

  const AgoraTokenResponse({
    required this.token,
    required this.channelName,
    required this.uid,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token: json['token'],
      channelName: json['channel_name'],
      uid: json['uid'],
    );
  }
}

enum CallType { audio, video }

class CallSession {
  final String channelName;
  final String token;
  final int uid;
  final CallType callType;
  final String callerName;
  final int receiverId;

  const CallSession({
    required this.channelName,
    required this.token,
    required this.uid,
    required this.callType,
    required this.callerName,
    required this.receiverId,
  });
}
