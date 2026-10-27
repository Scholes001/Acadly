import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/Resources Page.dart';

/// Admin's "Materials" tab. Rather than duplicating the semester toggle,
/// level list, course grid and course-detail screens, this just reuses
/// the exact same Resources -> Level1..5 -> CourseDetail flow that's
/// already built for the student side — they're generic widgets, not
/// tied to any student-only logic.
class Materials extends StatelessWidget {
  /// If Materials is one of AdminBottomNav's IndexedStack pages, pass a
  /// callback here so the back arrow switches tabs instead of trying to
  /// pop a route that was never pushed (same pattern as Upload).
  final VoidCallback? onBack;

  const Materials({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Resources(
      onBackToHome: onBack ?? () => Navigator.pop(context),
      title: 'Manage Materials',
      showMaterialsCount: true,
      isAdmin: true,
    );
  }
}