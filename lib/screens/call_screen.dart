// ─────────────────────────────────────────────────────────────
//  screens/call_screen.dart
//  Audio / Video call screen using Agora
//  Requires: agora_rtc_engine package in pubspec.yaml
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/chat_model.dart';
import '../services/chat_service.dart';

/// NOTE: This screen provides the full call UI and handles
/// Agora lifecycle. Add `agora_rtc_engine: ^6.x.x` to pubspec.yaml
/// and import the actual SDK. The AgoraRTC calls below are
/// annotated with [AGORA] so you can swap them in directly.

class CallScreen extends StatefulWidget {
  final CallSession session;
  final ChatService service;

  const CallScreen({super.key, required this.session, required this.service});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const _orange = Color(0xFFE85D22);
  static const _darkBg = Color(0xFF1A1A2E);

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;
  bool _callConnected = false;
  bool _isEnding = false;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  // [AGORA] RtcEngine? _engine;
  // [AGORA] int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    // [AGORA] _engine?.leaveChannel();
    // [AGORA] _engine?.release();
    super.dispose();
  }

  Future<void> _initCall() async {
    // ── [AGORA] Initialize Agora Engine ──────────────────────────
    // _engine = createAgoraRtcEngine();
    // await _engine!.initialize(RtcEngineContext(appId: 'YOUR_AGORA_APP_ID'));
    //
    // _engine!.registerEventHandler(RtcEngineEventHandler(
    //   onJoinChannelSuccess: (connection, elapsed) {
    //     setState(() => _callConnected = true);
    //     _startTimer();
    //   },
    //   onUserJoined: (connection, remoteUid, elapsed) {
    //     setState(() => _remoteUid = remoteUid);
    //   },
    //   onUserOffline: (connection, remoteUid, reason) {
    //     setState(() => _remoteUid = null);
    //     _endCall();
    //   },
    // ));
    //
    // if (widget.session.callType == CallType.video) {
    //   await _engine!.enableVideo();
    // }
    //
    // await _engine!.joinChannel(
    //   token: widget.session.token,
    //   channelId: widget.session.channelName,
    //   uid: widget.session.uid,
    //   options: const ChannelMediaOptions(),
    // );
    // ─────────────────────────────────────────────────────────────

    // Simulated connection for UI testing (remove when Agora is integrated)
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _callConnected = true);
      _startTimer();
    }
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDuration += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _endCall() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);

    try {
      await widget.service.endCall(
        receiverId: widget.session.receiverId,
        channelName: widget.session.channelName,
      );
    } catch (_) {}

    // [AGORA] await _engine?.leaveChannel();

    if (mounted) Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    // [AGORA] _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    // [AGORA] _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    // [AGORA] _engine?.muteLocalVideoStream(_isCameraOff);
  }

  void _switchCamera() {
    // [AGORA] _engine?.switchCamera();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.session.callType == CallType.video;
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // ── Video views ─────────────────────────────────────────
          if (isVideo) _buildVideoLayer(),

          // ── Gradient overlay ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBB1A1A2E),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xDD000000),
                ],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),

          // ── Top info ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.session.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(),
                ],
              ),
            ),
          ),

          // ── Controls ────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Secondary controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSecondaryBtn(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onTap: _toggleMute,
                          active: _isMuted,
                        ),
                        const SizedBox(width: 24),
                        _buildSecondaryBtn(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_off,
                          label: 'Speaker',
                          onTap: _toggleSpeaker,
                          active: !_isSpeakerOn,
                        ),
                        if (isVideo) ...[
                          const SizedBox(width: 24),
                          _buildSecondaryBtn(
                            icon: _isCameraOff
                                ? Icons.videocam_off
                                : Icons.videocam,
                            label: 'Camera',
                            onTap: _toggleCamera,
                            active: _isCameraOff,
                          ),
                          const SizedBox(width: 24),
                          _buildSecondaryBtn(
                            icon: Icons.flip_camera_ios,
                            label: 'Flip',
                            onTap: _switchCamera,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),
                    // End call button
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: _isEnding
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'End Call',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (!_callConnected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Connecting...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Text(
        _formatDuration(_callDuration),
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSecondaryBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? _orange.withOpacity(0.9)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? _orange : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    // [AGORA] Replace containers below with actual AgoraVideoView widgets
    return Stack(
      children: [
        // Remote video (full screen)
        // [AGORA] AgoraVideoView(controller: VideoViewController.remote(...))
        Container(color: const Color(0xFF0D0D1A)),

        // Local video (picture-in-picture)
        Positioned(
          top: 100,
          right: 16,
          child: Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            // [AGORA] child: AgoraVideoView(controller: VideoViewController(...))
            child: const Center(
              child: Icon(Icons.person, color: Colors.white54, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}
