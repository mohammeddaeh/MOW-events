import 'package:flutter/material.dart';

class RefreshableList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final Widget emptyWidget;
  final Widget? footer;
  final EdgeInsets padding;

  const RefreshableList({
    super.key,
    required this.onRefresh,
    required this.children,
    required this.emptyWidget,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: children.isEmpty
            ? [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(child: emptyWidget),
                ),
              ]
            : [
                ...children,
                if (footer != null) footer!,
              ],
      ),
    );
  }
}
