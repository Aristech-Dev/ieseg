import 'package:flutter/material.dart';

import 'core/app_logo.dart';
import 'core/theme.dart';

void main() {
  runApp(
    MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(body: Center(child: AppLogo())),
    ),
  );
}
