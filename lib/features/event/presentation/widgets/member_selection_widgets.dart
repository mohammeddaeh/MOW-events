import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';

class MemberSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onShowInfo;
  final bool hasError;

  const MemberSectionHeader({
    super.key,
    required this.title,
    required this.onShowInfo,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppThemeHelper.whiteBlack(context),
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(width: 6),
                Text(
                  '*',
                  style: TextStyle(
                    color: AppThemeHelper.red(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        Tooltip(
          message: AppTexts.memberSearchGuideTitle,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onShowInfo,
              child: Ink(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primary.withOpacity(0.16)),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: primary.withOpacity(0.92),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MemberSelectionSearchToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFinishSearch;
  final VoidCallback onShowSelected;
  final bool hasSearch;
  final int selectedCount;
  final int resultCount;

  /// يوضح للمستخدم أي حقول يُطبَّق عليها البحث (اسم، بريد، هاتف).
  final String? searchScopeLabel;

  const MemberSelectionSearchToolbar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFinishSearch,
    required this.onShowSelected,
    required this.hasSearch,
    required this.selectedCount,
    required this.resultCount,
    this.focusNode,
    this.searchScopeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    final secondaryText = AppThemeHelper.textSecondary(context);
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          scrollPadding: EdgeInsets.only(top: 56, bottom: keyboardBottom + 300),
          onChanged: onChanged,
          onTapOutside: (_) => focusNode?.unfocus(),
          decoration: InputDecoration(
            hintText: AppTexts.searchMembersByNameOrEmail,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: hasSearch
                ? IconButton(
                    tooltip: AppTexts.close,
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SelectedMembersButton(
                selectedCount: selectedCount,
                onTap: onShowSelected,
              ),
            ),
            if (hasSearch) const SizedBox(width: 8),
            if (hasSearch)
              TextButton.icon(
                onPressed: onFinishSearch,
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(AppTexts.finishSearch),
              ),
          ],
        ),
        if (hasSearch) ...[
          const SizedBox(height: 8),
          if (searchScopeLabel != null) ...[
            Text(
              searchScopeLabel!,
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '${AppTexts.searchResults} ($resultCount)',
            style: TextStyle(color: secondaryText, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _SelectedMembersButton extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onTap;

  const _SelectedMembersButton({
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    final hasSelection = selectedCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasSelection
                ? primary.withOpacity(0.11)
                : AppThemeHelper.blackWhite(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSelection
                  ? primary.withOpacity(0.28)
                  : AppThemeHelper.border(context).withOpacity(0.6),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 18,
                color: hasSelection
                    ? primary
                    : AppThemeHelper.textSecondary(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppTexts.selectedMembers,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppThemeHelper.whiteBlack(context),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasSelection ? primary : primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectedCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: hasSelection ? Colors.white : primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberSearchResultsCard extends StatelessWidget {
  final List<UserEntity> members;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final bool Function(UserEntity user) isManagerUser;

  const MemberSearchResultsCard({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.onToggle,
    required this.isManagerUser,
  });

  @override
  Widget build(BuildContext context) {
    final background = AppThemeHelper.blackWhite(context);
    final border = AppThemeHelper.border(context);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withOpacity(0.55)),
      ),
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final user = members[index];
            return _MemberUserTile(
              user: user,
              isSelected: selectedIds.contains(user.id),
              isManager: isManagerUser(user),
              showDepartment: true,
              onTap: () => onToggle(user.id),
              onLongPress: () => showMemberDetailsBottomSheet(
                context,
                user: user,
                isManager: isManagerUser(user),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ExpandableDepartmentMembersCard extends StatelessWidget {
  final Department department;
  final List<UserEntity> users;
  final bool isExpanded;
  final bool allSelected;
  final bool showUsers;
  final Set<int> selectedIds;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleDepartment;
  final ValueChanged<int> onToggleMember;
  final bool Function(UserEntity user) isManagerUser;

  const ExpandableDepartmentMembersCard({
    super.key,
    required this.department,
    required this.users,
    required this.isExpanded,
    required this.allSelected,
    required this.showUsers,
    required this.selectedIds,
    required this.onToggleExpanded,
    required this.onToggleDepartment,
    required this.onToggleMember,
    required this.isManagerUser,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    final border = AppThemeHelper.border(context);
    final background = AppThemeHelper.blackWhite(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onToggleExpanded,
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded
                        ? primary.withOpacity(0.35)
                        : border.withOpacity(0.55),
                  ),
                ),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 0.92,
                      child: Checkbox(
                        value: allSelected,
                        onChanged: (_) => onToggleDepartment(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        department.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppThemeHelper.whiteBlack(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${users.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: !showUsers
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border.withOpacity(0.4)),
                      ),
                      child: CollapsibleItemsList(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 10,
                          thickness: 0.7,
                          color: border.withOpacity(0.35),
                        ),
                        itemBuilder: (context, index) => _MemberUserTile(
                          user: users[index],
                          isSelected: selectedIds.contains(users[index].id),
                          isManager: isManagerUser(users[index]),
                          onTap: () => onToggleMember(users[index].id),
                          onLongPress: () => showMemberDetailsBottomSheet(
                            context,
                            user: users[index],
                            isManager: isManagerUser(users[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// قائمة طويلة تُطوى بعد [collapsedCount] عنصراً مع زر "عرض الكل / عرض أقل".
class CollapsibleItemsList extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final int collapsedCount;

  const CollapsibleItemsList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.collapsedCount = 5,
  });

  @override
  State<CollapsibleItemsList> createState() => _CollapsibleItemsListState();
}

class _CollapsibleItemsListState extends State<CollapsibleItemsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    // لا داعي للطي إذا كان المخفي عنصراً واحداً فقط
    final collapsible = widget.itemCount > widget.collapsedCount + 1;
    final visibleCount = !collapsible || _expanded
        ? widget.itemCount
        : widget.collapsedCount;

    // بدون AnimatedSize: تقلّص القائمة تدريجياً كان يترك فراغاً في الشاشة أثناء الطي.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int index = 0; index < visibleCount; index++) ...[
          if (index > 0 && widget.separatorBuilder != null)
            widget.separatorBuilder!(context, index),
          widget.itemBuilder(context, index),
        ],
        if (collapsible)
          Center(
            child: TextButton.icon(
              onPressed: _toggle,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                visualDensity: VisualDensity.compact,
              ),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
              ),
              label: Text(
                _expanded
                    ? AppTexts.showLess
                    : AppTexts.showAllCount.replaceFirst(
                        '%s',
                        '${widget.itemCount}',
                      ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  void _toggle() {
    final collapsing = _expanded;
    setState(() => _expanded = !_expanded);
    if (!collapsing) return;

    // بعد الطي يبقى موضع السكرول في الأسفل فيظهر فراغ/قسم لاحق —
    // نرجع لبداية القائمة إذا صارت فوق الشاشة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }
}

Future<void> showMemberSearchInfoBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppThemeHelper.background(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final items = [
        (Icons.search_rounded, AppTexts.memberSearchGuideSearchTip),
        (Icons.person_add_alt_1_rounded, AppTexts.memberSearchGuideSelectTip),
        (Icons.touch_app_rounded, AppTexts.memberSearchGuideLongPressTip),
        (
          Icons.check_circle_outline_rounded,
          AppTexts.memberSearchGuideFinishTip,
        ),
        (Icons.groups_rounded, AppTexts.memberSearchGuideReviewTip),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTexts.memberSearchGuideTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppThemeHelper.whiteBlack(sheetContext),
                ),
              ),
              const SizedBox(height: 14),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppThemeHelper.buttonPrimary(
                            sheetContext,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.$1,
                          size: 20,
                          color: AppThemeHelper.buttonPrimary(sheetContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppThemeHelper.textSecondary(sheetContext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showSelectedMembersBottomSheet(
  BuildContext context, {
  required Map<Department, List<UserEntity>> groupedMembers,
  required ValueChanged<int> onToggleMember,
  required bool Function(UserEntity user) isManagerUser,
}) {
  final localGroups = <Department, List<UserEntity>>{
    for (final entry in groupedMembers.entries)
      entry.key: List<UserEntity>.from(entry.value),
  };

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppThemeHelper.background(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final expandedDepartments = <int>{};

      return StatefulBuilder(
        builder: (context, setState) {
          final sortedEntries = localGroups.entries.toList()
            ..sort(
              (a, b) =>
                  a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase()),
            );
          final count = localGroups.values.fold<int>(
            0,
            (sum, users) => sum + users.length,
          );
          final primary = AppThemeHelper.buttonPrimary(sheetContext);

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.72,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppTexts.selectedMembers} ($count)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppThemeHelper.whiteBlack(sheetContext),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: AppTexts.close,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTexts.selectedMembersManageHint,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppThemeHelper.textSecondary(sheetContext),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (count == 0)
                      Expanded(
                        child: Center(
                          child: Text(
                            AppTexts.noSelectedMembersYet,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppThemeHelper.textSecondary(sheetContext),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: sortedEntries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = sortedEntries[index];
                            final users = entry.value;
                            final isExpanded = expandedDepartments.contains(
                              entry.key.id,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() {
                                        if (isExpanded) {
                                          expandedDepartments.remove(
                                            entry.key.id,
                                          );
                                        } else {
                                          expandedDepartments.add(entry.key.id);
                                        }
                                      });
                                    },
                                    child: Ink(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.09),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primary.withOpacity(0.18),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    AppThemeHelper.whiteBlack(
                                                      sheetContext,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.75,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${users.length}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isExpanded
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            color: primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  child: !isExpanded
                                      ? const SizedBox.shrink()
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppThemeHelper.blackWhite(
                                                sheetContext,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: AppThemeHelper.border(
                                                  sheetContext,
                                                ).withOpacity(0.4),
                                              ),
                                            ),
                                            child: CollapsibleItemsList(
                                              itemCount: users.length,
                                              separatorBuilder: (_, __) =>
                                                  Divider(
                                                    height: 10,
                                                    thickness: 0.7,
                                                    color:
                                                        AppThemeHelper.border(
                                                          sheetContext,
                                                        ).withOpacity(0.35),
                                                  ),
                                              itemBuilder:
                                                  (
                                                    context,
                                                    userIndex,
                                                  ) => _MemberUserTile(
                                                    user: users[userIndex],
                                                    isSelected: true,
                                                    isManager: isManagerUser(
                                                      users[userIndex],
                                                    ),
                                                    mode: _MemberTileMode
                                                        .selectedPreview,
                                                    onTap: () async {
                                                      final shouldRemove =
                                                          await _confirmMemberRemoval(
                                                            sheetContext,
                                                            users[userIndex],
                                                          );
                                                      if (!shouldRemove) {
                                                        return;
                                                      }

                                                      onToggleMember(
                                                        users[userIndex].id,
                                                      );
                                                      setState(() {
                                                        localGroups[entry.key]
                                                            ?.removeWhere(
                                                              (user) =>
                                                                  user.id ==
                                                                  users[userIndex]
                                                                      .id,
                                                            );
                                                        if (localGroups[entry
                                                                    .key]
                                                                ?.isEmpty ==
                                                            true) {
                                                          localGroups.remove(
                                                            entry.key,
                                                          );
                                                          expandedDepartments
                                                              .remove(
                                                                entry.key.id,
                                                              );
                                                        }
                                                      });
                                                    },
                                                    onLongPress: () =>
                                                        showMemberDetailsBottomSheet(
                                                          sheetContext,
                                                          user:
                                                              users[userIndex],
                                                          isManager:
                                                              isManagerUser(
                                                                users[userIndex],
                                                              ),
                                                        ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showMemberDetailsBottomSheet(
  BuildContext context, {
  required UserEntity user,
  required bool isManager,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppThemeHelper.background(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final primary = AppThemeHelper.buttonPrimary(sheetContext);
      final roleLabel = user.isAdmin
          ? AppTexts.administrator
          : isManager
          ? AppTexts.manager
          : AppTexts.employee;
      final statusLabel = user.isActive ? AppTexts.active : AppTexts.inactive;
      final metadata = <({IconData icon, String label, String value})>[
        (
          icon: Icons.person_outline_rounded,
          label: AppTexts.fullName,
          value: user.fullName,
        ),
        (
          icon: Icons.badge_outlined,
          label: AppTexts.firstName,
          value: user.firstName,
        ),
        (
          icon: Icons.badge_outlined,
          label: AppTexts.familyName,
          value: user.lastName,
        ),
        if ((user.email ?? '').trim().isNotEmpty)
          (
            icon: Icons.mail_outline_rounded,
            label: AppTexts.email,
            value: user.email!.trim(),
          ),
        if ((user.phone ?? '').trim().isNotEmpty)
          (
            icon: Icons.phone_outlined,
            label: AppTexts.phoneNumber,
            value: user.phone!.trim(),
          ),
        if (user.department?.name.trim().isNotEmpty == true)
          (
            icon: Icons.apartment_rounded,
            label: AppTexts.section,
            value: user.department!.name,
          ),
        if ((user.address ?? '').trim().isNotEmpty)
          (
            icon: Icons.location_on_outlined,
            label: AppTexts.addresse,
            value: user.address!.trim(),
          ),
        (
          icon: Icons.work_outline_rounded,
          label: AppTexts.role,
          value: roleLabel,
        ),
        (
          icon: Icons.verified_user_outlined,
          label: AppTexts.accountStatus,
          value: statusLabel,
        ),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primary.withOpacity(0.14),
                      foregroundColor: primary,
                      child: Text(
                        _initialsFor(user),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTexts.memberDetails,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppThemeHelper.whiteBlack(sheetContext),
                            ),
                          ),
                          if (isManager) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                AppTexts.manager,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...metadata.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeHelper.blackWhite(sheetContext),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppThemeHelper.border(
                            sheetContext,
                          ).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, size: 18, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppThemeHelper.textSecondary(
                                      sheetContext,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemeHelper.whiteBlack(
                                      sheetContext,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MemberUserTile extends StatelessWidget {
  final UserEntity user;
  final bool isSelected;
  final bool isManager;
  final bool showDepartment;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final _MemberTileMode mode;

  const _MemberUserTile({
    required this.user,
    required this.isSelected,
    required this.isManager,
    required this.onTap,
    required this.onLongPress,
    this.showDepartment = false,
    this.mode = _MemberTileMode.toggle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    final detailStyle = TextStyle(
      fontSize: 12.5,
      height: 1.25,
      color: AppThemeHelper.textSecondary(context),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withOpacity(0.14),
                foregroundColor: primary,
                child: Text(
                  _initialsFor(user),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppThemeHelper.whiteBlack(context),
                            ),
                          ),
                        ),
                        if (isManager) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              AppTexts.manager,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((user.email ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        user.email!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: detailStyle,
                      ),
                    ],
                    if ((user.phone ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: detailStyle,
                      ),
                    ],
                    if (showDepartment &&
                        user.department?.name.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.department!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: detailStyle,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _MemberSelectionIndicator(isSelected: isSelected, mode: mode),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberSelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final _MemberTileMode mode;

  const _MemberSelectionIndicator({
    required this.isSelected,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeHelper.buttonPrimary(context);
    final border = AppThemeHelper.border(context);

    if (mode == _MemberTileMode.selectedPreview) {
      final removeColor = AppThemeHelper.red(context);
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: removeColor.withOpacity(0.12),
          border: Border.all(color: removeColor.withOpacity(0.24)),
        ),
        child: Icon(Icons.remove_rounded, size: 18, color: removeColor),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? primary : Colors.transparent,
        border: Border.all(color: isSelected ? primary : border, width: 1.4),
      ),
      child: Icon(
        isSelected ? Icons.check_rounded : Icons.add_rounded,
        size: 18,
        color: isSelected ? Colors.white : primary,
      ),
    );
  }
}

Future<bool> _confirmMemberRemoval(
  BuildContext context,
  UserEntity user,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(AppTexts.removeMemberFromEventTitle),
        content: Text(
          '${AppTexts.removeMemberFromEventDescription}\n\n${user.fullName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppTexts.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppTexts.removeFromEvent),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

String _initialsFor(UserEntity user) {
  final parts = user.fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((element) => element.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

enum _MemberTileMode { toggle, selectedPreview }
