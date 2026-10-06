class PasswordRule {
  const PasswordRule(this.label, this.error, this.test);

  final String label;
  final String error;
  final bool Function(String) test;
}

final RegExp _uppercase = RegExp(r'\p{Lu}', unicode: true);
final RegExp _special = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool _hasMinLength(String v) => v.length >= 8;
bool _hasUppercase(String v) => _uppercase.hasMatch(v);
bool _hasSpecial(String v) => _special.hasMatch(v);

const List<PasswordRule> passwordRules = [
  PasswordRule(
    '8 caractères minimum',
    'Le mot de passe doit contenir au moins 8 caractères',
    _hasMinLength,
  ),
  PasswordRule(
    '1 majuscule minimum',
    'Le mot de passe doit contenir au moins une majuscule',
    _hasUppercase,
  ),
  PasswordRule(
    '1 caractère spécial minimum',
    'Le mot de passe doit contenir au moins un caractère spécial',
    _hasSpecial,
  ),
];

String? validatePassword(String? value) {
  final v = value ?? '';
  for (final rule in passwordRules) {
    if (!rule.test(v)) return rule.error;
  }
  return null;
}

String? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Saisissez votre email';
  if (!_email.hasMatch(v)) return 'Adresse email invalide';
  return null;
}

String? validateConfirm(String? password, String? confirm) {
  if (password != confirm) return 'Les mots de passe ne correspondent pas';
  return null;
}
