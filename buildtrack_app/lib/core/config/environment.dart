abstract class FlavorConfig {
  static const String dev = 'dev';
  static const String staging = 'staging';
  static const String prod = 'prod';
}

class AppConfig {
  final String flavor;
  final String appName;
  final bool enableLogs;

  AppConfig({
    required this.flavor,
    required this.appName,
    required this.enableLogs,
  });


  factory AppConfig.dev() => AppConfig(
    flavor: FlavorConfig.dev,
    appName: 'BuildTrack Dev',
    enableLogs: true,
  );

  factory AppConfig.staging() => AppConfig(
    flavor: FlavorConfig.staging,
    appName: 'BuildTrack Staging',
    enableLogs: true,
  );

  factory AppConfig.prod() => AppConfig(
    flavor: FlavorConfig.prod,
    appName: 'BuildTrack',
    enableLogs: false,
  );
}