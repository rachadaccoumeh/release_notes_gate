import 'package:flutter/foundation.dart' show immutable;

/// A lenient app version: `v2.2.0`, `2.2.0-dev.4+12`, `2.2` or `1.0.0-rc1`.
///
/// Numbers compare numerically and missing parts count as zero, so `2.2`
/// equals `2.2.0`. A version without a pre-release part is newer than the
/// same numbers with one (`2.2.0` > `2.2.0-dev.4`). Build metadata after `+`
/// is kept for display and ignored when comparing.
@immutable
class ReleaseVersion implements Comparable<ReleaseVersion> {
  const ReleaseVersion._({
    required this.raw,
    required this.numbers,
    required this.preRelease,
    required this.build,
  });

  /// Parses [input]. Throws a [FormatException] when it does not start with
  /// a number after an optional `v`.
  factory ReleaseVersion.parse(String input) {
    final version = tryParse(input);
    if (version == null) {
      throw FormatException('Not a version', input);
    }
    return version;
  }

  /// Parses [input], or returns null when it is not a version.
  static ReleaseVersion? tryParse(String? input) {
    if (input == null) return null;
    var text = input.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1).trimLeft();
    }
    String? build;
    final plus = text.indexOf('+');
    if (plus >= 0) {
      build = text.substring(plus + 1);
      text = text.substring(0, plus);
    }
    final match = _numbers.firstMatch(text);
    if (match == null) return null;
    final numbers = match
        .group(1)!
        .split('.')
        .map(int.parse)
        .toList(growable: false);
    final rest = text.substring(match.end);
    final preRelease = rest
        .replaceFirst(_separator, '')
        .split(_identifierSplit)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return ReleaseVersion._(
      raw: input.trim(),
      numbers: numbers,
      preRelease: preRelease,
      build: build,
    );
  }

  static final RegExp _numbers = RegExp(r'^(\d+(?:\.\d+)*)');
  static final RegExp _separator = RegExp(r'^[-._ ]+');
  static final RegExp _identifierSplit = RegExp(r'[.\-_]');
  static final RegExp _digits = RegExp(r'^\d+$');

  /// The text as given, trimmed.
  final String raw;

  /// Numeric parts: `[2, 2, 0]` for `2.2.0`.
  final List<int> numbers;

  /// Pre-release identifiers: `['dev', '4']` for `2.2.0-dev.4`. Empty for a
  /// stable release.
  final List<String> preRelease;

  /// Build metadata after `+`, or null.
  final String? build;

  /// True when the version carries a pre-release part.
  bool get isPrerelease => preRelease.isNotEmpty;

  /// The version without a leading `v` and without build metadata:
  /// `2.2.0-dev.4`.
  String get normalized {
    final core = numbers.join('.');
    return preRelease.isEmpty ? core : '$core-${preRelease.join('.')}';
  }

  /// [normalized] with the conventional `v` prefix: `v2.2.0`.
  String get withPrefix => 'v$normalized';

  @override
  int compareTo(ReleaseVersion other) {
    final length =
        numbers.length > other.numbers.length
            ? numbers.length
            : other.numbers.length;
    for (var i = 0; i < length; i++) {
      final a = i < numbers.length ? numbers[i] : 0;
      final b = i < other.numbers.length ? other.numbers[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;
    final count =
        preRelease.length < other.preRelease.length
            ? preRelease.length
            : other.preRelease.length;
    for (var i = 0; i < count; i++) {
      final result = _compareIdentifier(preRelease[i], other.preRelease[i]);
      if (result != 0) return result;
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  static int _compareIdentifier(String a, String b) {
    final aNumeric = _digits.hasMatch(a);
    final bNumeric = _digits.hasMatch(b);
    if (aNumeric && bNumeric) return int.parse(a).compareTo(int.parse(b));
    if (aNumeric) return -1;
    if (bNumeric) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  /// True when this version is strictly newer than [other].
  bool operator >(ReleaseVersion other) => compareTo(other) > 0;

  /// True when this version is strictly older than [other].
  bool operator <(ReleaseVersion other) => compareTo(other) < 0;

  /// True when this version is newer than or equal to [other].
  bool operator >=(ReleaseVersion other) => compareTo(other) >= 0;

  /// True when this version is older than or equal to [other].
  bool operator <=(ReleaseVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is ReleaseVersion && compareTo(other) == 0;

  @override
  int get hashCode {
    final trimmed = List<int>.of(numbers);
    while (trimmed.length > 1 && trimmed.last == 0) {
      trimmed.removeLast();
    }
    return Object.hash(
      Object.hashAll(trimmed),
      Object.hashAll(preRelease.map((part) => part.toLowerCase())),
    );
  }

  @override
  String toString() => normalized;
}
