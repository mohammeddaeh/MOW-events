import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// نص قابل للتحديد والنسخ (مثل المتصفح)، مع روابط قابلة للفتح في التطبيق الخارجي.
class SelectableLinkText extends StatefulWidget {
  const SelectableLinkText({
    super.key,
    required this.text,
    required this.style,
    this.linkStyle,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;

  @override
  State<SelectableLinkText> createState() => _SelectableLinkTextState();
}

class _SelectableLinkTextState extends State<SelectableLinkText> {
  /// http(s) ، www. ، mailto:
  static final RegExp _urlRx = RegExp(
    r'''https?:\/\/[^\s<>"'\]\)]+|www\.[^\s<>"'\]\)]+|mailto:[^\s<>"'\]\)]+''',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = [];
  String? _builtForText;
  List<InlineSpan>? _spans;

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void didUpdateWidget(SelectableLinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _clearRecognizers();
      _builtForText = null;
      _spans = null;
    }
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  String _trimTrailingPunctuation(String raw) {
    var s = raw.trim();
    const trailing = '.,;:!?)]}»›';
    while (s.isNotEmpty && trailing.contains(s[s.length - 1])) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  Future<void> _openUrl(String matched) async {
    var uriString = _trimTrailingPunctuation(matched);
    if (uriString.isEmpty) return;
    if (uriString.toLowerCase().startsWith('www.')) {
      uriString = 'https://$uriString';
    }
    final uri = Uri.tryParse(uriString);
    if (uri == null) return;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https' && scheme != 'mailto') {
      return;
    }
    if ((scheme == 'http' || scheme == 'https') && uri.host.isEmpty) {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  List<InlineSpan> _composeSpans(BuildContext context) {
    final linkColor =
        widget.linkStyle?.color ?? Theme.of(context).colorScheme.primary;
    final baseStyle = widget.style;
    final linkMerged = widget.linkStyle != null
        ? baseStyle.merge(widget.linkStyle)
        : baseStyle;
    final linkTextStyle = linkMerged.copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    );

    final spans = <InlineSpan>[];
    var cursor = 0;
    final matches = _urlRx.allMatches(widget.text);

    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(
          TextSpan(
            text: widget.text.substring(cursor, m.start),
            style: baseStyle,
          ),
        );
      }
      final urlText = m.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _openUrl(urlText);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(text: urlText, style: linkTextStyle, recognizer: recognizer),
      );
      cursor = m.end;
    }
    if (cursor < widget.text.length) {
      spans.add(
        TextSpan(text: widget.text.substring(cursor), style: baseStyle),
      );
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: widget.text, style: baseStyle));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (_builtForText != widget.text || _spans == null) {
      _clearRecognizers();
      _spans = _composeSpans(context);
      _builtForText = widget.text;
    }

    return SelectableText.rich(
      TextSpan(children: _spans),
      textAlign: widget.textAlign ?? TextAlign.start,
    );
  }
}
