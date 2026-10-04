import 'package:flutter/material.dart';

import '../screens/explore_screen.dart';
import '../screens/home_screen.dart';
import '../screens/my_helps_screen.dart';
import '../screens/my_requests_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _changePage(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final screens = [
      HomeScreen(
        onExploreTap: () {
          _changePage(1);
        },
      ),
      const ExploreScreen(),
      const MyHelpsScreen(),
      MyRequestsScreen(
        onGoHomeRequested: () {
          _changePage(0);
        },
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 62 + bottomPadding,
        padding: EdgeInsets.only(
          bottom: bottomPadding,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            _NavigationItem(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              selected: _currentIndex == 0,
              onTap: () => _changePage(0),
            ),
            _NavigationItem(
              label: 'Explorar',
              icon: Icons.explore_outlined,
              selectedIcon: Icons.explore,
              selected: _currentIndex == 1,
              onTap: () => _changePage(1),
            ),
            _NavigationItem(
              label: 'Ajudas',
              icon: Icons.volunteer_activism_outlined,
              selectedIcon: Icons.volunteer_activism_rounded,
              selected: _currentIndex == 2,
              onTap: () => _changePage(2),
            ),
            _NavigationItem(
              label: 'Pedidos',
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment,
              selected: _currentIndex == 3,
              onTap: () => _changePage(3),
            ),
            _NavigationItem(
              label: 'Perfil',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              selected: _currentIndex == 4,
              onTap: () => _changePage(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 21,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9.5,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}