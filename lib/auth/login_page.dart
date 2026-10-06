import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_logo.dart';
import '../core/validators.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.signIn(_email.text, _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo()),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('email-field'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('password-field'),
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Saisissez votre mot de passe'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('login-button'),
                    onPressed: _loading ? null : _submit,
                    child: const Text('Me connecter'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('signup-link'),
                    onPressed: () => context.go('/signup'),
                    child: const Text('Je n\'ai pas de compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
