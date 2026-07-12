class AppSettingsModel {
  final String version;
  final String appUrl;
  final bool isVersionRequired;

  AppSettingsModel({
    required this.version,
    required this.appUrl,
    required this.isVersionRequired,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      version: json['version']?.toString() ?? '',
      appUrl: json['app_url']?.toString() ?? '',
      isVersionRequired:
          json['is_verison_required']?.toString().toLowerCase() == 'true',
    );
  }
}
