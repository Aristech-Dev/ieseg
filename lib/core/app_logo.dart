import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          child: Icon(
            Icons.directions_car_filled,
            color: scheme.onPrimary,
            size: size * 0.55,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Autoscope',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
