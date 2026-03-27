import 'dart:async';

import 'package:audio_session/audio_session.dart'
    hide AndroidAudioFocus, AVAudioSessionCategory;
import 'package:audio_session/audio_session.dart' as as_session;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Manages all audio output for the app: Text-to-Speech voice cues and
/// countdown sound effects.
///
/// Implements "Audio Ducking" via [AudioSession] so that background music
/// (e.g. Spotify) lowers its volume instead of pausing.
class AudioService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _countdownPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  // Track if we explicitly activated the session for our sounds.
  // flutter_tts handles its own session activations, but we want
  // to ensure ducking is active for our short beeps.
  bool _isSessionActive = false;
  int _activeAudioCount = 0;
  Timer? _deactivateTimer;

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Configure AudioPlayers to NEVER handle AudioFocus.
      // We manage it manually with audio_session for smooth ducking.
      const audioContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: [AVAudioSessionOptions.duckOthers],
        ),
      );
      AudioPlayer.global.setAudioContext(audioContext);
      await _countdownPlayer.setAudioContext(audioContext);

      // Preload sounds
      await _countdownPlayer.setSource(AssetSource('sounds/countdown.wav'));
      
      // Handle ducking end when countdown playback is actually finished
      _countdownPlayer.onPlayerComplete.listen((_) {
        _deactivateSession();
      });

      final session = await AudioSession.instance;
      // Configure audio session for speech with ducking enabled
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: as_session.AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              as_session.AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: as_session.AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              as_session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions:
              as_session.AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: as_session.AndroidAudioAttributes(
            contentType: as_session.AndroidAudioContentType.sonification,
            flags: as_session.AndroidAudioFlags.none,
            usage: as_session.AndroidAudioUsage.assistanceSonification,
          ),
          androidAudioFocusGainType:
              as_session.AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );

      // Set up TTS
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.5); // 0.5 is usually a natural speed
      await _flutterTts.setPitch(1.0);

      // Handle ducking end when TTS completes or cancels
      _flutterTts.setCompletionHandler(() {
        _deactivateSession();
      });
      _flutterTts.setCancelHandler(() {
        _deactivateSession();
      });
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _deactivateSession();
      });
    } catch (e) {
      debugPrint('AudioService initialization error: $e');
    }
  }

  Future<void> _activateSession() async {
    _deactivateTimer?.cancel();
    _activeAudioCount++;
    if (_isSessionActive) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      _isSessionActive = true;
    } catch (e) {
      debugPrint('Failed to activate audio session: $e');
    }
  }

  Future<void> _deactivateSession() async {
    _activeAudioCount--;
    if (_activeAudioCount > 0) return;
    _activeAudioCount = 0;

    // Release focus quickly upon finish
    _deactivateTimer?.cancel();
    _deactivateTimer = Timer(const Duration(milliseconds: 100), () async {
      if (_activeAudioCount > 0 || !_isSessionActive) return;
      try {
        final session = await AudioSession.instance;
        await session.setActive(false);
        _isSessionActive = false;
      } catch (e) {
        debugPrint('Failed to deactivate audio session: $e');
      }
    });
  }

  /// Speaks the given [text] aloud using the platform TTS engine.
  ///
  /// Activates the audio session for ducking before speaking. The session
  /// is deactivated automatically when TTS completes or is cancelled.
  Future<void> speak(String text) async {
    try {
      await _activateSession();
      await _flutterTts.speak(text);
      // We don't deactivate here directly; the completion handler will do it.
    } catch (e) {
      debugPrint('TTS speak error: $e');
      await _deactivateSession();
    }
  }

  /// Plays the pre-loaded countdown sound effect (`countdown.wav`).
  ///
  /// Activates the audio session for ducking and adds a 150 ms delay to
  /// allow the OS to lower background media volume before the first audio
  /// frame, preventing audible pops/cracks.
  Future<void> playCountdownSequence() async {
    try {
      await _activateSession();
      // Give the OS 150ms to duck Spotify volume before the first audio frame to prevent cracking
      await Future.delayed(const Duration(milliseconds: 150));
      await _countdownPlayer.seek(Duration.zero);
      await _countdownPlayer.resume();
      // We don't deactivate here directly; the onPlayerComplete listener handles it.
    } catch (e) {
      debugPrint('playCountdownSequence error: $e');
      await _deactivateSession();
    }
  }

  /// Stops the countdown sound if it is currently playing and deactivates
  /// the audio session.
  Future<void> stopCountdownSequence() async {
    try {
      if (_countdownPlayer.state == PlayerState.playing) {
        await _countdownPlayer.stop();
        _deactivateSession();
      }
    } catch (e) {
      debugPrint('stopCountdownSequence error: $e');
    }
  }

  /// Releases all audio resources. Call when the service is no longer needed.
  void dispose() {
    _deactivateTimer?.cancel();
    _countdownPlayer.dispose();
    _flutterTts.stop();
  }
}

/// Riverpod provider that creates and owns the singleton [AudioService].
///
/// Automatically disposes audio resources when the provider is destroyed.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
