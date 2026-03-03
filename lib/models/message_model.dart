class MessageModel {
  final String senderName;
  final String? subTitle;
  final String lastMessage;
  final String time;
  final bool isVendor;
  final int unreadCount;
  final String? imageUrl;

  MessageModel({
    required this.senderName,
    required this.lastMessage,
    required this.time,
    this.subTitle,
    this.isVendor = false,
    this.unreadCount = 0,
    this.imageUrl,
  });

  // Convert JSON/Map data to Model
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderName: map['senderName'] ?? 'Unknown',
      lastMessage: map['lastMessage'] ?? '',
      time: map['time'] ?? '',
      subTitle: map['subTitle'],
      isVendor: map['isVendor'] ?? false,
      unreadCount: map['unreadCount'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }

  // Helper to convert Model back to Map if needed for uploading
  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'subTitle': subTitle,
      'lastMessage': lastMessage,
      'time': time,
      'isVendor': isVendor,
      'unreadCount': unreadCount,
      'imageUrl': imageUrl,
    };
  }
}
