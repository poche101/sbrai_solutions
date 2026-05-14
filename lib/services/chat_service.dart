// ─────────────────────────────────────────────────────────────
//  services/chat_service.dart
//  All API calls for Chat and Call endpoints
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sbrai_solutions/models/chat_model.dart';

class ChatService {
  // ── Configuration ─────────────────────────────────────────────
  // Replace with your actual base URL
  static const String _baseUrl = 'https://sbraisolutions.com/api/v1';

  final String _authToken;

  ChatService(this._authToken);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_authToken',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ── GET /api/v1/chats ──────────────────────────────────────────
  Future<PaginatedResponse<ChatThread>> getChats({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/chats?page=$page');
    final response = await http.get(uri, headers: _headers);

    _throwIfError(response);

    final json = jsonDecode(response.body);
    final pageData = json['data'];

    final threads = (pageData['data'] as List)
        .map((e) => ChatThread.fromJson(e))
        .toList();

    return PaginatedResponse<ChatThread>(
      data: threads,
      currentPage: pageData['current_page'],
      lastPage: pageData['last_page'],
      total: pageData['total'],
    );
  }

  // ── POST /api/v1/chats ─────────────────────────────────────────
  Future<ChatThread> startChat({
    required int adId,
    String? message,
    File? image,
  }) async {
    final uri = Uri.parse('$_baseUrl/chats');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $_authToken',
        'Accept': 'application/json',
      })
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _throwIfError(response);

    final json = jsonDecode(response.body);
    return ChatThread.fromJson(json['data']);
  }

  // ── GET /api/v1/chats/{id}/messages ───────────────────────────
  Future<PaginatedResponse<ChatMessageModel>> getMessages(
    int chatId, {
    int page = 1,
  }) async {
    final uri = Uri.parse('$_baseUrl/chats/$chatId/messages?page=$page');
    final response = await http.get(uri, headers: _headers);

    _throwIfError(response);

    final json = jsonDecode(response.body);
    final pageData = json['data'];

    final messages = (pageData['data'] as List)
        .map((e) => ChatMessageModel.fromJson(e))
        .toList();

    return PaginatedResponse<ChatMessageModel>(
      data: messages,
      currentPage: pageData['current_page'],
      lastPage: pageData['last_page'],
      total: pageData['total'],
    );
  }

  // ── POST /api/v1/chats/{id}/messages ──────────────────────────
  Future<ChatMessageModel> sendMessage(
    int chatId, {
    String? message,
    File? image,
  }) async {
    final uri = Uri.parse('$_baseUrl/chats/$chatId/messages');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $_authToken',
        'Accept': 'application/json',
      });

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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _throwIfError(response);

    final json = jsonDecode(response.body);
    return ChatMessageModel.fromJson(json['data']);
  }

  // ── POST /api/v1/chats/{id}/read ──────────────────────────────
  Future<void> markRead(int chatId) async {
    final uri = Uri.parse('$_baseUrl/chats/$chatId/read');
    final response = await http.post(uri, headers: _headers);
    _throwIfError(response);
  }

  // ── POST /api/v1/calls/token ───────────────────────────────────
  Future<AgoraTokenResponse> getCallToken({
    required String channelName,
    required int uid,
  }) async {
    final uri = Uri.parse('$_baseUrl/calls/token');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'channel_name': channelName, 'uid': uid}),
    );

    _throwIfError(response);

    final json = jsonDecode(response.body);
    return AgoraTokenResponse.fromJson(json['data'] ?? json);
  }

  // ── POST /api/v1/calls/initiate ───────────────────────────────
  Future<void> initiateCall({
    required int receiverId,
    required String channelName,
    required String callerName,
    required CallType callType,
  }) async {
    final uri = Uri.parse('$_baseUrl/calls/initiate');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'channel_name': channelName,
        'caller_name': callerName,
        'call_type': callType == CallType.audio ? 'audio' : 'video',
      }),
    );

    _throwIfError(response);
  }

  // ── POST /api/v1/calls/end ─────────────────────────────────────
  Future<void> endCall({
    required int receiverId,
    required String channelName,
  }) async {
    final uri = Uri.parse('$_baseUrl/calls/end');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'channel_name': channelName,
      }),
    );

    _throwIfError(response);
  }

  // ── Private helpers ────────────────────────────────────────────
  void _throwIfError(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        message = json['message'] ?? message;
      } catch (_) {}
      throw ChatApiException(message, response.statusCode);
    }
  }
}

class ChatApiException implements Exception {
  final String message;
  final int statusCode;

  const ChatApiException(this.message, this.statusCode);

  @override
  String toString() => 'ChatApiException($statusCode): $message';
}
