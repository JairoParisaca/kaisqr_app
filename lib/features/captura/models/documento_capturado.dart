import 'dart:io';

enum EstadoDocumento { pendiente, enviando, enviado, error }

class DocumentoCapturado {
  DocumentoCapturado({
    required this.archivo,
    required this.nombre,
    this.estado = EstadoDocumento.pendiente,
    this.mensajeError,
  });

  final File archivo;
  final String nombre;
  EstadoDocumento estado;
  String? mensajeError;
}
