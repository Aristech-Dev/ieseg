import 'package:autoscope/firebase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sans --dart-define, Firebase n\'est pas considéré comme configuré', () {
    expect(FirebaseConfig.isConfigured, isFalse);
  });
}
