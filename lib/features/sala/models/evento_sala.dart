class EventoSala {
  const EventoSala({
    required this.tipo,
    this.estado,
    this.mensaje,
    this.nombre,
    this.cantidadDocumentos,
  });

  final String tipo;
  final String? estado;
  final String? mensaje;
  final String? nombre;
  final int? cantidadDocumentos;

  factory EventoSala.desdeJson(Map<String, dynamic> json) {
    return EventoSala(
      tipo: json['tipo']?.toString() ?? 'mensaje_desconocido',
      estado: json['estado']?.toString(),
      mensaje: json['mensaje']?.toString(),
      nombre: json['nombre']?.toString(),
      cantidadDocumentos: json['cantidad_documentos'] is int
          ? json['cantidad_documentos'] as int
          : int.tryParse(json['cantidad_documentos']?.toString() ?? ''),
    );
  }
}
