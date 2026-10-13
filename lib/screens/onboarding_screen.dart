import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../widgets/journal_components.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: JournalCanvas(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 80,
                      height: 80,
                      semanticLabel: 'Mindful Journal mark',
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'A little space\nfor yourself.',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Notice how you feel. Write what matters.\nReturn to the moments that make you, you.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.slow,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reflect · Make space for what is on your mind.',
                        style: TextStyle(color: Colors.white, height: 1.6),
                      ),
                      Text(
                        'Notice · See patterns in how you feel.',
                        style: TextStyle(color: Colors.white, height: 1.6),
                      ),
                      Text(
                        'Remember · Return to moments worth keeping.',
                        style: TextStyle(color: Colors.white, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.indigo,
                  ),
                  onPressed: onGetStarted,
                  child: const Text('Get Started'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mindful Journal · Saved locally on this device.',
                  style: TextStyle(color: Colors.white, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
