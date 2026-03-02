import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';

/// Main app shell with bottom navigation bar.
/// Adapts styling based on user type.
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userType = ref.watch(userTypeProvider);
    final accentColor = AppTheme.getAccentColor(userType);
    final isPremium = userType == 'premium';

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: accentColor.withValues(alpha: 0.2),
        backgroundColor: isPremium ? AppTheme.premiumSurface : null,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined,
                color: isPremium ? Colors.white54 : null),
            selectedIcon: Icon(Icons.home, color: accentColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined,
                color: isPremium ? Colors.white54 : null),
            selectedIcon: Icon(Icons.shopping_cart, color: accentColor),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline,
                color: isPremium ? Colors.white54 : null),
            selectedIcon: Icon(Icons.person, color: accentColor),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/cart');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
