import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show immutable;

/// Text with optional translations.
///
/// [text] is the fallback. [translations] map a locale tag (`ar`, `ar_SA`,
/// `pt-BR`, case-insensitive) to the text in that language. [resolve] picks
/// the best match for a locale: language and country first, then language,
/// then the fallback.
@immutable
class LocalizedText {
  /// Creates text with a fallback and optional translations.
  const LocalizedText(this.text, {this.translations = const {}});

  /// Reads a JSON value: a plain string, or a map of locale tag to string.
  ///
  /// In a map the fallback is, in order, the `default` key, the
  /// [defaultLocale] key, the `en` key, or the first entry.
  factory LocalizedText.fromJson(Object? json, {String defaultLocale = 'en'}) {
    if (json == null) return const LocalizedText('');
    if (json is String) return LocalizedText(json);
    if (json is Map) {
      final entries = <String, String>{};
      json.forEach((key, value) {
        if (key is String && value is String) entries[key] = value;
      });
      if (entries.isEmpty) return const LocalizedText('');
      final fallback =
          entries.remove('default') ??
          _take(entries, defaultLocale) ??
          _take(entries, 'en') ??
          entries.remove(entries.keys.first)!;
      return LocalizedText(fallback, translations: entries);
    }
    return LocalizedText(json.toString());
  }

  static String? _take(Map<String, String> entries, String key) {
    final match =
        entries.keys
            .where((candidate) => _normalize(candidate) == _normalize(key))
            .firstOrNull;
    return match == null ? null : entries.remove(match);
  }

  static String _normalize(String tag) =>
      tag.trim().toLowerCase().replaceAll('-', '_');

  /// The fallback text.
  final String text;

  /// Translations by locale tag.
  final Map<String, String> translations;

  /// True when the fallback text is empty.
  bool get isEmpty => text.trim().isEmpty;

  /// True when the fallback text is not empty.
  bool get isNotEmpty => !isEmpty;

  /// The text for [locale]: exact language and country, then language, then
  /// [text]. A null locale returns [text].
  String resolve([Locale? locale]) {
    if (locale == null || translations.isEmpty) return text;
    final language = locale.languageCode.toLowerCase();
    final country = locale.countryCode?.toLowerCase();
    final candidates = <String>[
      if (country != null && country.isNotEmpty) '${language}_$country',
      language,
    ];
    for (final candidate in candidates) {
      for (final entry in translations.entries) {
        if (_normalize(entry.key) == candidate) return entry.value;
      }
    }
    // A translation for another country of the same language still beats the
    // fallback: `ar_EG` serves an `ar_SA` user.
    for (final entry in translations.entries) {
      final key = _normalize(entry.key);
      if (key.startsWith('${language}_')) return entry.value;
    }
    return text;
  }

  /// Returns a copy with [transform] applied to the fallback and every
  /// translation.
  LocalizedText map(String Function(String text) transform) => LocalizedText(
    transform(text),
    translations: translations.map(
      (key, value) => MapEntry(key, transform(value)),
    ),
  );

  /// A plain string when there are no translations, else a map with a
  /// `default` key and one key per translation.
  Object toJson() {
    if (translations.isEmpty) return text;
    return <String, String>{'default': text, ...translations};
  }

  @override
  bool operator ==(Object other) =>
      other is LocalizedText &&
      other.text == text &&
      other.translations.length == translations.length &&
      other.translations.entries.every(
        (entry) => translations[entry.key] == entry.value,
      );

  @override
  int get hashCode => Object.hash(
    text,
    Object.hashAllUnordered(
      translations.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => text;
}
