import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/screens/onboarding_page.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      onGuest: () => context.go('/home'),
    );
  }
}
