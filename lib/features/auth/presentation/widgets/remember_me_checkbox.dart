import 'package:flutter/material.dart';

import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class RememberMeCheckbox extends StatelessWidget {
  RememberMeCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    Widget? title,
    this.activeColor,
    this.checkColor,
  }) : title = title ?? Text(AppTexts.rememberMe);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Color? activeColor;
  final Color? checkColor;

  void _toggle() {
    if (onChanged != null) onChanged!(!value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            value: value,
            onChanged: onChanged == null
                ? null
                : (checked) {
                    if (checked != null) onChanged!(checked);
                  },
            side: BorderSide(
              color: AppThemeHelper.buttonSecondary(context),
              width: 1.5,
            ),
            activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
            checkColor: checkColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: InkWell(
            onTap: onChanged == null ? null : _toggle,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: DefaultTextStyle(
                style:
                    Theme.of(context).textTheme.bodyMedium ??
                    const TextStyle(fontSize: 14),
                child: title,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
