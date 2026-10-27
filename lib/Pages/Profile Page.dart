import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resourceapp/Pages/Sign In Page.dart';
import 'package:resourceapp/Pages/Sign Up Page.dart';
import 'package:resourceapp/Pages/admin bottom nav.dart';
import 'package:resourceapp/Services/Supabase service.dart';

// All four tiles (Department, Level, Downloads, Delete Account, Log Out)
// share this exact height so their containers line up perfectly.
const double kTileHeight = 70;

class Profile extends StatefulWidget {
  final VoidCallback onBackToHome;
  final VoidCallback? onGoToDownloads;

  const Profile({
    super.key,
    required this.onBackToHome,
    this.onGoToDownloads,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const Color kBackground = Color(0xFFF0ECF9);
  static const Color kPurple = Color(0xFF6A3DF0);
  static const Color kRed = Color(0xFFE23E3E);
  static const Color kTitle = Color(0xFF2D1B69);

  final SupabaseService _service = SupabaseService();

  String _name = '';
  String _email = '';
  String _department = '';
  String _level = '';
  bool _isAdmin = false;
  bool _loadingProfile = true;

  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.getMyProfile();
      if (!mounted) return;
      setState(() {
        _name = (profile?['full_name'] as String?) ?? '';
        _email = _service.currentUserEmail ?? '';
        _department = (profile?['department'] as String?) ?? '';
        _level = (profile?['level'] as String?) ?? '';
        _isAdmin = profile?['role'] == 'admin';
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
    });
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: kPurple),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: kPurple),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: kRed),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: kRed),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: kTitle),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Student Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _name = nameController.text.trim();
                  _email = emailController.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: kPurple, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogOut() async {
    await _service.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignIn()),
      (route) => false,
    );
  }

  Future<void> _handleDeleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: kTitle)),
        content: const Text('This will permanently remove your account. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: kRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _service.deleteAccount();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignUp()),
      (route) => false,
    );
  }

  void _handleSwitchToAdmin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminBottomNav()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 33),

              // Back arrow + title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kTitle),
                    onPressed: widget.onBackToHome,
                  ),
                  const SizedBox(width: 75),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Color(0xD9150054),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Purple profile card: photo + name/email + edit
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(Icons.person, color: kPurple, size: 30)
                                : null,
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 15,
                                color: kPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loadingProfile ? 'Loading...' : (_name.isEmpty ? 'No name set' : _name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                      onPressed: _showEditDialog,
                      icon: _AssetIcon(
                        assetPath: 'assets/images/edit icon.png',
                        size: 20,
                        fallbackIcon: Icons.edit,
                        fallbackColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Department (real data)
              _InfoTile(
                icon: Icons.account_balance,
                title: 'Department',
                subtitle: _department.isEmpty ? '—' : _department,
              ),
              const SizedBox(height: 15),

              // Level (real data)
              _InfoTile(
                assetPath: 'assets/images/materials.png',
                fallbackIcon: Icons.layers,
                title: 'Level',
                subtitle: _level.isEmpty ? '—' : _level,
              ),
              const SizedBox(height: 15),

              // Switch to Admin -> only visible to allowlisted admins
              if (_isAdmin) ...[
                _ActionTile(
                  fallbackIcon: Icons.admin_panel_settings,
                  assetPath: '',
                  title: 'Switch to Admin',
                  titleColor: kPurple,
                  onTap: _handleSwitchToAdmin,
                ),
                const SizedBox(height: 15),
              ],

              // Downloads -> jumps to Files page, Downloads tab
              _ActionTile(
                assetPath: 'assets/images/downloads_purple.png',
                fallbackIcon: Icons.download,
                title: 'Downloads',
                titleColor: kTitle,
                onTap: widget.onGoToDownloads ?? () {},
              ),
              const SizedBox(height: 15),

              // Delete Account
              _ActionTile(
                assetPath: 'assets/images/delete_account_icon.png',
                fallbackIcon: Icons.delete_outline,
                title: 'Delete Account',
                titleColor: kRed,
                onTap: _handleDeleteAccount,
              ),
              const SizedBox(height: 15),

              // Log Out
              _ActionTile(
                assetPath: 'assets/images/logout_icon_red.png',
                fallbackIcon: Icons.logout,
                title: 'Log Out',
                titleColor: kRed,
                onTap: _handleLogOut,
              ),
              const SizedBox(height: 130),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads an asset icon, but falls back to a plain Material icon instead of
/// Flutter's giant red error widget if the asset is missing or misnamed.
/// This is what prevents a bad asset path from ever breaking the layout.
class _AssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const _AssetIcon({
    required this.assetPath,
    required this.size,
    required this.fallbackIcon,
    this.fallbackColor = const Color(0xFF6A3DF0),
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath.isEmpty) {
      return Icon(fallbackIcon, size: size, color: fallbackColor);
    }
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: size, color: fallbackColor);
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final IconData? fallbackIcon;
  final String title;
  final String subtitle;

  const _InfoTile({
    this.icon,
    this.assetPath,
    this.fallbackIcon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kTileHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6A3DF0).withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          assetPath != null
              ? _AssetIcon(
                  assetPath: assetPath!,
                  size: 24,
                  fallbackIcon: fallbackIcon ?? Icons.info_outline,
                )
              : Icon(icon, color: const Color(0xFF6A3DF0), size: 24),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF150054).withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF150054).withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final String title;
  final Color titleColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.assetPath,
    required this.fallbackIcon,
    required this.title,
    required this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: kTileHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECF9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF6A3DF0).withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _AssetIcon(
              assetPath: assetPath,
              size: 24,
              fallbackIcon: fallbackIcon,
              fallbackColor: titleColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: titleColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: titleColor),
          ],
        ),
      ),
    );
  }
}