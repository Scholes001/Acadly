import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/Home Page.dart';
import 'package:resourceapp/Pages/Resources Page.dart';
import 'package:resourceapp/Pages/Files Page.dart';
import 'package:resourceapp/Pages/Profile Page.dart';

class BottomNav extends StatefulWidget {
  /// Which tab to land on when this BottomNav is first built. Defaults
  /// to Home (0). Pass 3 to land directly on Profile — e.g. when the
  /// admin side switches back to the student shell.
  final int initialIndex;

  const BottomNav({super.key, this.initialIndex = 0});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int _selectedIndex;

  // Which tab Files should open on next time it's shown. Changed only when
  // Profile's "Downloads" tile is tapped.
  FilesTab _filesInitialTab = FilesTab.recentlyOpened;

  static const Color _activeColor = Color(0xFF6A3DF0);

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home, label: 'Home'),
    _NavItem(assetPath: "assets/images/materials.png", label: 'Resources'),
    _NavItem(icon: Icons.description, label: 'Files'),
    _NavItem(icon: Icons.person, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // A getter instead of `late final` so it rebuilds when _filesInitialTab
  // changes, letting Profile jump straight into Files' Downloads tab.
  List<Widget> get _pages => [
        const Home(),
        Resources(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        ),
        Files(
          key: ValueKey(_filesInitialTab),
          initialTab: _filesInitialTab,
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        ),
        Profile(
          onBackToHome: () => setState(() => _selectedIndex = 0),
          onGoToDownloads: () {
            setState(() {
              _filesInitialTab = FilesTab.downloads;
              _selectedIndex = 2; // Files tab's position in _navItems
            });
          },
        ),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
          color: const Color(0xFFF0ECF9), // 100% opacity base
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

            final Color color = isSelected
                ? _activeColor.withOpacity(0.95)
                : const Color(0xFF6A3DF0).withOpacity(0.50);

            return GestureDetector(
              onTap: () => _onItemTapped(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  item.assetPath != null
                      ? Image.asset(
                          item.assetPath!,
                          width: 24,
                          height: 24,
                          color: color,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.layers, color: color, size: 24);
                          },
                        )
                      : Icon(item.icon, color: color),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData? icon;
  final String? assetPath;
  final String label;

  _NavItem({this.icon, this.assetPath, required this.label});
}