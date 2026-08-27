class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.webSocketUrl,
    required this.apiKey,
  });

  final String apiUrl;
  final String webSocketUrl;
  final String apiKey;

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiUrl: String.fromEnvironment(
        'KAISQR_API_URL',
        defaultValue: 'http://192.168.88.85:8000/api/v1',
      ),
      webSocketUrl: String.fromEnvironment(
        'KAISQR_WS_URL',
        defaultValue: 'ws://192.168.88.85:8000/api/v1/ws/v1',
      ),
      apiKey: String.fromEnvironment(
        'KAISQR_API_KEY',
        defaultValue: 'development-key',
      ),
    );
  }
}
