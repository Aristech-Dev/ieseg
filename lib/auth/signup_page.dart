import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_logo.dart';
import '../core/validators.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
      await auth.signUp(_email.text, _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
        title: const Text('Créer un compte'),
      ),
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
                  const Center(child: AppLogo(size: 56)),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('signup-email-field'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup-password-field'),
                    controller: _password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: _password,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final rule in passwordRules)
                          _RuleRow(
                            label: rule.label,
                            ok: rule.test(_password.text),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup-confirm-field'),
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe'),
                    validator: (v) => validateConfirm(_password.text, v),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('signup-button'),
                    onPressed: _loading ? null : _submit,
                    child: const Text('Créer mon compte'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('login-link'),
                    onPressed: () => context.go('/login'),
                    child: const Text('J\'ai déjà un compte'),
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

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: ok ? Colors.green : Theme.of(context).disabledColor,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
