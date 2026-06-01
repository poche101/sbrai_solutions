// lib/services/chat_service.dart
// All API calls for Chat and Call endpoints — aligned with ChatController

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sbrai_solutions/models/chat_model.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';

class ChatService {
  static const String _baseUrl = 'https://sbraisolutions.com/api/v1';

  final int currentUserId;

  /// Token is lazy-loaded from [ApiService] (SharedPreferences) on first use
  /// so it is always fresh regardless of when [ChatService] is constructed.
  String? _cachedToken;

  /// [currentUserId] — ID of the logged-in user (vendor or buyer).
  ChatService({required this.currentUserId});

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<String> _getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken!;
    _cachedToken = await ApiService().getToken();
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      throw const ChatApiException(
        'Session expired. Please log in again.',
        401,
      );
    }
    return _cachedToken!;
  }

  /// Call this to force a fresh token fetch (e.g. after re-login).
  void invalidateToken() => _cachedToken = null;

  // ── Headers ────────────────────────────────────────────────────────────────

  Future<Map<String, String>> get _headers async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, String>> get _multipartHeaders async {
    final token = await _getToken();
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  // ── GET /api/v1/chats ──────────────────────────────────────────────────────
  /// Returns the paginated list of chat threads for the authenticated user.
  /// Controller: index() — filters by vendor_id or buyer_id automatically.
  Future<PaginatedResponse<ChatThread>> getChats({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/chats?page=$page');
    final response = await http.get(uri, headers: await _headers);
    _throwIfError(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final pageData = body['data'] as Map<String, dynamic>;

    return PaginatedResponse<ChatThread>(
      data: (pageData['data'] as List)
          .map((e) => ChatThread.fromJson(e))
          .toList(),
      currentPage: pageData['current_page'] as int,
      lastPage: pageData['last_page'] as int,
      total: pageData['total'] as int,
    );
  }

  // ── POST /api/v1/chats ─────────────────────────────────────────────────────
  /// Starts a new chat thread or returns the existing one for the same ad+buyer.
  /// Controller: start() — uses firstOrCreate so calling it twice is safe.
  ///
  /// Returns the [ChatThread] with the chat id needed to open [ChatScreen].
  Future<ChatThread> startChat({
    required int adId,
    String? message,
    File? image,
  }) async {
    final uri = Uri.parse('$_baseUrl/chats');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _multipartHeaders)
      ..fields['ad_id'] = adId.toString();

    if (message != null && message.isNotEmpty) {
      request.fields['message'] = message;
    }

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _throwIfError(response);

    // Controller returns: { success: true, data: { id, ad, latestMessage, ... } }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatThread.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── GET /api/v1/chats/{id}/messages ───────────────────────────────────────
  /// Fetches paginated messages for a chat thread.
  /// Controller: messages() — also marks messages as read and broadcasts receipt.
  Future<PaginatedResponse<ChatMessageModel>> getMessages(
    int chatId, {
    int page = 1,
  }) async {
    final uri = Uri.parse('$_baseUrl/chats/$chatId/messages?page=$page');
    final response = await http.get(uri, headers: await _headers);
    _throwIfError(response);

    // Controller returns: { success: true, data: { data: [], current_page, last_page, total } }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final pageData = body['data'] as Map<String, dynamic>;

    return PaginatedResponse<ChatMessageModel>(
      data: (pageData['data'] as List)
          .map((e) => ChatMessageModel.fromJson(e))
          .toList(),
      currentPage: pageData['current_page'] as int,
      lastPage: pageData['last_page'] as int,
      total: pageData['total'] as int,
    );
  }

  // ── POST /api/v1/chats/{id}/messages ──────────────────────────────────────
  /// Sends a text or image message.
  /// Controller: send() — broadcasts MessageSent + sends FCM push.
  /// Returns the created [ChatMessageModel].
  Future<ChatMessageModel> sendMessage(
    int chatId, {
    String? message,
    File? image,
  }) async {
    final uri = Uri.parse('$_baseUrl/chats/$chatId/messages');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _multipartHeaders);

    if (message != null && message.isNotEmpty) {
      request.fields['message'] = message;
    }

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _throwIfError(response);

    // Controller returns: { success: true, data: { id, chat_id, sender_id, body, ... } }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessageModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── POST /api/v1/chats/{id}/read ──────────────────────────────────────────
  /// Marks all unread messages in a thread as read.
  /// Controller: markRead() — broadcasts MessageRead receipt.
  Future<void> markRead(int chatId) async {
    final uri = Uri.parse('$_baseUrl/chats/$chatId/read');
    final response = await http.post(uri, headers: await _headers);
    _throwIfError(response);
  }

  // ── POST /api/v1/calls/token ───────────────────────────────────────────────
  /// API response: { "status": true, "token": "...", "app_id": "..." }
  /// channel_name and uid are NOT returned — they are echoed from the request.
  Future<AgoraTokenResponse> getCallToken({
    required String channelName,
    required int uid,
  }) async {
    final uri = Uri.parse('$_baseUrl/calls/token');
    final response = await http.post(
      uri,
      headers: await _headers,
      body: jsonEncode({'channel_name': channelName, 'uid': uid}),
    );

    debugPrint('📞 getCallToken raw response: ${response.body}');
    _throwIfError(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Pass channelName and uid back in since the API doesn't echo them
    return AgoraTokenResponse.fromJson(
      body,
      channelName: channelName,
      uid: uid,
    );
  }

  // ── POST /api/v1/calls/initiate ───────────────────────────────────────────
  Future<void> initiateCall({
    required int receiverId,
    required String channelName,
    required String callerName,
    required CallType callType,
  }) async {
    final uri = Uri.parse('$_baseUrl/calls/initiate');
    final response = await http.post(
      uri,
      headers: await _headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'channel_name': channelName,
        'caller_name': callerName,
        'call_type': callType == CallType.audio ? 'audio' : 'video',
      }),
    );
    _throwIfError(response);
  }

  // ── POST /api/v1/calls/end ────────────────────────────────────────────────
  Future<void> endCall({
    required int receiverId,
    required String channelName,
  }) async {
    final uri = Uri.parse('$_baseUrl/calls/end');
    final response = await http.post(
      uri,
      headers: await _headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'channel_name': channelName,
      }),
    );
    _throwIfError(response);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _throwIfError(http.Response response) {
    if (response.statusCode < 400) return;

    // Detect Laravel's "Unauthenticated." message regardless of status code.
    // Some Laravel setups return 500 instead of 401 for missing tokens.
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message']?.toString() ?? '';

      if (response.statusCode == 401 ||
          message.toLowerCase() == 'unauthenticated.') {
        // Evict cached token so the next attempt re-reads from SharedPreferences.
        invalidateToken();
        throw const ChatApiException(
          'Session expired. Please log in again.',
          401,
        );
      }

      final display = message.isNotEmpty
          ? message
          : 'Request failed (${response.statusCode})';
      throw ChatApiException(display, response.statusCode);
    } on ChatApiException {
      rethrow;
    } catch (_) {
      throw ChatApiException(
        'Request failed (${response.statusCode})',
        response.statusCode,
      );
    }
  }
}

// ── Exception ──────────────────────────────────────────────────────────────

class ChatApiException implements Exception {
  final String message;
  final int statusCode;

  const ChatApiException(this.message, this.statusCode);

  @override
  String toString() => 'ChatApiException($statusCode): $message';
}
