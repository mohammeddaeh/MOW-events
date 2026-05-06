import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/alarm_ringtone_settings_controller.dart';

class AlarmRingtoneSettingsScreen extends StatelessWidget {
  const AlarmRingtoneSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.alarmRingtoneScreenTitle)),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: AlarmRingtoneSettingsSection(compact: false),
      ),
    );
  }
}

class AlarmRingtoneSettingsSection extends StatefulWidget {
  const AlarmRingtoneSettingsSection({super.key, this.compact = true});
  final bool compact;

  @override
  State<AlarmRingtoneSettingsSection> createState() =>
      _AlarmRingtoneSettingsSectionState();
}

class _AlarmRingtoneSettingsSectionState
    extends State<AlarmRingtoneSettingsSection> {
  late final String _tag;
  late final AlarmRingtoneSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _tag = 'alarm_ringtone_section_${identityHashCode(this)}';
    _controller = Get.put(AlarmRingtoneSettingsController(), tag: _tag);
  }

  @override
  void dispose() {
    if (Get.isRegistered<AlarmRingtoneSettingsController>(tag: _tag)) {
      Get.delete<AlarmRingtoneSettingsController>(tag: _tag);
    }
    super.dispose();
  }

  Future<void> _openRingtoneBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _buildSheetContainer(sheetContext),
      ),
    );
  }

  Widget _buildSheetContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemeHelper.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: SingleChildScrollView(
            child: Obx(() => _buildSheetContent(context, _controller)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final primary = AppThemeHelper.buttonPrimary(context);
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!_controller.isAndroid) return const SizedBox.shrink();

      if (widget.compact) {
        return Container(
          decoration: BoxDecoration(
            color: AppThemeHelper.blackWhite(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppThemeHelper.border(context)),
          ),

          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.music_note_rounded, color: primary),
            ),
            title: Text(
              AppTexts.alarmSoundSettingsTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppThemeHelper.whiteBlack(context),
              ),
            ),
            subtitle: Text(
              _controller.statusLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppThemeHelper.textSecondary(context),
                fontSize: 12.5,
              ),
            ),
            trailing: Icon(Icons.tune_rounded, color: primary),
            onTap: _controller.isBusy.value
                ? null
                : () => _openRingtoneBottomSheet(context),
          ),
        );
      }

      return _buildSheetContent(context, _controller);
    });
  }

  Widget _buildSheetContent(
    BuildContext context,
    AlarmRingtoneSettingsController c,
  ) {
    final primary = AppThemeHelper.buttonPrimary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppThemeHelper.border(context),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppTexts.alarmSoundSettingsTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppThemeHelper.whiteBlack(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppTexts.alarmSoundSettingsSubtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: AppThemeHelper.textSecondary(context),
          ),
        ),

        const SizedBox(height: 8),
        _tile(
          context,
          icon: Icons.alarm_rounded,
          text: AppTexts.alarmRingtoneUseSystemDefault,
          selected: c.isDefaultSelected,
          onTap: c.chooseDefaultTone,
        ),
        _tile(
          context,
          icon: Icons.library_music_outlined,
          text: AppTexts.alarmRingtoneChooseFromPhone,
          selected: c.isDeviceSelected,
          onTap: c.chooseFromDeviceTones,
        ),
        _tile(
          context,
          icon: Icons.folder_open_rounded,
          text: AppTexts.alarmRingtoneChooseFromFile,
          selected: c.isStorageSelected,
          onTap: c.chooseFromStorageFile,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: c.isBusy.value ? null : c.togglePreview,
            icon: Icon(
              c.isPreviewPlaying.value
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
              color: primary,
            ),
            label: Text(
              c.isPreviewPlaying.value
                  ? AppTexts.alarmRingtoneStopPreviewButton
                  : AppTexts.alarmRingtonePreviewButton,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary),
              foregroundColor: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primary = AppThemeHelper.buttonPrimary(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: primary),
      title: Text(text),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: primary)
          : Icon(Icons.chevron_right_rounded, color: primary),
      enabled: !_controller.isBusy.value,
      onTap: onTap,
    );
  }
}
