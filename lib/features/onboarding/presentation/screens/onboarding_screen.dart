import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to Nuvora',
      subtitle:
          'Build calm momentum every day with a workspace designed for focus, clarity, and progress.',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
    ),
    _OnboardingPageData(
      title: 'Organize your life',
      subtitle:
          'Manage tasks and capture notes in one place so your priorities stay clear and actionable.',
      icon: Icons.dashboard_customize_rounded,
      gradient: [Color(0xFF14B8A6), Color(0xFF0D9488)],
      showFeatureCards: true,
    ),
    _OnboardingPageData(
      title: 'Track your productivity',
      subtitle:
          'See your focus trends, completion rhythm, and progress signals in a clean premium dashboard.',
      icon: Icons.insights_rounded,
      gradient: [Color(0xFFF97316), Color(0xFFEA580C)],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _next() async {
    if (_isLast) {
      widget.onComplete();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onSkip,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(_pages.length, (i) {
                          final selected = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            width: selected ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textTertiary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _next,
                        icon: Icon(_isLast ? Icons.check : Icons.arrow_forward),
                        label: Text(_isLast ? 'Start' : 'Continue'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      child: Column(
        key: ValueKey(data.title),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              gradient: LinearGradient(
                colors: data.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.gradient.last.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, size: 38, color: Colors.white),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  data.title,
                  style: AppTypography.displaySmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (data.showFeatureCards) ...[
            const SizedBox(height: AppSpacing.xl),
            const _FeatureCard(
              icon: Icons.check_circle_outline,
              title: 'Tasks',
              subtitle: 'Prioritize your day with clarity and rhythm.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _FeatureCard(
              icon: Icons.note_alt_outlined,
              title: 'Notes',
              subtitle: 'Capture ideas before they disappear.',
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.showFeatureCards = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool showFeatureCards;
}
