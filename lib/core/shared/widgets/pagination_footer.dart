import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';

class PaginationFooter extends StatefulWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final String actionLabel;
  final String loadingLabel;
  final String completedLabel;
  final VoidCallback? onLoadMore;
  final EdgeInsetsGeometry padding;
  final bool showCompletedTransiently;
  final Duration completedVisibleDuration;

  const PaginationFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.actionLabel,
    required this.loadingLabel,
    required this.completedLabel,
    this.onLoadMore,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    this.showCompletedTransiently = true,
    this.completedVisibleDuration = const Duration(seconds: 2),
  });

  @override
  State<PaginationFooter> createState() => _PaginationFooterState();
}

class _PaginationFooterState extends State<PaginationFooter> {
  bool _showCompleted = false;
  Timer? _hideTimer;

  bool get _isCompletedState => !widget.isLoadingMore && !widget.hasMore;

  @override
  void initState() {
    super.initState();
    _syncCompletedState();
  }

  @override
  void didUpdateWidget(covariant PaginationFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoadingMore != widget.isLoadingMore ||
        oldWidget.hasMore != widget.hasMore ||
        oldWidget.showCompletedTransiently != widget.showCompletedTransiently) {
      _syncCompletedState();
    }
  }

  void _syncCompletedState() {
    _hideTimer?.cancel();
    if (!_isCompletedState) {
      if (mounted) setState(() => _showCompleted = false);
      return;
    }
    if (!widget.showCompletedTransiently) {
      if (mounted) setState(() => _showCompleted = true);
      return;
    }
    if (mounted) setState(() => _showCompleted = true);
    _hideTimer = Timer(widget.completedVisibleDuration, () {
      if (mounted) setState(() => _showCompleted = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeHelper.accent(context);
    final secondaryText = AppThemeHelper.textSecondary(context);

    return Padding(
      padding: widget.padding,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: widget.isLoadingMore
              ? Row(
                  key: const ValueKey('pagination_loading'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.loadingLabel,
                      style: TextStyle(
                        color: secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : widget.hasMore
              ? OutlinedButton.icon(
                  key: const ValueKey('pagination_action'),
                  onPressed: widget.onLoadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text(widget.actionLabel),
                )
              : _showCompleted
              ? Text(
                  widget.completedLabel,
                  key: const ValueKey('pagination_completed'),
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
