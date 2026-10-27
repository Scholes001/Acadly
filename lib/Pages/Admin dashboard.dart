import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/admin upload.dart';
import 'package:resourceapp/Pages/admin materials.dart';
import 'package:resourceapp/Pages/Bottom Nav.dart';import 'package:resourceapp/Services/Supabase service.dart';

class Admindashboard extends StatefulWidget {
  /// If Admindashboard is one of AdminBottomNav's IndexedStack pages,
  /// pass these so the two action tiles switch tabs directly instead of
  /// pushing a new full-screen route (same pattern as Upload/Materials'
  /// onBack). If left null, each tile falls back to a normal push.
  final VoidCallback? onGoToUpload;
  final VoidCallback? onGoToMaterials;

  const Admindashboard({super.key, this.onGoToUpload, this.onGoToMaterials});

  @override
  State<Admindashboard> createState() => _AdmindashboardState();
}

class _AdmindashboardState extends State<Admindashboard> {
  // Colors — same palette as Home
  static const Color kBackground = Color(0xFFF0ECF9); // 100% opacity
  final Color kPurpleWithOpacity = const Color(0xFF6A3DF0).withOpacity(0.95);
  static const Color kTextColor = Color(0xD9150054);

  final SupabaseService _service = SupabaseService();
  String _name = '';
  String _department = '';
  String _level = '';
  int _totalMaterials = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTotalMaterials();
  }

  Future<void> _loadProfile() async {
    final profile = await _service.getMyProfile();
    if (!mounted) return;
    setState(() {
      _name = (profile?['full_name'] as String?) ?? '';
      _department = (profile?['department'] as String?) ?? '';
      _level = (profile?['level'] as String?) ?? '';
    });
  }

  Future<void> _loadTotalMaterials() async {
    final count = await _service.totalMaterialsCount();
    if (!mounted) return;
    setState(() => _totalMaterials = count);
  }

  void _switchToStudent() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const BottomNav(initialIndex: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text(
                      'Admin Dashboard',
                      style: TextStyle(
                           fontSize: 26,
                        fontWeight: FontWeight.w600,
                         color: Color(0xD9150054),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz, color: kTextColor),
                      tooltip: 'Switch to Student',
                      onPressed: _switchToStudent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Welcome purple card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPurpleWithOpacity,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shrinks slightly if needed so "(Admin)" stays on the same line
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Welcome, ${_name.isEmpty ? '...' : _name}! (Admin)',
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_department.isEmpty ? '—' : _department} Department',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _level.isEmpty ? '—' : _level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Logo, centered in the empty space beside the text
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Image.asset(
                          'assets/images/acad.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Stat cards row: Course Materials / Total Materials
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatCard(
                      assetPath: 'assets/images/layers_transparent (1).png',
                      title: 'Course\nMaterials',
                      subtitle: '(100-500 Level)',
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _StatCard(
                      assetPath: 'assets/images/layers.png',
                      title: 'Total\nMaterials',
                      value: '$_totalMaterials',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Department Levels title
              const Text(
                'Department Levels',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                 color: Color(0xD9150054),
                ),
              ),
              const SizedBox(height: 10),

              // Department levels chips (3 per row, then remaining 2)
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _LevelChip(label: '100 Level', onTap: () {}),
                  _LevelChip(label: '200 Level', onTap: () {}),
                  _LevelChip(label: '300 Level', onTap: () {}),
                  _LevelChip(label: '400 Level', onTap: () {}),
                  _LevelChip(label: '500 Level', onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),

              // Upload Materials action tile
              _ActionTile(
                assetPath: 'assets/images/upload_material.png',
                title: 'Upload Materials',
                subtitle: 'Add New Course Materials',
                onTap: () {
                  if (widget.onGoToUpload != null) {
                    widget.onGoToUpload!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Upload()),
                    );
                  }
                },
              ),
              const SizedBox(height: 13),

              // Manage Materials action tile
              _ActionTile(
                assetPath: 'assets/images/manage_materials2.png',
                title: 'Manage Materials',
                subtitle: 'View, edit or delete Materials',
                onTap: () {
                  if (widget.onGoToMaterials != null) {
                    widget.onGoToMaterials!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Materials()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top stat card — icon beside the title, matching the Figma layout.
/// Fixed height so both cards line up exactly, regardless of content.
class _StatCard extends StatelessWidget {
  final String assetPath;
  final String title;
  final String? subtitle;
  final String? value;

  const _StatCard({
    required this.assetPath,
    required this.title,
    this.subtitle,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECF9), // same as page background
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 25,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 40, height: 44),
            const SizedBox(width: 7),
        
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.15,
                      color: Color(0xD9150054),
                    ),
                  ),
                  subtitle != null
                      ? Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xD9150054),
                          ),
                        )
                      : Text(
                          value ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xD9150054),
                          ),
                        ),
                ],
              ),
            
          ],
        ),
      ),
    );
  }
}

/// Full-width row action button — Upload Materials / Manage Materials.
class _ActionTile extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECF9), // same as page background
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 25,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 28, height: 28),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xD9150054),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xD9150054),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LevelChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECF9), // same as page background
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 25,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/layers_transparent (1).png',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xD9150054),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}