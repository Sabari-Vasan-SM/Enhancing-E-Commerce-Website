import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';

/// Profile screen showing user info and current classification.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userType = ref.watch(userTypeProvider);
    final accentColor = AppTheme.getAccentColor(userType);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        if (user == null) return const SizedBox();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: accentColor,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName ?? user.username,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(user.email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),

                // User Type Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Shopping Personality',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getUserTypeLabel(userType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getUserTypeDescription(userType),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: user.userTypeConfidence,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(user.userTypeConfidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu items
                _buildMenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.favorite_outline,
                  title: 'Wishlist',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.analytics_outlined,
                  title: 'My Analytics',
                  subtitle: 'See your shopping patterns',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.refresh,
                  title: 'Reclassify Me',
                  subtitle: 'Update your shopping personality',
                  onTap: () async {
                    final api = ref.read(apiServiceProvider);
                    try {
                      final result = await api.reclassify();
                      ref.read(userTypeProvider.notifier).state =
                          result['user_type'];
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Updated to: ${_getUserTypeLabel(result['user_type'])}'),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getUserTypeLabel(String type) {
    switch (type) {
      case 'exploration':
        return 'Explorer';
      case 'brand':
        return 'Brand Loyalist';
      case 'price':
        return 'Smart Saver';
      case 'interaction':
        return 'Active Shopper';
      case 'offer':
        return 'Deal Hunter';
      case 'premium':
        return 'Premium Connoisseur';
      default:
        return 'Explorer';
    }
  }

  String _getUserTypeDescription(String type) {
    switch (type) {
      case 'exploration':
        return 'You love discovering new categories and products';
      case 'brand':
        return 'You prefer trusted brands you know and love';
      case 'price':
        return 'You find the best value for your money';
      case 'interaction':
        return 'You are highly engaged and browse extensively';
      case 'offer':
        return 'You never miss a great deal or sale';
      case 'premium':
        return 'You appreciate quality and premium products';
      default:
        return 'Your personalized shopping experience';
    }
  }
}
