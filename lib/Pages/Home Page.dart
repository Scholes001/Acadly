import 'package:flutter/material.dart';
import 'package:resourceapp/Services/Supabase service.dart';

// >>> Adjust these to resize the Resources cards (Course Materials, PDFs,
// Uploaded Videos, Past Questions) <<<
const double kCardWidth = 153;
const double kCardHeight = 85;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Colors
  static const Color kBackground = Color(0xFFF0ECF9); // 100% opacity
  final Color kPurpleWithOpacity = const Color(0xFF6A3DF0).withOpacity(0.95);

  final SupabaseService _service = SupabaseService();
  String _name = '';
  String _department = '';
  String _level = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Center(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                     color: Color(0xD9150054),
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                          Text(
                            'Welcome, ${_name.isEmpty ? '...' : _name}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_department.isEmpty ? '—' : _department}\nDepartment',
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
              const SizedBox(height: 23),

              // Resources title
              const Text(
                'Resources',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                 color: Color(0xD9150054),
                ),
              ),
              const SizedBox(height: 13),

              // Resources grid (2x2), each card fixed at kCardWidth x kCardHeight
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ResourceCard(
                    assetPath: 'assets/images/materials.png',
                    title: 'Course Materials',
                    subtitle: '(100-500 Level)',
                    onTap: () {},
                  ),
                  _ResourceCard(
                    assetPath: 'assets/images/pdf icon.png',
                    title: 'PDFs and Notes',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ResourceCard(
                    assetPath: 'assets/images/video icon.png',
                    title: 'Uploaded Videos',
                    onTap: () {},
                  ),
                  _ResourceCard(
                    assetPath: 'assets/images/past questions icon.png',
                    title: 'Past Questions',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // Department Levels title
              const Text(
                'Department Levels',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                 color: Color(0xD9150054),
                ),
              ),
              const SizedBox(height: 13),

              // Department levels chips (3 per row, then remaining 2)
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.3,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final String assetPath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.assetPath,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: kCardWidth,
        height: kCardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            Image.asset(assetPath, width: 45, height: 45),
            const SizedBox(width:5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xD9150054),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xD9150054),
                      ),
                    ),
                  ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              'assets/images/materials.png',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
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