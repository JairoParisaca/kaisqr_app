class Sala {
  const Sala({
    required this.salaId,
    required this.codigo,
    required this.token,
    required this.websocketUrl,
    required this.expiraEn,
    this.estado = 'abierta',
  });

  final String salaId;
  final String codigo;
  final String token;
  final String websocketUrl;
  final DateTime? expiraEn;
  final String estado;

  factory Sala.desdeRespuestaServidor(
    Map<String, dynamic> respuesta,
    String webSocketBaseUrl,
  ) {
    final salaId = respuesta['sala_id']?.toString();
    final codigo = respuesta['codigo']?.toString();
    final token = respuesta['token']?.toString();

    if (salaId == null || codigo == null || token == null) {
      throw const FormatException('La respuesta de la sala está incompleta');
    }

    return Sala(
      salaId: salaId,
      codigo: codigo,
      token: token,
      websocketUrl: _crearWebSocketUrl(webSocketBaseUrl, salaId, token),
      expiraEn: _parsearFecha(respuesta['expira_en']),
      estado: respuesta['estado']?.toString() ?? 'abierta',
    );
  }

  factory Sala.desdePayloadQr(
    Map<String, dynamic> payload,
    String webSocketBaseUrl,
  ) {
    final salaId = payload['sala_id']?.toString();
    final codigo = payload['codigo']?.toString();
    final token = payload['token']?.toString();

    if (salaId == null || codigo == null || token == null) {
      throw const FormatException('El QR no contiene una sala válida');
    }

    return Sala(
      salaId: salaId,
      codigo: codigo,
      token: token,
      websocketUrl: _crearWebSocketUrl(webSocketBaseUrl, salaId, token),
      expiraEn: null,
    );
  }

  static String _crearWebSocketUrl(
    String baseUrl,
    String salaId,
    String token,
  ) {
    final base = baseUrl.replaceFirst(RegExp(r'\/$'), '');
    return '$base/salas/$salaId?token=${Uri.encodeQueryComponent(token)}';
  }

  static DateTime? _parsearFecha(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
