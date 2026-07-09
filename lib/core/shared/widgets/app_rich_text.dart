import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/theme/app_typography.dart';

/// [RichText] مع خط التطبيق الافتراضي حتى مع [TextStyle] جزئي.
class AppRichText extends StatelessWidget {
  const AppRichText({
    super.key,
    required this.text,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final TextSpan text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      softWrap: softWrap ?? true,
      text: TextSpan(
        style: AppTypography.merge(context, text.style),
        text: text.text,
        children: text.children,
      ),
    );
  }
}
