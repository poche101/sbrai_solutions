// ─────────────────────────────────────────────────────────────
//  screens/call_screen.dart
//  Audio / Video call screen using Agora RTC Engine
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sbrai_solutions/models/chat_model.dart';
import '../services/chat_service.dart';

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

  RtcEngine? _engine;
  int? _remoteUid;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;
  bool _callConnected = false;
  bool _isEnding = false;
  String? _errorMessage;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    // Defer to ensure the widget tree is fully built before requesting
    // permissions — prevents MethodChannel crashes on some Android devices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initCall();
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  // ── Agora init ─────────────────────────────────────────────────────────────

  Future<void> _initCall() async {
    // ── Step 1: Request permissions ────────────────────────────────────────
    try {
      final micStatus = await Permission.microphone.request();

      if (!mounted) return;

      if (widget.session.callType == CallType.video) {
        await Permission.camera.request();
        if (!mounted) return;
      }

      if (!micStatus.isGranted) {
        setState(() => _errorMessage = 'Microphone permission denied.');
        return;
      }
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Could not request permissions: $e');
      }
      return;
    }

    // ── Step 2: Initialise Agora engine ────────────────────────────────────
    try {
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(
        RtcEngineContext(
          appId: widget.session.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('✅ Joined channel: ${connection.channelId}');
            // Set speakerphone AFTER joining — calling it before join
            // returns error -4 (ERR_NOT_SUPPORTED) on Android
            _engine?.setEnableSpeakerphone(_isSpeakerOn);
            if (mounted) {
              setState(() => _callConnected = true);
              _startTimer();
            }
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            debugPrint('👤 Remote user joined: $remoteUid');
            if (mounted) setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            debugPrint('👤 Remote user left: $remoteUid');
            if (mounted) setState(() => _remoteUid = null);
            _endCall();
          },
          onError: (err, msg) {
            debugPrint('❌ Agora error: $err — $msg');
            if (mounted) setState(() => _errorMessage = 'Call error: $msg');
          },
        ),
      );

      if (widget.session.callType == CallType.video) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
      }

      // NOTE: setEnableSpeakerphone is intentionally NOT called here.
      // It must be called after joinChannel succeeds (inside onJoinChannelSuccess)
      // to avoid AgoraRtcException(-4) on Android.

      // ── DEBUG: log session values before joining ──────────────────────────
      debugPrint('🔑 appId: "${widget.session.appId}"');
      debugPrint('🔑 channelName: "${widget.session.channelName}"');
      debugPrint('🔑 uid: ${widget.session.uid}');
      debugPrint('🔑 token length: ${widget.session.token.length}');
      debugPrint(
        '🔑 token prefix: "${widget.session.token.substring(0, widget.session.token.length.clamp(0, 10))}"',
      );

      // Safety check
      if (widget.session.token.isEmpty) {
        setState(
          () => _errorMessage = 'Invalid or empty token received from server.',
        );
        return;
      }

      await _engine!.joinChannel(
        token: widget.session.token, // ← Fixed: Now using real token
        channelId: widget.session.channelName,
        uid: widget.session.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: widget.session.callType == CallType.video,
        ),
      );
    } catch (e) {
      debugPrint('❌ Agora init error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Could not start call: $e');
      }
    }
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDuration += const Duration(seconds: 1));
      }
    });
  }

  // ── Call controls ──────────────────────────────────────────────────────────

  Future<void> _endCall() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);

    try {
      await widget.service.endCall(
        receiverId: widget.session.receiverId,
        channelName: widget.session.channelName,
      );
    } catch (_) {}

    await _engine?.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _engine?.muteLocalVideoStream(_isCameraOff);
  }

  void _switchCamera() {
    _engine?.switchCamera();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.session.callType == CallType.video;

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _darkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.call_end, color: Colors.red, size: 56),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // ── Video views ───────────────────────────────────────
          if (isVideo) _buildVideoLayer(),

          // ── Gradient overlay ──────────────────────────────────
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

          // ── Top info ──────────────────────────────────────────
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

          // ── Controls ──────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

  // ── Widgets ────────────────────────────────────────────────────────────────

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
    return Stack(
      children: [
        // Remote video full screen
        if (_remoteUid != null && _engine != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUid!),
              connection: RtcConnection(channelId: widget.session.channelName),
            ),
          )
        else
          Container(
            color: const Color(0xFF0D0D1A),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white24, size: 80),
            ),
          ),

        // Local video picture-in-picture
        if (_engine != null)
          Positioned(
            top: 100,
            right: 16,
            child: SizedBox(
              width: 100,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isCameraOff
                    ? Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white54,
                            size: 32,
                          ),
                        ),
                      )
                    : AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
