import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/Admin dashboard.dart';
import 'package:resourceapp/Pages/admin upload.dart';
import 'package:resourceapp/Pages/admin materials.dart';

class AdminBottomNav extends StatefulWidget {
  const AdminBottomNav({super.key});

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  int _selectedIndex = 0;

  // Bumped every time Dashboard/Materials become the active tab, so
  // they're given a fresh Key each time -> Flutter remounts them ->
  // initState reruns -> counts refetch. This is what makes the Admin
  // Dashboard total and the Materials level counts "reflect quickly"
  // after an upload, edit or delete.
  int _dashboardRefreshKey = 0;
  int _materialsRefreshKey = 0;

  static const Color _activeColor = Color(0xFF6A3DF0);

  final List<_NavItem> _navItems = [
    _NavItem(assetPath: "assets/images/dashboard.png", label: 'Dashboard'),
    _NavItem(assetPath: "assets/images/upload_cloud2.png", label: 'Upload'),
    _NavItem(assetPath: "assets/images/materials_book2.png", label: 'Materials'),
  ];

  List<Widget> get _pages => [
        Admindashboard(
          key: ValueKey('dashboard-$_dashboardRefreshKey'),
          onGoToUpload: () => _onItemTapped(1),
          onGoToMaterials: () => _onItemTapped(2),
        ),
        Upload(onBack: () => _onItemTapped(0)),
        Materials(
          key: ValueKey('materials-$_materialsRefreshKey'),
          onBack: () => _onItemTapped(0),
        ),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _dashboardRefreshKey++;
      if (index == 2) _materialsRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECF9),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB3ADBF).withOpacity(0.66),
              offset: const Offset(0, 4),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final bool isSelected = _selectedIndex == index;
            final _NavItem item = _navItems[index];

            return GestureDetector(
              onTap: () => _onItemTapped(index),
              behavior: HitTestBehavior.opaque,
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      item.assetPath,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.layers, color: _activeColor, size: 24);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? _activeColor : const Color(0xFF6A3DF0),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final String assetPath;
  final String label;

  _NavItem({required this.assetPath, required this.label});
}