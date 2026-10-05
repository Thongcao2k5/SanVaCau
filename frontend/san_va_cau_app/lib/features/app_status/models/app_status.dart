class AppStatus {
  const AppStatus({
    required this.platform,
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.maintenanceMode,
    this.maintenanceMessage,
    required this.updateRequired,
    required this.updateAvailable,
    this.updateMessage,
    this.storeUrl,
  });

  final String platform;
  final String currentVersion;
  final String latestVersion;
  final String minimumSupportedVersion;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final bool updateRequired;
  final bool updateAvailable;
  final String? updateMessage;
  final String? storeUrl;

  factory AppStatus.fromJson(Map<String, dynamic> json) {
    return AppStatus(
      platform: json['platform']?.toString() ?? '',
      currentVersion: json['currentVersion']?.toString() ?? '',
      latestVersion: json['latestVersion']?.toString() ?? '',
      minimumSupportedVersion:
          json['minimumSupportedVersion']?.toString() ?? '',
      maintenanceMode: json['maintenanceMode'] == true,
      maintenanceMessage: json['maintenanceMessage']?.toString(),
      updateRequired: json['updateRequired'] == true,
      updateAvailable: json['updateAvailable'] == true,
      updateMessage: json['updateMessage']?.toString(),
      storeUrl: json['storeUrl']?.toString(),
    );
  }
}
