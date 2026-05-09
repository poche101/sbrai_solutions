// ─────────────────────────────────────────────────────────────
//  widgets/start_chat_button.dart
//  Drop-in button to start a chat from any Ad/Product page.
//  Calls POST /api/v1/chats and then opens ChatScreen.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../screens/chat_screen.dart';

class StartChatButton extends StatefulWidget {
  final int adId;
  final String adTitle;
  final int vendorId;
  final String vendorName;
  final String authToken;
  final int currentUserId;

  const StartChatButton({
    super.key,
    required this.adId,
    required this.adTitle,
    required this.vendorId,
    required this.vendorName,
    required this.authToken,
    required this.currentUserId,
  });

  @override
  State<StartChatButton> createState() => _StartChatButtonState();
}

class _StartChatButtonState extends State<StartChatButton> {
  bool _isLoading = false;

  Future<void> _openChat() async {
    setState(() => _isLoading = true);

    final service = ChatService(widget.authToken);

    try {
      // Opens or creates a thread for this ad
      final thread = await service.startChat(
        adId: widget.adId,
        message: 'Hi, I\'m interested in ${widget.adTitle}',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: thread.id,
            authToken: widget.authToken,
            currentUserId: widget.currentUserId,
            otherPartyName: widget.vendorName,
            otherPartyInitial: widget.vendorName.isNotEmpty
                ? widget.vendorName[0].toUpperCase()
                : '?',
            adTitle: widget.adTitle,
            otherPartyId: widget.vendorId,
            service: service,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open chat. Please try again.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _openChat,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE85D22),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE85D22).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.chat_bubble_outline, size: 20),
        label: Text(
          _isLoading ? 'Opening chat...' : 'Chat with Vendor',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
