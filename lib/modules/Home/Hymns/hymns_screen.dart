import 'package:audioplayers/audioplayers.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/hymn_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/audio_player_service.dart';
import '../../../core/services/hymns_service.dart';
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
  HymnModel? _selectedHymn;
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
    } catch (e) {
      debugPrint('Error loading user class: $e');
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

                      if (hymns.isEmpty) {
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
                              key: ValueKey(
                                _selectedHymn?.id ?? 'no_selection',
                              ),
                              initialValue: _selectedHymn?.id,
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
                              items: hymns.map((hymn) {
                                return DropdownMenuItem<String>(
                                  value: hymn.id,
                                  child: Text(
                                    hymn.arabicTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedHymn = hymns.firstWhere(
                                      (hymn) => hymn.id == newValue,
                                    );
                                  });
                                }
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: teal500,
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
                // Occasion Chip
                if (_selectedHymn!.occasion != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Chip(
                      label: Text(_selectedHymn!.occasion!),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: teal500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
                          ),
                        ),

                      // English Column with left and right borders
                      if (hasEnglish)
                        Expanded(
                          child: _buildLyricsColumn(
                            title: 'English',
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
                          title: 'الكلمات بالقبطية',
                          lyrics: _selectedHymn!.copticLyrics!,
                        ),

                      // English Lyrics
                      if (_selectedHymn!.copticArlyrics != null &&
                          _selectedHymn!.copticArlyrics!.isNotEmpty)
                        _buildLyricsSection(
                          title: 'Lyrics in English',
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
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: teal900,
                    letterSpacing: 0.3,
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
  Widget _buildLyricsSection({required String title, required String lyrics}) {
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
          style: TextStyle(
            fontSize: 16,
            height: 1.8,
            color: teal900,
            letterSpacing: 0.3,
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
      MaterialPageRoute(builder: (context) => const AddHymnScreen()),
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
