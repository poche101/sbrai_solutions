// ─────────────────────────────────────────────────────────────
//  widgets/chat_input_bar.dart
//  Bottom input bar: image picker + text field + send button
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;
  final bool isSending;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onPickImage,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image picker button
            _RoundedIconBtn(
              icon: Icons.image_outlined,
              onTap: isSending ? null : onPickImage,
            ),
            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) => onSendText(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSending
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 46,
                      height: 46,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Color(0xFFE85D22),
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : GestureDetector(
                      key: const ValueKey('send'),
                      onTap: onSendText,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85D22),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE85D22).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundedIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundedIconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: onTap == null ? Colors.grey.shade100 : Colors.white,
        ),
        child: Icon(
          icon,
          color: onTap == null ? Colors.grey.shade400 : Colors.black54,
          size: 22,
        ),
      ),
    );
  }
}
