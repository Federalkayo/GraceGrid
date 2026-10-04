import 'package:flutter/material.dart';

class FeatureTileData {
  final String key;
  final String title;
  final String description;
  final String? imageUrl;

  const FeatureTileData({
    required this.key,
    required this.title,
    required this.description,
    this.imageUrl,
  });
}

class FeatureGridTile extends StatefulWidget {
  final FeatureTileData tile;
  final VoidCallback onTap;

  const FeatureGridTile({
    super.key,
    required this.tile,
    required this.onTap,
  });

  @override
  State<FeatureGridTile> createState() => _FeatureGridTileState();
}

class _FeatureGridTileState extends State<FeatureGridTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 100% Offline Custom Visual Artwork
              _buildOfflineVisualArtwork(context, widget.tile.key, isDark),

              // Bottom Overlay Gradient for Crisp Legibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Content & Typography
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.tile.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.tile.description,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineVisualArtwork(BuildContext context, String key, bool isDark) {
    switch (key) {
      case 'bible':
        return _buildBibleArtwork();
      case 'worship':
        return _buildWorshipArtwork();
      case 'connect':
        return _buildConnectArtwork();
      case 'live':
        return _buildLiveArtwork();
      case 'social':
        return _buildSocialArtwork();
      case 'prayer':
        return _buildPrayerArtwork();
      default:
        return _buildBibleArtwork();
    }
  }

  // 📖 DEDICATED HOLY BIBLE VISUAL ARTWORK
  Widget _buildBibleArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A), // Midnight Navy
            Color(0xFF1E3A8A), // Royal Blue
            Color(0xFF2563EB), // GraceGrid Primary Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background ambient light ring
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              ),
            ),
          ),
          // Top pill badge
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.5), width: 1),
              ),
              child: const Text(
                'SCRIPTURE',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Color(0xFFFDE047),
                ),
              ),
            ),
          ),
          // Central Holy Bible Icon Emblem
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 32,
                      color: Color(0xFFFDE047), // Holy Gold
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'HOLY BIBLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎵 WORSHIP ARTWORK
  Widget _buildWorshipArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF311042),
            Color(0xFF5B21B6),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AUDIO',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.music_note_rounded, size: 32, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💬 CONNECT ARTWORK
  Widget _buildConnectArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF064E3B),
            Color(0xFF047857),
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'GROUPS',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_rounded, size: 32, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📡 LIVE ARTWORK
  Widget _buildLiveArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF881337),
            Color(0xFFBE123C),
            Color(0xFFF43F5E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: Color(0xFFE11D48)),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFFBE123C)),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sensors_rounded, size: 32, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👥 SOCIAL ARTWORK
  Widget _buildSocialArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF6366F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'COMMUNITY',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.feed_rounded, size: 32, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🙏 PRAYER ARTWORK
  Widget _buildPrayerArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF78350F),
            Color(0xFFD97706),
            Color(0xFFF59E0B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PRAYER',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded, size: 32, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
