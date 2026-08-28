import 'dart:io';

enum EstadoDocumento { pendiente, enviando, enviado, error }

enum TipoArchivo {
  imagen('imagen'),
  pdf('pdf');

  const TipoArchivo(this.valor);

  final String valor;
}

class PuntoPoligono {
  const PuntoPoligono({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, double> toJson() => <String, double>{'x': x, 'y': y};
}

class DocumentoCapturado {
  DocumentoCapturado({
    required this.archivo,
    required this.nombre,
    File? archivoOriginal,
    this.tipoArchivo = TipoArchivo.imagen,
    this.lotePdfId,
    this.nombrePdf,
    List<PuntoPoligono> poligono = const <PuntoPoligono>[],
    this.estado = EstadoDocumento.pendiente,
    this.mensajeError,
  }) : archivoOriginal = archivoOriginal ?? archivo,
       poligono = List<PuntoPoligono>.unmodifiable(poligono);

  final File archivo;
  final File archivoOriginal;
  final String nombre;
  final TipoArchivo tipoArchivo;
  final String? lotePdfId;
  final String? nombrePdf;
  final List<PuntoPoligono> poligono;
  EstadoDocumento estado;
  String? mensajeError;
}
