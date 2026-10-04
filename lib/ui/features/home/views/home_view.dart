import 'package:flutter/material.dart';
import 'package:gracegride2/ui/features/home/view_models/home_view_model.dart';
import 'package:gracegride2/ui/core/widgets/notifications_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/welcome_section.dart';
import 'widgets/feature_grid_tile.dart';

class HomeView extends StatelessWidget {
  final HomeViewModel viewModel;
  final Function(String feature) onNavigateToFeature;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeView({
    super.key,
    required this.viewModel,
    required this.onNavigateToFeature,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  static const List<FeatureTileData> _tiles = [
    FeatureTileData(
      key: 'bible',
      title: 'Bible',
      description: 'Read and study Scripture',
    ),
    FeatureTileData(
      key: 'worship',
      title: 'Worship',
      description: 'Listen to sermons & worship',
    ),
    FeatureTileData(
      key: 'connect',
      title: 'Connect',
      description: 'Messages, groups & calls',
    ),
    FeatureTileData(
      key: 'live',
      title: 'Live',
      description: 'Watch active broadcasts',
    ),
    FeatureTileData(
      key: 'social',
      title: 'Social',
      description: 'Join community discussions',
    ),
    FeatureTileData(
      key: 'prayer',
      title: 'Prayer',
      description: 'Share & join in prayer',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                HomeHeader(
                  userProfile: viewModel.userProfile,
                  onTapProfile: () => onNavigateToFeature('more'),
                  onTapNotifications: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const NotificationsSheet(),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Welcome Section
                WelcomeSection(
                  isSignedIn: viewModel.isSignedIn,
                  userName: viewModel.userProfile.name,
                ),

                const SizedBox(height: 16),

                // 2-Column Visual Feature Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _tiles.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final tile = _tiles[index];
                        return FeatureGridTile(
                          tile: tile,
                          onTap: () => onNavigateToFeature(tile.key),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
