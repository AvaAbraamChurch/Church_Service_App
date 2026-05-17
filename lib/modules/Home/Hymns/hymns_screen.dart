import 'package:audioplayers/audioplayers.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/hymn_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as youtube;

import '../../../core/services/audio_player_service.dart';
import '../../../core/services/hymns_service.dart';
import '../../../core/services/video_player_service.dart';
import '../../../core/styles/colors.dart';
import 'add_hymn_screen.dart';
import 'edit_hymn_screen.dart';

class HymnsScreen extends StatefulWidget {
  const HymnsScreen({super.key});

  @override
  State<HymnsScreen> createState() => _HymnsScreenState();
}

class _HymnsScreenState extends State<HymnsScreen> {
  final HymnsService _hymnsService = HymnsService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final UsersRepository _usersRepository = UsersRepository();
  final ScrollController _scrollController = ScrollController();
  static const String _copticFontFamily = 'Athanasius';
  HymnModel? _selectedHymn;
  youtube.YoutubePlayerController? _videoPlayerController;
  bool _showDropdown = true;
  double _lastScrollOffset = 0.0;
  String? _currentUserClass;
  UserModel? _currentUser;
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _audioPlayerService.initialize();
    _scrollController.addListener(_onScroll);
    _loadCurrentUserClass();
  }

  /// Load the current user's class from Firebase
  Future<void> _loadCurrentUserClass() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _usersRepository.getUserById(userId);
        if (mounted) {
          setState(() {
            _currentUser = userDoc;
            _currentUserClass = userDoc.userClass;
          });
        }
      }
    } catch (e, st) {
      // Log to help diagnose failures loading the current user
      // ignore: avoid_print
      print('Error loading current user class: $e');
      // ignore: avoid_print
      print(st);
    }
  }

  /// Initialize or update the video player controller for the selected hymn
  void _initializeVideoPlayer(HymnModel hymn) {
    // Dispose old controller if it exists
    if (_videoPlayerController != null) {
      VideoPlayerService.dispose(_videoPlayerController!);
    }

    // Create new controller if hymn has video URL
    if (hymn.videoUrl != null && hymn.videoUrl!.isNotEmpty) {
      final videoId = VideoPlayerService.extractVideoId(hymn.videoUrl!);
      if (videoId.isNotEmpty) {
        _videoPlayerController = VideoPlayerService.createController(
          videoId: videoId,
          autoPlay: false,
          mute: false,
        );
      }
    } else {
      _videoPlayerController = null;
    }
  }

  /// Check if current user can manage hymns (servant, superServant, or priest)
  bool get _canManageHymns {
    if (_currentUser == null) return false;
    return _currentUser!.userType == UserType.servant ||
        _currentUser!.userType == UserType.superServant ||
        _currentUser!.userType == UserType.priest;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _audioPlayerService.stop();
    if (_videoPlayerController != null) {
      VideoPlayerService.dispose(_videoPlayerController!);
    }
    super.dispose();
  }

  void _onScroll() {
    final currentScrollOffset = _scrollController.offset;

    // Hide dropdown when scrolling down, show when scrolling up
    if (currentScrollOffset > _lastScrollOffset && currentScrollOffset > 50) {
      // Scrolling down
      if (_showDropdown) {
        setState(() {
          _showDropdown = false;
        });
      }
    } else if (currentScrollOffset < _lastScrollOffset) {
      // Scrolling up
      if (!_showDropdown) {
        setState(() {
          _showDropdown = true;
        });
      }
    }

    _lastScrollOffset = currentScrollOffset;
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        title: const Text(hymns, style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: _canManageHymns ? _buildFabMenu() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Dropdown menu for hymn selection with hide animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showDropdown ? null : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showDropdown ? 1.0 : 0.0,
                  child: StreamBuilder<List<HymnModel>>(
                    stream: _currentUserClass != null
                        ? _hymnsService.getHymnsByUserClass(_currentUserClass!)
                        : _hymnsService.getAllHymns(),
                    builder: (context, snapshot) {
                      // ...existing code...
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'خطأ في تحميل الألحان: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final hymns = snapshot.data ?? [];

                      // Keep dropdown values unique and non-empty to satisfy DropdownButton assertions.
                      final uniqueHymnsById = <String, HymnModel>{};
                      for (final hymn in hymns) {
                        final normalizedId = hymn.id.trim();
                        if (normalizedId.isEmpty ||
                            uniqueHymnsById.containsKey(normalizedId)) {
                          continue;
                        }
                        uniqueHymnsById[normalizedId] = hymn;
                      }
                      final dropdownHymns = uniqueHymnsById.values.toList(
                        growable: false,
                      );

                      final selectedId = _selectedHymn?.id.trim();
                      final safeSelectedId =
                          selectedId != null &&
                              uniqueHymnsById.containsKey(selectedId)
                          ? selectedId
                          : null;

                      if (_selectedHymn != null && safeSelectedId == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || _selectedHymn == null) return;
                          setState(() {
                            _selectedHymn = null;
                          });
                        });
                      }

                      if (dropdownHymns.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'لا توجد ألحان متاحة',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Show filter indicator if user class is loaded
                            if (_currentUserClass != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: teal500.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: teal500.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.filter_list,
                                        size: 16,
                                        color: teal700,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'الألحان المتاحة لفصلك: $_currentUserClass',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: teal700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            DropdownButtonFormField<String>(
                              key: ValueKey(safeSelectedId ?? 'no_selection'),
                              initialValue: safeSelectedId,
                              decoration: InputDecoration(
                                labelText: 'اختر اللحن',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                              ),
                              isExpanded: true,
                              hint: const Text('اختر لحناً من القائمة'),
                              items: dropdownHymns.map((hymn) {
                                return DropdownMenuItem<String>(
                                  value: hymn.id.trim(),
                                  child: Text(
                                    hymn.arabicTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue == null) return;
                                final selected = uniqueHymnsById[newValue];
                                if (selected == null) return;
                                setState(() {
                                  _selectedHymn = selected;
                                  _initializeVideoPlayer(selected);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Display selected hymn details in book-style 3-column layout
              Expanded(
                child: _selectedHymn == null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'اختر لحناً لعرض التفاصيل',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildBookStyleContent(),
              ),
            ],
          ),

          // Floating audio player bar at the bottom
          _buildFloatingAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildBookStyleContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Title Section with semi-transparent background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Arabic Title
                Text(
                  _selectedHymn!.arabicTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: teal500,
                  ),
                ),
                const SizedBox(height: 8),
                // Coptic Title
                if (_selectedHymn!.copticTitle.isNotEmpty)
                  Text(
                    _selectedHymn!.copticTitle,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: teal500,
                      fontFamily: _copticFontFamily,
                    ),
                  ),
                const SizedBox(height: 8),
                // English Title
                if (_selectedHymn!.title.isNotEmpty)
                  Text(
                    _selectedHymn!.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                // Occasion title
                if (_selectedHymn!.occasion != null)
                  SizedBox(height: 5,),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(_selectedHymn!.occasion ?? '', style: TextStyle(
                        fontSize: 14,
                        color: teal500,
                        fontStyle: FontStyle.italic,
                      )),
                    ),
                  )


          ],
              ),
          ),
          const SizedBox(height: 20),

          // Video Player Section (if available)
          if (_selectedHymn!.videoUrl != null &&
              _selectedHymn!.videoUrl!.isNotEmpty &&
              _videoPlayerController != null)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الفيديو',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: teal900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal[600]!, Colors.transparent],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModernVideoPlayer(),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // 3-Column Book-Style Layout
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Check if screen is wide enough for 3 columns (600px for tablets and up)
                bool isWideScreen = constraints.maxWidth > 600;

                if (isWideScreen) {
                  // 3-column layout for wide screens
                  final hasArabic =
                      _selectedHymn!.arabicLyrics != null &&
                      _selectedHymn!.arabicLyrics!.isNotEmpty;
                  final hasCoptic =
                      _selectedHymn!.copticLyrics != null &&
                      _selectedHymn!.copticLyrics!.isNotEmpty;
                  final hasEnglish =
                      _selectedHymn!.copticArlyrics != null &&
                      _selectedHymn!.copticArlyrics!.isNotEmpty;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic Column
                      if (hasArabic)
                        Expanded(
                          child: _buildLyricsColumn(
                            title: 'العربية',
                            lyrics: _selectedHymn!.arabicLyrics!,
                            isRightBorder: hasCoptic || hasEnglish,
                          ),
                        ),

                      // Coptic Column
                      if (hasCoptic)
                        Expanded(
                          child: _buildLyricsColumn(
                            title: 'القبطية',
                            lyrics: _selectedHymn!.copticLyrics!,
                            isRightBorder: hasEnglish,
                            direction: TextDirection.ltr,
                            fontFamily: _copticFontFamily,
                          ),
                        ),

                      // Arabic Coptic Column with left and right borders
                      if (hasEnglish)
                        Expanded(
                          child: _buildLyricsColumn(
                            title: 'قبطي معرب',
                            lyrics: _selectedHymn!.copticArlyrics!,
                            isRightBorder: true,
                            hasLeftBorder: true,
                          ),
                        ),
                    ],
                  );
                } else {
                  // Single column layout for narrow screens
                  return Column(
                    children: [
                      // Arabic Lyrics
                      if (_selectedHymn!.arabicLyrics != null &&
                          _selectedHymn!.arabicLyrics!.isNotEmpty)
                        _buildLyricsSection(
                          title: 'الكلمات بالعربية',
                          lyrics: _selectedHymn!.arabicLyrics!,
                        ),

                      // Coptic Lyrics
                      if (_selectedHymn!.copticLyrics != null &&
                          _selectedHymn!.copticLyrics!.isNotEmpty)
                        _buildLyricsSection(
                          fontSize: 30,
                          title: 'الكلمات بالقبطية',
                          lyrics: _selectedHymn!.copticLyrics!,
                          textDirection: TextDirection.ltr,
                          fontFamily: _copticFontFamily,
                        ),

                      // قبطي معرب
                      if (_selectedHymn!.copticArlyrics != null &&
                          _selectedHymn!.copticArlyrics!.isNotEmpty)
                        _buildLyricsSection(
                          title: 'قبطي معرب',
                          lyrics: _selectedHymn!.copticArlyrics!,
                        ),
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 80), // Space for floating player
        ],
      ),
    );
  }

  // Build a column for 3-column layout with book-style borders
  Widget _buildLyricsColumn({
    required String title,
    required String lyrics,
    required bool isRightBorder,
    TextDirection direction = TextDirection.rtl,
    String? fontFamily,
    bool hasLeftBorder = false,
  }) {
    // Split lyrics by double line breaks to get paragraphs/verses
    final List<String> verses = lyrics
        .split('\n\n')
        .where((verse) => verse.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          left: hasLeftBorder
              ? BorderSide(color: teal500.withValues(alpha: 0.4), width: 2)
              : BorderSide.none,
          right: isRightBorder
              ? BorderSide(color: teal500.withValues(alpha: 0.4), width: 2)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: teal900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 2,
            width: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[600]!, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Display verses with dividers between them
          ...verses.asMap().entries.map((entry) {
            final index = entry.key;
            final verse = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse,
                  textDirection: direction,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: teal900,
                    letterSpacing: 0.3,
                    fontFamily: fontFamily,
                    fontFamilyFallback: fontFamily == null
                        ? null
                        : const ['Alexandria'],
                  ),
                ),
                // Add divider after each verse except the last one
                if (index < verses.length - 1) ...[
                  const SizedBox(height: 16),
                  Divider(
                    color: teal500.withValues(alpha: 0.3),
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  // Build a section for single-column layout
  Widget _buildLyricsSection({
    required String title,
    required String lyrics,
    double fontSize = 20.0,
    TextDirection textDirection = TextDirection.rtl,
    String? fontFamily,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: teal700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[600]!, Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          lyrics,
          textDirection: textDirection,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.8,
            color: teal900,
            letterSpacing: 0.3,
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamily == null
                ? null
                : const ['Alexandria'],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // Format duration as mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Build modern video player with enhanced controls
  Widget _buildModernVideoPlayer() {
    if (_videoPlayerController == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Video player container with rounded corners
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: VideoPlayerService.buildPlayer(
            controller: _videoPlayerController!,
            showProgressIndicator: true,
          ),
        ),
        const SizedBox(height: 16),

        // Modern control panel
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // Video info row
              Row(
                children: [
                  Icon(Icons.video_library, color: teal600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedHymn!.arabicTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: teal900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Play/Pause and Fullscreen buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Play/Pause button
                  _buildVideoControlButton(
                    icon: Icons.play_arrow,
                    label: 'تشغيل',
                    onPressed: () {
                      _videoPlayerController!.play();
                    },
                  ),

                  // Pause button
                  _buildVideoControlButton(
                    icon: Icons.pause,
                    label: 'إيقاف مؤقت',
                    onPressed: () {
                      _videoPlayerController!.pause();
                    },
                  ),

                  // Replay button
                  _buildVideoControlButton(
                    icon: Icons.replay,
                    label: 'إعادة',
                    onPressed: () {
                      _videoPlayerController!.seekTo(Duration.zero);
                    },
                  ),

                  // Fullscreen button
                  _buildVideoControlButton(
                    icon: Icons.fullscreen,
                    label: 'ملء الشاشة',
                    onPressed: () {
                      _videoPlayerController!.toggleFullScreenMode();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info row with icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'اضغط على الفيديو للتحكم',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.hd,
                        size: 16,
                        color: teal600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HD',
                        style: TextStyle(
                          fontSize: 12,
                          color: teal600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build individual video control button
  Widget _buildVideoControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: teal500.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: teal600,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: teal700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build floating audio player bar at the bottom
  Widget _buildFloatingAudioPlayer() {
    if (_selectedHymn == null || _selectedHymn!.audioUrl == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<PlayerState>(
        valueListenable: _audioPlayerService.playerStateNotifier,
        builder: (context, playerState, child) {
          final isCurrentAudio = _audioPlayerService.isCurrentAudio(
            _selectedHymn!.audioUrl!,
          );

          // Always show the floating player if the hymn has an audioUrl

          return Container(
            decoration: BoxDecoration(
              color: teal900,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress slider
                ValueListenableBuilder<Duration>(
                  valueListenable: _audioPlayerService.positionNotifier,
                  builder: (context, position, child) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: _audioPlayerService.durationNotifier,
                      builder: (context, duration, child) {
                        return SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: position.inSeconds.toDouble(),
                            max: duration.inSeconds > 0
                                ? duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (value) async {
                              await _audioPlayerService.seek(
                                Duration(seconds: value.toInt()),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

                // Player controls
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // Hymn info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedHymn!.arabicTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<Duration>(
                              valueListenable:
                                  _audioPlayerService.positionNotifier,
                              builder: (context, position, child) {
                                return ValueListenableBuilder<Duration>(
                                  valueListenable:
                                      _audioPlayerService.durationNotifier,
                                  builder: (context, duration, child) {
                                    return Text(
                                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Control buttons
                      ValueListenableBuilder<bool>(
                        valueListenable: _audioPlayerService.isLoadingNotifier,
                        builder: (context, isLoading, child) {
                          final isPlaying =
                              isCurrentAudio &&
                              playerState == PlayerState.playing;
                          final isPaused =
                              isCurrentAudio &&
                              playerState == PlayerState.paused;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Stop button - only show when audio is loaded
                              if (isCurrentAudio &&
                                  !_audioPlayerService.isStopped)
                                IconButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          await _audioPlayerService.stop();
                                        },
                                  icon: const Icon(Icons.stop),
                                  color: Colors.white,
                                  iconSize: 28,
                                ),

                              // Play/Pause button
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      if (isPlaying) {
                                        await _audioPlayerService.pause();
                                      } else if (isPaused) {
                                        await _audioPlayerService.resume();
                                      } else {
                                        await _audioPlayerService.play(
                                          _selectedHymn!.audioUrl!,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'خطأ في تشغيل الصوت: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                  ),
                                  color: Colors.white,
                                  iconSize: 36,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build FAB with menu for managing hymns (Add, Edit)
  Widget _buildFabMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu options (shown when FAB is tapped)
        if (_isFabMenuOpen) ...[
          // Edit option
          _buildFabMenuItem(
            label: 'تعديل لحن',
            icon: Icons.edit,
            onTap: () {
              setState(() => _isFabMenuOpen = false);
              _showEditHymnDialog();
            },
          ),
          const SizedBox(height: 12),

          // Add option
          _buildFabMenuItem(
            label: 'إضافة لحن جديد',
            icon: Icons.add,
            onTap: () {
              setState(() => _isFabMenuOpen = false);
              _showAddHymnDialog();
            },
          ),
          const SizedBox(height: 16),
        ],

        // Main FAB button
        FloatingActionButton(
          onPressed: () {
            setState(() => _isFabMenuOpen = !_isFabMenuOpen);
          },
          backgroundColor: teal500,
          child: AnimatedRotation(
            turns: _isFabMenuOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isFabMenuOpen ? Icons.close : Icons.menu,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Build individual FAB menu item
  Widget _buildFabMenuItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  color: teal700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: teal700,
          borderRadius: BorderRadius.circular(24),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  /// Show dialog to add a new hymn
  void _showAddHymnDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddHymnScreen(currentUser: _currentUser!)),
    );

    if (result == true && mounted) {
      // Refresh the hymns list if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة اللحن بنجاح'),
          backgroundColor: teal500,
        ),
      );
    }
  }

  /// Show dialog to edit the selected hymn
  void _showEditHymnDialog() async {
    // Pass the currently selected hymn if available, otherwise let user choose in edit screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHymnScreen(initialHymn: _selectedHymn),
      ),
    );

    if (result == true && mounted) {
      // Refresh the hymns list if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث اللحن بنجاح'),
          backgroundColor: teal500,
        ),
      );
    }
  }
}
