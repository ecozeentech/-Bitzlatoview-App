import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Brand logo matching app.bitzlatoview.com header:
/// gradient icon badge + "Bitzlato" (white) + "view" (gold).
class BitzlatoviewLogo extends StatelessWidget {
  const BitzlatoviewLogo({
    super.key,
    this.iconSize = 36,
    this.fontSize = 22,
    this.showWordmark = true,
    this.showTagline = false,
  });

  final double iconSize;
  final double fontSize;
  final bool showWordmark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (iconSize > 0) _BrandIconBadge(size: iconSize),
            if (showWordmark) ...[
              if (iconSize > 0) SizedBox(width: iconSize * 0.35),
              _BrandWordmark(fontSize: fontSize),
            ],
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: iconSize * 0.25),
          Text(
            'Secure Trading Platform',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: fontSize * 0.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _BrandIconBadge extends StatelessWidget {
  const _BrandIconBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandGold.withValues(alpha: 0.25),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'B',
        style: TextStyle(
          color: AppTheme.textOnBrand,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        children: const [
          TextSpan(
            text: 'Bitzlato',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          TextSpan(
            text: 'view',
            style: TextStyle(color: AppTheme.brandGold),
          ),
        ],
      ),
    );
  }
}

/// Square app icon image from official website assets.
class BitzlatoviewAppIcon extends StatelessWidget {
  const BitzlatoviewAppIcon({
    super.key,
    this.size = 120,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icons/icon-512x512.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
