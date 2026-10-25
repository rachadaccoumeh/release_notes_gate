import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

void main() {
  group('LocalizedText.resolve', () {
    const text = LocalizedText(
      'Dark mode',
      translations: {
        'ar': 'الوضع الداكن',
        'pt-BR': 'Modo escuro',
        'fr_CA': 'Mode sombre',
      },
    );

    test('returns the fallback without a locale', () {
      expect(text.resolve(), 'Dark mode');
      expect(text.resolve(const Locale('de')), 'Dark mode');
    });

    test('matches language, language and country, and sibling countries', () {
      expect(text.resolve(const Locale('ar')), 'الوضع الداكن');
      expect(text.resolve(const Locale('ar', 'SA')), 'الوضع الداكن');
      expect(text.resolve(const Locale('pt', 'BR')), 'Modo escuro');
      expect(text.resolve(const Locale('pt', 'PT')), 'Modo escuro');
      expect(text.resolve(const Locale('fr')), 'Mode sombre');
    });
  });

  group('LocalizedText.fromJson', () {
    test('reads a string', () {
      expect(LocalizedText.fromJson('Hello'), const LocalizedText('Hello'));
    });

    test('reads a map with a default key', () {
      final text = LocalizedText.fromJson({'default': 'Hello', 'ar': 'مرحبا'});
      expect(text.text, 'Hello');
      expect(text.translations, {'ar': 'مرحبا'});
    });

    test('reads a map without a default key, en first', () {
      final text = LocalizedText.fromJson({'ar': 'مرحبا', 'en': 'Hello'});
      expect(text.text, 'Hello');
      expect(text.translations, {'ar': 'مرحبا'});
    });

    test('reads a map with a custom default locale', () {
      final text = LocalizedText.fromJson({
        'ar': 'مرحبا',
        'fr': 'Bonjour',
      }, defaultLocale: 'fr');
      expect(text.text, 'Bonjour');
      expect(text.translations, {'ar': 'مرحبا'});
    });

    test('round-trips through toJson', () {
      const text = LocalizedText('Hello', translations: {'ar': 'مرحبا'});
      expect(LocalizedText.fromJson(text.toJson()), text);
      expect(const LocalizedText('Plain').toJson(), 'Plain');
    });
  });
}
