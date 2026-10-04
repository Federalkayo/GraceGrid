import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/auth_notifier.dart';
import '../../../data/services/profile_service.dart';

/// Profile editing screen matching the GraceGrid design system.
///
/// Allows authenticated users to view/update their display name, bio, and profile picture.
class ProfileScreen extends StatefulWidget {
  final AuthNotifier authNotifier;

  const ProfileScreen({super.key, required this.authNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  bool _saving = false;
  bool _uploadingImage = false;
  File? _pickedImageFile;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = widget.authNotifier.userProfile;
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close sheet
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _pickedImageFile = file;
        _uploadingImage = true;
        _errorMessage = null;
        _successMessage = null;
      });

      final uploadedUrl = await ProfileService.instance.uploadAvatar(file);

      if (!mounted) return;

      if (uploadedUrl != null) {
        widget.authNotifier.updateProfile(avatarUrl: uploadedUrl);
        setState(() {
          _uploadingImage = false;
          _successMessage = 'Profile picture updated!';
        });
      } else {
        setState(() {
          _uploadingImage = false;
          _errorMessage =
              'Failed to upload profile picture. Ensure storage bucket policy allows uploads.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
        _errorMessage = 'Error selecting image: $e';
      });
    }
  }

  void _showImagePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from Gallery'),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take a Photo'),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Display name cannot be empty.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final ok = await ProfileService.instance.updateProfile(
      displayName: name,
      bio: _bioController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      widget.authNotifier.updateProfile(
        displayName: name,
        bio: _bioController.text.trim(),
      );
      setState(() {
        _saving = false;
        _successMessage = 'Profile updated!';
      });
    } else {
      setState(() {
        _saving = false;
        _errorMessage = 'Failed to update profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final profile = widget.authNotifier.userProfile;

    ImageProvider? avatarImage;
    if (_pickedImageFile != null) {
      avatarImage = FileImage(_pickedImageFile!);
    } else if (profile.avatarUrl.isNotEmpty) {
      avatarImage = NetworkImage(profile.avatarUrl);
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar picker
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadingImage ? null : _showImagePickerModal,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: primaryBlue,
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? Text(
                                  profile.name.isNotEmpty
                                      ? profile.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                                )
                              : null,
                        ),
                        if (_uploadingImage)
                          Container(
                            width: 92,
                            height: 92,
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: surfaceColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _uploadingImage ? null : _showImagePickerModal,
                    child: Text(
                      'Change Profile Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  Text(
                    profile.email,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Success message
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_successMessage!,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.green)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFEF4444))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Display Name
            Text('Display Name',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _nameController,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Your display name',
                  hintStyle:
                      TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  prefixIcon: Icon(Icons.person_outline,
                      size: 18, color: textSecondary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bio
            Text('Bio',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 200,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Tell the community a little about yourself...',
                  hintStyle:
                      TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: TextStyle(color: textSecondary, fontSize: 11),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_saving || _uploadingImage) ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

