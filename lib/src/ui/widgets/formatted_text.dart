import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../parser/inline_markup.dart';
import '../theme/release_notes_theme.dart';

/// Called when the user taps a link inside a change.
typedef LinkTapCallback = void Function(Uri url);

/// A change's text with its inline formatting: code on rounded chips, bold
/// runs, and tappable links.
class FormattedText extends StatefulWidget {
  /// Creates formatted text.
  const FormattedText(
    this.text, {
    super.key,
    this.style,
    this.onLinkTap,
    this.maxLines,
  });

  /// The text, with `` `code` ``, `**bold**` and `[label](url)` markup.
  final String text;

  /// Base style. Defaults to the theme's item style.
  final TextStyle? style;

  /// Called on a link tap. Defaults to opening the link in the browser.
  final LinkTapCallback? onLinkTap;

  /// Maximum lines before the text is cut with an ellipsis.
  final int? maxLines;

  @override
  State<FormattedText> createState() => _FormattedTextState();
}

class _FormattedTextState extends State<FormattedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _open(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final onLinkTap = widget.onLinkTap;
    if (onLinkTap != null) {
      onLinkTap(uri);
    } else {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = ReleaseNotesTheme.of(context);
    final base = widget.style ?? theme.itemStyle;
    final spans = parseInlineMarkup(widget.text);
    final codeStyle = base.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier New'],
      fontSize: (base.fontSize ?? 14) * 0.9,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (final span in spans)
            switch (span.kind) {
              InlineMarkupKind.text => TextSpan(text: span.text),
              InlineMarkupKind.bold => TextSpan(
                text: span.text,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              InlineMarkupKind.link => TextSpan(
                text: span.text,
                style: TextStyle(
                  color: theme.linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.linkColor.withValues(alpha: 0.5),
                ),
                recognizer: _recognizer(span.url!),
                semanticsLabel: span.text,
              ),
              InlineMarkupKind.code => WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.codeChipColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(span.text, style: codeStyle),
                ),
              ),
            },
        ],
      ),
      maxLines: widget.maxLines,
      overflow:
          widget.maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      semanticsLabel: stripInlineMarkup(widget.text),
    );
  }

  TapGestureRecognizer _recognizer(String url) {
    final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
    _recognizers.add(recognizer);
    return recognizer;
  }
}
