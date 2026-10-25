import 'package:flutter/foundation.dart' show immutable;

/// The kind of an [InlineMarkupSpan].
enum InlineMarkupKind {
  /// Plain text.
  text,

  /// Inline code, written `` `code` ``.
  code,

  /// Bold text, written `**bold**`.
  bold,

  /// A link, written `[label](url)`.
  link,
}

/// A run of text with one inline style.
@immutable
class InlineMarkupSpan {
  /// Creates a span.
  const InlineMarkupSpan(this.kind, this.text, {this.url});

  /// The style of the run.
  final InlineMarkupKind kind;

  /// The text shown.
  final String text;

  /// The link target, for [InlineMarkupKind.link].
  final String? url;

  @override
  bool operator ==(Object other) =>
      other is InlineMarkupSpan &&
      other.kind == kind &&
      other.text == text &&
      other.url == url;

  @override
  int get hashCode => Object.hash(kind, text, url);

  @override
  String toString() =>
      'InlineMarkupSpan.${kind.name}($text${url == null ? '' : ' -> $url'})';
}

/// Splits a change's text into styled runs: inline code, bold and links,
/// the only formatting a single change carries. Everything else is text.
List<InlineMarkupSpan> parseInlineMarkup(String text) {
  final spans = <InlineMarkupSpan>[];
  var position = 0;
  for (final match in _inline.allMatches(text)) {
    if (match.start > position) {
      spans.add(
        InlineMarkupSpan(
          InlineMarkupKind.text,
          text.substring(position, match.start),
        ),
      );
    }
    final code = match.group(1);
    final bold = match.group(2);
    final label = match.group(3);
    final url = match.group(4);
    if (code != null) {
      spans.add(InlineMarkupSpan(InlineMarkupKind.code, code));
    } else if (bold != null) {
      spans.add(InlineMarkupSpan(InlineMarkupKind.bold, bold));
    } else if (label != null && url != null) {
      spans.add(InlineMarkupSpan(InlineMarkupKind.link, label, url: url));
    }
    position = match.end;
  }
  if (position < text.length) {
    spans.add(
      InlineMarkupSpan(InlineMarkupKind.text, text.substring(position)),
    );
  }
  return spans;
}

/// [text] with the inline markup removed, for semantics labels and search.
String stripInlineMarkup(String text) =>
    parseInlineMarkup(text).map((span) => span.text).join();

final RegExp _inline = RegExp(
  r'`([^`]+)`|\*\*(.+?)\*\*|\[([^\]]+)\]\(([^)\s]+)\)',
);
