import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class RememberMeCheckbox extends StatefulWidget {
  RememberMeCheckbox({
    super.key,
    this.storageKey,
    this.initialValue = false,
    this.onChanged,
    Widget? title,
    this.activeColor,
    this.checkColor,
  }) : title = title ?? Text(AppTexts.rememberMe);

  final String? storageKey;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Color? activeColor;
  final Color? checkColor;

  @override
  State<RememberMeCheckbox> createState() => _RememberMeCheckboxState();
}

class _RememberMeCheckboxState extends State<RememberMeCheckbox> {
  late bool _value;
  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;

    if (widget.storageKey != null) {
      final storedValue = _storage.read(widget.storageKey!);
      if (storedValue is bool) {
        _value = storedValue;
      }
    }
  }

  void _toggle() {
    setState(() => _value = !_value);
    widget.onChanged?.call(_value);

    if (widget.storageKey != null) {
      _storage.write(widget.storageKey!, _value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1.0,

            child: Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              value: _value,
              onChanged: (_) => _toggle(),
              side: BorderSide(
                color: AppThemeHelper.buttonSecondary(context),
                width: 1.5,
              ),
              activeColor:
                  widget.activeColor ?? Theme.of(context).colorScheme.primary,
              checkColor: widget.checkColor ?? Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          DefaultTextStyle(
            style:
                Theme.of(context).textTheme.bodyMedium ??
                const TextStyle(fontSize: 14),
            child: widget.title,
          ),
        ],
      ),
    );
  }
}
