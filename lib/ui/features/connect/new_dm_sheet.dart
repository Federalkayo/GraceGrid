import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/services/profile_service.dart';
import '../../core/theme/app_colors.dart';

/// Bottom sheet that lets a signed-in user search for other GraceGrid
/// members and start a new 1-to-1 conversation.
///
/// Returns the selected [ProfileData] or null if dismissed.
class NewDmSheet extends StatefulWidget {
  const NewDmSheet({super.key});

  @override
  State<NewDmSheet> createState() => _NewDmSheetState();
}

class _NewDmSheetState extends State<NewDmSheet> {
  final _searchController = TextEditingController();
  List<ProfileData> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await ProfileService.instance.searchProfiles(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? AppColors.primaryBlueDark : AppColors.primaryBlueLight;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceElevated =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'New Conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textPrimary),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(fontSize: 14, color: textSecondary),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: textSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Flexible(
            child: _loading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: primaryBlue, strokeWidth: 2),
                    ),
                  )
                : _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Type a name to find members'
                              : 'No members found',
                          style:
                              TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final profile = _results[index];
                          return _buildProfileTile(
                            profile,
                            primaryBlue,
                            textPrimary,
                            textSecondary,
                            border,
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProfileTile(
    ProfileData profile,
    Color primaryBlue,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => Navigator.pop(context, profile),
        leading: CircleAvatar(
          backgroundColor: primaryBlue,
          backgroundImage: profile.avatarUrl.isNotEmpty
              ? NetworkImage(profile.avatarUrl)
              : null,
          child: profile.avatarUrl.isEmpty
              ? Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          profile.displayName.isNotEmpty ? profile.displayName : 'User',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: profile.bio.isNotEmpty
            ? Text(
                profile.bio,
                style: TextStyle(fontSize: 12, color: textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(Icons.chat_bubble_outline_rounded,
            size: 18, color: primaryBlue),
      ),
    );
  }
}
