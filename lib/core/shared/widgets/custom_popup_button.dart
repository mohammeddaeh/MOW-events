import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';

class PopupMenuOption {
  final String title;
  final IconData? icon;
  final double? iconSize;
  final VoidCallback onTap;
  final bool showDividerAfter;
  final Color? textColor;

  PopupMenuOption({
    required this.title,
    this.icon,
    this.iconSize,
    required this.onTap,
    this.showDividerAfter = false,
    this.textColor,
  });
}

class ReusablePopupMenu extends StatelessWidget {
  final List<PopupMenuOption> options;
  final IconData icon;
  final double? size;
  final EdgeInsets contentPadding;
  final bool top;
  const ReusablePopupMenu({
    super.key,
    required this.options,
    this.size,
    required this.icon,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.top = false,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final GlobalKey menuKey = GlobalKey();

    return GestureDetector(
      key: menuKey,
      onTap: () => _showCustomMenu(context, menuKey),
      child: Icon(icon, size: size),
    );
  }

  void _showCustomMenu(BuildContext context, GlobalKey key) async {
    final RenderBox button =
        key.currentContext?.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);

    final RelativeRect position = top
        ? RelativeRect.fromLTRB(
            offset.dx + button.size.width - 25,
            offset.dy - (options.length * 48),
            overlay.size.width - offset.dx,
            overlay.size.height - offset.dy,
          )
        : RelativeRect.fromLTRB(
            offset.dx + button.size.width - 25,
            offset.dy + button.size.height,
            overlay.size.width - offset.dx,
            overlay.size.height - offset.dy,
          );
    final List<PopupMenuEntry<int>> menuItems = [];

    for (int i = 0; i < options.length; i++) {
      final item = options[i];

      menuItems.add(
        PopupMenuItem<int>(
          value: i,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: contentPadding,
            child: Row(
              children: [
                if (item.icon != null)
                  Icon(
                    item.icon!,

                    size: item.iconSize ?? 16.w,
                    color: item.textColor ?? AppColors.black,
                  ),
                if (item.icon != null) SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: item.textColor ?? AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (item.showDividerAfter && i < options.length - 1) {
        menuItems.add(
          PopupMenuItem<int>(
            enabled: false,
            height: 8.h,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Divider(
                height: 1.h,
                thickness: 0.5.w,
                color: Colors.grey[300],
              ),
            ),
          ),
        );
      }
    }

    final selected = await showMenu<int>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: AppColors.white,
      elevation: 8.w,
      items: menuItems,
    );

    if (selected != null) {
      options[selected].onTap();
    }
  }
}
