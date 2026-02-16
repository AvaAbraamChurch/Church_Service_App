# Hymns Audio Player - Installation Instructions

## Changes Made

1. **Added audioplayers package** to `pubspec.yaml`:
   - Added `audioplayers: ^6.1.0` dependency for audio playback

2. **Created AudioPlayerService** (`lib/core/services/audio_player_service.dart`):
   - Singleton service for managing audio playback
   - Features:
     - Play audio from URL
     - Pause/Resume playback
     - Stop playback
     - Seek to position
     - Track playback state (playing, paused, stopped)
     - Track audio position and duration
     - Volume control

3. **Updated HymnsScreen** (`lib/modules/Home/Hymns/hymns_screen.dart`):
   - Added audio player integration
   - Added play/pause/stop buttons
   - Added progress bar with seek functionality
   - Added time display (current position / total duration)
   - Loading state indicator
   - Error handling with user feedback

## Installation Steps

**IMPORTANT**: You need to run the following command to install the new dependency:

```bash
flutter pub get
```

Or in your IDE:
- **VS Code**: Open the command palette (Ctrl+Shift+P) and run "Flutter: Get Packages"
- **Android Studio/IntelliJ**: Click "Pub get" in the notification bar or go to Tools > Flutter > Flutter Pub Get

## Features

### Audio Playback Controls:
- **Play Button**: Starts playing the hymn audio from the selected hymn's URL
- **Pause Button**: Pauses the currently playing audio (appears when audio is playing)
- **Stop Button**: Stops the audio and resets to the beginning
- **Progress Slider**: Shows current playback position and allows seeking
- **Time Display**: Shows current position / total duration (e.g., "2:30 / 5:45")
- **Loading Indicator**: Shows while audio is loading

### How It Works:
1. **Select a hymn** from the dropdown menu
2. **Audio player appears** if the hymn has an audioUrl
3. **Tap play button** to fetch and stream the audio from the URL
4. **Pause/Resume** as needed
5. **Seek** to any position by dragging the slider
6. **Stop** to reset the playback

### Technical Details:
- Audio is streamed directly from the URL (no manual download required)
- The `audioplayers` package handles the download and caching automatically
- Supports online streaming with progress tracking
- Audio continues playing even if you select a different hymn (use stop button to stop playback)
- Only one audio can play at a time - selecting a new hymn stops the current one

## Troubleshooting

If you encounter errors:

1. Make sure you've run `flutter pub get`
2. Clean and rebuild the project:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
3. Check that the audioUrl in your Firestore hymns collection is valid and accessible

## Next Steps

You can enhance this further by:
- Adding a playlist feature
- Adding download for offline playback
- Adding playback speed control
- Integrating background audio playback
- Adding audio effects (equalizer, etc.)

