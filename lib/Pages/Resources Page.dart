import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/100level.dart';
import 'package:resourceapp/Pages/200level.dart';
import 'package:resourceapp/Pages/300level.dart';
import 'package:resourceapp/Pages/500level.dart';
import 'package:resourceapp/Pages/400level.dart';
import 'package:resourceapp/Services/Supabase service.dart';
import 'package:resourceapp/Services/route observer.dart';

enum Semester { first, second }

class Resources extends StatefulWidget {
  final VoidCallback onBackToHome;
  final String title;
  final bool showMaterialsCount;
  /// When true, drills into CourseDetail in admin mode (edit/delete
  /// instead of open/download). Set by admin materials.dart.
  final bool isAdmin;
  const Resources({
    super.key,
    required this.onBackToHome,
    this.title = 'Course Materials',
    this.showMaterialsCount = false,
    this.isAdmin = false,
  });

  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources> with RouteAware {
  static const Color kBackground = Color(0xFFF0ECF9);
  static const Color kPurple = Color(0xFF6A3DF0);

  Semester _selectedSemester = Semester.first;
  final SupabaseService _service = SupabaseService();

  // Real materials count per level, for the currently selected semester.
  // Key = level (100..500). Refetched whenever the semester toggle changes.
  Map<int, int> _materialsCounts = {};

  // Course counts per level, per semester.
  static const Map<int, Map<Semester, int>> _courseCounts = {
    100: {Semester.first: 11, Semester.second: 9},
    200: {Semester.first: 8, Semester.second: 9},
    300: {Semester.first: 10, Semester.second: 9},
    400: {Semester.first: 10, Semester.second: 3},
    500: {Semester.first: 8, Semester.second: 8},
  };

  @override
  void initState() {
    super.initState();
    if (widget.showMaterialsCount) {
      _loadMaterialsCounts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called automatically when a route pushed on top of Resources
  /// (Level -> CourseDetail) is popped back to Resources — e.g. right
  /// after an admin deletes/edits a material deep in that flow. This
  /// is what makes the "X Materials" counts refresh without needing
  /// to leave and re-enter the Materials tab.
  @override
  void didPopNext() {
    if (widget.showMaterialsCount) {
      _loadMaterialsCounts();
    }
  }

  Future<void> _loadMaterialsCounts() async {
    final String semesterString =
        _selectedSemester == Semester.first ? 'First Semester' : 'Second Semester';

    final Map<int, int> counts = {};
    for (final level in _courseCounts.keys) {
      final levelString = '$level Level';
      counts[level] = await _service.materialsCountForLevel(
        level: levelString,
        semester: semesterString,
      );
    }
    if (!mounted) return;
    setState(() => _materialsCounts = counts);
  }

  int _coursesFor(int level) {
    return _courseCounts[level]![_selectedSemester]!;
  }

  void _openLevel(int level) {
    Widget page;
    switch (level) {
      case 100:
        page = Level1(initialSemester: _selectedSemester, isAdmin: widget.isAdmin);
        break;
      case 200:
        page = Level2(initialSemester: _selectedSemester, isAdmin: widget.isAdmin);
        break;
      case 300:
        page = Level3(initialSemester: _selectedSemester, isAdmin: widget.isAdmin);
        break;
      case 400:
        page = Level4(initialSemester: _selectedSemester, isAdmin: widget.isAdmin);
        break;
      case 500:
        page = Level5(initialSemester: _selectedSemester, isAdmin: widget.isAdmin);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 38),

            // Back arrow + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2D1B69)),
                    onPressed: widget.onBackToHome,
                  ),
                  const SizedBox(width: 35),
                  Text(
                    widget.title,
                    style: const TextStyle(
                     fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Color(0xD9150054),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),

            // Semester toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: kPurple.withOpacity(0.17),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: _semesterTab('First Semester', Semester.first)),
                    Expanded(child: _semesterTab('Second Semester', Semester.second)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Level list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  for (final level in _courseCounts.keys) ...[
                    _LevelTile(
                      level: level,
                      courses: _coursesFor(level),
                      showMaterialsCount: widget.showMaterialsCount,
                      materialsCount: _materialsCounts[level] ?? 0,
                      onTap: () => _openLevel(level),
                    ),
                    const SizedBox(height: 19),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _semesterTab(String label, Semester semester) {
    final bool isSelected = _selectedSemester == semester;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSemester = semester);
        if (widget.showMaterialsCount) {
          _loadMaterialsCounts();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? kPurple.withOpacity(0.95) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
           color: isSelected
                ? Colors.white
                : const Color(0xFF150054).withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int level;
  final int courses;
  final bool showMaterialsCount;
  final int materialsCount;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.courses,
    required this.onTap,
    this.showMaterialsCount = false,
    this.materialsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        decoration: BoxDecoration(
          color: const Color(0xFFE9DFFF).withOpacity(0.20),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF6A3DF0).withOpacity(0.40),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/layers.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.layers, color: Color(0xFF6A3DF0), size: 26);
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$level Level',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2D1B69),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$courses Course${courses == 1 ? '' : 's'}'
                    '${showMaterialsCount ? '   $materialsCount Materials' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                       color: Color(0xFF2D1B69),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,  color: Color(0xFF2D1B69),)
          ],
        ),
      ),
    );
  }
}