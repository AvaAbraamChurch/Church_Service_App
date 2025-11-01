import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/models/user/user_model.dart';
import '../core/styles/colors.dart';

class AvatarDisplayWidget extends StatefulWidget {
  // Accept either a full UserModel or just an imageUrl/name for more flexible usage
  final UserModel? user;
  final String? imageUrl; // network image fallback when user is not provided
  final String? name; // fallback name when user is not provided
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const AvatarDisplayWidget({
    super.key,
    this.user,
    this.imageUrl,
    this.name,
    this.size = 120,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 3,
  });

  @override
  State<AvatarDisplayWidget> createState() => _AvatarDisplayWidgetState();
}

class _AvatarDisplayWidgetState extends State<AvatarDisplayWidget> {
  String? _avatarSvg;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatarIfExists();
  }

  @override
  void didUpdateWidget(AvatarDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload avatar if user changes or avatar data changes
    final oldAvatar = oldWidget.user?.avatar;
    final newAvatar = widget.user?.avatar;
    if (oldAvatar != newAvatar) {
      _loadAvatarIfExists();
    }
  }

  Future<void> _loadAvatarIfExists() async {
    final avatarString = widget.user?.avatar;
    if (avatarString != null && avatarString.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      final fluttermoji = FluttermojiFunctions();

      try {
        // Decode the Fluttermoji string to SVG using the package's decode function
        // (use the top-level function exported by the package)
        final String svgString = fluttermoji.decodeFluttermojifromString(avatarString);
        if (mounted) {
          setState(() {
            _avatarSvg = svgString;
            _isLoading = false;
          });
        }
      } catch (e) {
        // If decoding fails, clear avatar and stop loading
        // ignore: avoid_print
        print('Error loading avatar: $e');
        if (mounted) {
          setState(() {
            _avatarSvg = null;
            _isLoading = false;
          });
        }
      }
    } else {
      // No avatar present — ensure loading flag is false and svg cleared
      if (mounted) {
        setState(() {
          _avatarSvg = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ?? teal300;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: widget.showBorder
            ? Border.all(color: effectiveBorderColor, width: widget.borderWidth)
            : null,
        boxShadow: widget.showBorder
            ? [
                BoxShadow(
                  // use withValues to match project color extension
                  color: effectiveBorderColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: Colors.grey[800],
        child: ClipOval(
          child: _buildAvatarContent(),
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Priority 1: Check if network image exists (from user or provided imageUrl)
    final networkImageUrl = widget.user?.profileImageUrl ?? widget.imageUrl;
    if (networkImageUrl != null && networkImageUrl.isNotEmpty) {
      return Image.network(
        networkImageUrl,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If network image fails, fall back to avatar or asset
          return _buildAvatarOrAsset();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: teal300,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    // Priority 2 & 3: Check avatar or use asset/initials
    return _buildAvatarOrAsset();
  }

  Widget _buildAvatarOrAsset() {
    // Priority 2: Check if custom avatar SVG exists
    if (_avatarSvg != null && _avatarSvg!.isNotEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        color: Colors.white,
        child: SvgPicture.string(
          _avatarSvg!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => _buildLoadingOrInitials(),
        ),
      );
    }

    // Show loading indicator while decoding avatar
    if (_isLoading) {
      return _buildLoadingOrInitials();
    }

    // Priority 3: Display first letter of fullName or provided name
    return _buildInitialsAvatar();
  }

  Widget _buildLoadingOrInitials() {
    return Center(
      child: CircularProgressIndicator(
        color: teal300,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    // Get first letter of name
    final displayName = (widget.user?.fullName ?? widget.name ?? '').trim();
    String initials = '';
    if (displayName.isNotEmpty) {
      initials = displayName[0].toUpperCase();
    }

    // Generate a color based on the user's name for consistency
    final colorIndex = (displayName.hashCode.abs()) % _avatarColors.length;
    final backgroundColor = _avatarColors[colorIndex];

    return Container(
      width: widget.size,
      height: widget.size,
      color: backgroundColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4, // 40% of avatar size
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Color palette for initials avatars
  static const List<Color> _avatarColors = [
    Color(0xFF1abc9c), // Turquoise
    Color(0xFF2ecc71), // Emerald
    Color(0xFF3498db), // Blue
    Color(0xFF9b59b6), // Amethyst
    Color(0xFF34495e), // Wet Asphalt
    Color(0xFF16a085), // Green Sea
    Color(0xFF27ae60), // Nephritis
    Color(0xFF2980b9), // Belize Hole
    Color(0xFF8e44ad), // Wisteria
    Color(0xFFf39c12), // Orange
    Color(0xFFd35400), // Pumpkin
    Color(0xFFc0392b), // Pomegranate
    Color(0xFFe74c3c), // Alizarin
    Color(0xFFe67e22), // Carrot
  ];
}
