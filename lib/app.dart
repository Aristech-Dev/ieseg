import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'core/theme.dart';
import 'onboarding/search_criteria.dart';
import 'router.dart';

class AutoscopeApp extends StatefulWidget {
  const AutoscopeApp({
    super.key,
    required this.auth,
    required this.criteria,
    this.initialLocation = '/login',
  });

  final AuthController auth;
  final SearchCriteria criteria;
  final String initialLocation;

  @override
  State<AutoscopeApp> createState() => _AutoscopeAppState();
}

class _AutoscopeAppState extends State<AutoscopeApp> {
  late final GoRouter _router =
      createRouter(widget.auth, initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: widget.auth),
        ChangeNotifierProvider<SearchCriteria>.value(value: widget.criteria),
      ],
      child: MaterialApp.router(
        title: 'Autoscope',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
