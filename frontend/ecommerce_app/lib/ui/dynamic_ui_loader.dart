import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/core/constants.dart';

// Import all personalized UI layouts
import 'package:ecommerce_app/ui/exploration/exploration_home.dart';
import 'package:ecommerce_app/ui/brand/brand_home.dart';
import 'package:ecommerce_app/ui/price/price_home.dart';
import 'package:ecommerce_app/ui/interaction/interaction_home.dart';
import 'package:ecommerce_app/ui/offer/offer_home.dart';
import 'package:ecommerce_app/ui/premium/premium_home.dart';

/// DynamicUILoader - The core widget that switches UI layouts
/// based on the user's classification type.
///
/// Uses a switch-case on user_type (from Riverpod) to render
/// the appropriate personalized layout. When user_type changes
/// (via WebSocket or reclassification), the UI rebuilds automatically.
class DynamicUILoader extends ConsumerWidget {
  const DynamicUILoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch user type - rebuilds when it changes
    final userType = ref.watch(userTypeProvider);

    // Animate transitions between UI layouts
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildUIForType(userType),
    );
  }

  /// Switch-case to select the appropriate UI layout.
  Widget _buildUIForType(String userType) {
    switch (userType) {
      case AppConstants.typeExploration:
        return const ExplorationHome(key: ValueKey('exploration'));

      case AppConstants.typeBrand:
        return const BrandHome(key: ValueKey('brand'));

      case AppConstants.typePrice:
        return const PriceHome(key: ValueKey('price'));

      case AppConstants.typeInteraction:
        return const InteractionHome(key: ValueKey('interaction'));

      case AppConstants.typeOffer:
        return const OfferHome(key: ValueKey('offer'));

      case AppConstants.typePremium:
        return const PremiumHome(key: ValueKey('premium'));

      default:
        return const ExplorationHome(key: ValueKey('default'));
    }
  }
}
