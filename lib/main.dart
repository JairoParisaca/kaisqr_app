import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/network/web_socket_client.dart';
import 'features/sala/services/sala_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final apiClient = ApiClient(config: config);
  final webSocketClient = WebSocketClient();
  final salaService = SalaService(
    apiClient: apiClient,
    webSocketClient: webSocketClient,
    config: config,
  );

  runApp(AppRoot(salaService: salaService));
}
