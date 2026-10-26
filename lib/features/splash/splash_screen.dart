import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_emblem.dart';
import '../../core/widgets/ornaments.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldNight,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF155440),
              Color(0xFF0A3529),
              Color(0xFF05201A),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: const IslamicPatternPainter(
                  color: Color(0x1AC6A664),
                  cell: 108,
                ),
              ),
            ),
            Positioned(
              left: -40,
              right: -40,
              top: 60,
              bottom: 60,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.16,
                  child: MihrabArch(
                    color: AppColors.gold,
                    strokeWidth: 1.4,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandEmblem(size: 148, glow: true),
                          const SizedBox(height: 34),
                          const Text(
                            'Werenga',
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontSize: 54,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              color: AppColors.ivory,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "QUR'AN  ·  CHICHEWA",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3.4,
                              color: AppColors.goldBright.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          const SizedBox(
                            width: 190,
                            child: ArabesqueDivider(
                              color: AppColors.gold,
                              starSize: 11,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Listen to the recitation,\nthen its Chichewa meaning.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.6,
                              color: AppColors.ivory.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 26,
              child: FadeTransition(
                opacity: _fade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: AppColors.gold.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'FULLY OFFLINE  ·  YOUR RECORDINGS STAY WITH YOU',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: AppColors.gold.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
