import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class BrandEmblem extends StatelessWidget {
  const BrandEmblem({
    super.key,
    this.size = 48,
    this.glow = false,
  });

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(
      'assets/brand/werenga_emblem.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'Werenga emblem',
    );
    if (!glow) return image;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC6A664).withValues(alpha: 0.22),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: image,
    );
  }
}
