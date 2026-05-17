// video_player_service.dart

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerService {
  /// Create controller
  static YoutubePlayerController createController({
    required String videoId,
    bool autoPlay = false,
    bool mute = false,
  }) {
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: autoPlay,
        mute: mute,
        enableCaption: true,
        isLive: false,
      ),
    );
  }

  /// Build player widget
  static Widget buildPlayer({
    required YoutubePlayerController controller,
    bool showProgressIndicator = true,
  }) {
    return YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: showProgressIndicator,
      progressIndicatorColor: Colors.red,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
      ),
    );
  }

  /// Extract video ID from URL
  static String extractVideoId(String url) {
    return YoutubePlayer.convertUrlToId(url) ?? '';
  }

  /// Dispose controller
  static void dispose(YoutubePlayerController controller) {
    controller.dispose();
  }
}