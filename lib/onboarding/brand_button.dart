import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'search_criteria.dart';

class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.brand,
    required this.selected,
    required this.onPressed,
  });

  final Brand brand;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(brand.asset, width: 28, height: 28);
    final label = Text(brand.label);
    const alignment = Alignment.centerLeft;
    return selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: FilledButton.styleFrom(alignment: alignment),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: OutlinedButton.styleFrom(alignment: alignment),
          );
  }
}
