import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Service for managing audio playback for hymns
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentAudioUrl;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Stream controllers for state changes
  final ValueNotifier<PlayerState> playerStateNotifier = ValueNotifier(
    PlayerState.stopped,
  );
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  AudioPlayer get audioPlayer => _audioPlayer;
  PlayerState get playerState => _playerState;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentAudioUrl => _currentAudioUrl;

  /// Initialize the audio player with listeners
  void initialize() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      playerStateNotifier.value = state;
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      durationNotifier.value = newDuration;
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      positionNotifier.value = newPosition;
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _position = Duration.zero;
      positionNotifier.value = Duration.zero;
    });
  }

  /// Play audio from URL
  Future<void> play(String audioUrl) async {
    try {
      isLoadingNotifier.value = true;

      if (_currentAudioUrl != audioUrl && _playerState == PlayerState.playing) {
        await stop();
      }

      _currentAudioUrl = audioUrl;

      if (_playerState == PlayerState.paused && _currentAudioUrl == audioUrl) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Pause the current audio
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Stop the current audio
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentAudioUrl = null;
    _position = Duration.zero;
    positionNotifier.value = Duration.zero;
  }

  /// Resume the paused audio
  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// Check if currently playing
  bool get isPlaying => _playerState == PlayerState.playing;

  /// Check if currently paused
  bool get isPaused => _playerState == PlayerState.paused;

  /// Check if stopped
  bool get isStopped => _playerState == PlayerState.stopped;

  /// Check if the given URL is currently loaded
  bool isCurrentAudio(String audioUrl) => _currentAudioUrl == audioUrl;

  /// Dispose the audio player
  void dispose() {
    _audioPlayer.dispose();
    playerStateNotifier.dispose();
    durationNotifier.dispose();
    positionNotifier.dispose();
    isLoadingNotifier.dispose();
  }
}
