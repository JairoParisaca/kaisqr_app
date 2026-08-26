// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:kais_qr_app/app.dart';
import 'package:kais_qr_app/core/config/app_config.dart';
import 'package:kais_qr_app/core/network/api_client.dart';
import 'package:kais_qr_app/core/network/web_socket_client.dart';
import 'package:kais_qr_app/features/sala/services/sala_service.dart';

void main() {
  testWidgets('AppRoot renders the room entry screen', (
    WidgetTester tester,
  ) async {
    const config = AppConfig(
      apiUrl: 'http://localhost:8000/api/v1',
      webSocketUrl: 'ws://localhost:8000/api/v1/ws/v1',
      apiKey: 'test-key',
    );
    final salaService = SalaService(
      apiClient: ApiClient(config: config),
      webSocketClient: WebSocketClient(),
      config: config,
    );

    await tester.pumpWidget(AppRoot(salaService: salaService));

    expect(find.text('Kais QR'), findsOneWidget);
    expect(find.text('Escanear código QR'), findsOneWidget);
  });
}
