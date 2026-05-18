// ─────────────────────────────────────────────────────────────
//  widgets/message_bubble.dart
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/chat_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  // ✅ fixed: matches your actual API base
  static const _storageBaseUrl = 'https://sbraisolutions.com/storage/';

  const MessageBubble({super.key, required this.message, required this.isMe});

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            _buildBubble(context),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead
                        ? const Color(0xFFE85D22)
                        : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final hasImage = message.imagePath != null && message.imagePath!.isNotEmpty;
    final hasText = message.body != null && message.body!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE85D22) : Colors.grey.shade200,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) _buildImage(),
          if (hasText)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                message.body!,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          // ✅ show placeholder if message has neither text nor image yet
          if (!hasText && !hasImage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                '...',
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black38,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final path = message.imagePath!;
    final isLocalFile = path.startsWith('/') || path.startsWith('file://');

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(4),
      ),
      child: isLocalFile
          ? Image.file(
              File(path),
              width: 220,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imageFallback(),
            )
          : Image.network(
              '$_storageBaseUrl$path',
              width: 220,
              height: 180,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  width: 220,
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFFE85D22),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _imageFallback(),
            ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 220,
      height: 180,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
    );
  }
}
