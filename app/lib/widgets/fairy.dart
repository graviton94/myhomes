import 'package:flutter/material.dart';

/// The six House Fairy expressions (design/fairy/parts.svg, baked by
/// tool/bake_fairy.mjs). Dark variants carry a light sticker outline so the
/// stick arms stay visible on dark backgrounds.
enum FairyPose { hello, found, carry, worry, cheer, sleep }

class Fairy extends StatelessWidget {
  const Fairy(this.pose, {super.key, this.height = 120});

  final FairyPose pose;
  final double height;

  static String asset(FairyPose pose, Brightness brightness) =>
      'assets/fairy/${pose.name}${brightness == Brightness.dark ? '_dark' : ''}.webp';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset(pose, Theme.of(context).brightness),
      height: height,
      width: height * 360 / 420,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
    );
  }
}
