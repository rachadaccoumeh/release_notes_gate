import 'package:flutter/material.dart';

import '../theme/release_notes_theme.dart';

/// Formats a release date the way the timeline shows it: "Today",
/// "Yesterday", "3 days ago" for recent releases, else a short localised
/// date such as "Oct 25, 2026".
String formatReleaseDate(BuildContext context, DateTime date, {DateTime? now}) {
  final theme = ReleaseNotesTheme.of(context);
  final strings = ReleaseNotesTheme.stringsOf(context);
  final today = now ?? DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final age =
      DateTime(today.year, today.month, today.day).difference(day).inDays;
  if (age == 0) return strings.today;
  if (age == 1) return strings.yesterday;
  if (age > 1 && age <= theme.relativeDateDays) return strings.daysAgo(age);
  final localizations = Localizations.of<MaterialLocalizations>(
    context,
    MaterialLocalizations,
  );
  if (localizations != null) return localizations.formatShortDate(day);
  return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
