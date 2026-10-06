import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_logo.dart';
import 'auth_controller.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = context.read<AuthController>().verifyCode(_code.text);
    if (!ok) setState(() => _error = 'Code incorrect');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final scheme = Theme.of(context).colorScheme;
    final code = auth.demoCode;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 56)),
                const SizedBox(height: 24),
                Text(
                  'Vérifiez votre adresse email',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Saisissez le code à 6 chiffres associé à ${auth.user?.email ?? ''}.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (code != null)
                  Card(
                    color: scheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            'Mode démo : aucun email n\'est envoyé et ce code '
                            'n\'est pas sécurisé. Votre code est :',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code,
                            key: const Key('demo-code-value'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(letterSpacing: 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('code-field'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Code à 6 chiffres',
                    errorText: _error,
                    counterText: '',
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('verify-button'),
                  onPressed: _submit,
                  child: const Text('Valider le code'),
                ),
                TextButton(
                  key: const Key('resend-button'),
                  onPressed: () {
                    context.read<AuthController>().resendCode();
                    setState(() => _error = null);
                  },
                  child: const Text('Renvoyer un code'),
                ),
                TextButton(
                  key: const Key('logout-button'),
                  onPressed: () => context.read<AuthController>().signOut(),
                  child: const Text('Me déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
