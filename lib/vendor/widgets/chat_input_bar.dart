// ─────────────────────────────────────────────────────────────
//  widgets/chat_input_bar.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
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
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

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
            // ── Image picker — slides away when typing ─────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasText
                  ? const SizedBox(key: ValueKey('hidden'), width: 0)
                  : _RoundedIconBtn(
                      key: const ValueKey('image'),
                      icon: Icons.image_outlined,
                      onTap: widget.isSending ? null : widget.onPickImage,
                    ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _hasText ? 0 : 8,
            ),

            // ── Text field ─────────────────────────────────────────
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !widget.isSending,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onSubmitted: (_) {
                          if (!widget.isSending) widget.onSendText();
                        },
                      ),
                    ),
                    // ── Emoji placeholder ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ── Send button ────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: widget.isSending
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
                      onTap: _hasText ? widget.onSendText : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          // grey when empty, orange when ready
                          color: _hasText
                              ? const Color(0xFFE85D22)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _hasText
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE85D22,
                                    ).withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: _hasText ? Colors.white : Colors.grey.shade500,
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

  const _RoundedIconBtn({super.key, required this.icon, this.onTap});

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
