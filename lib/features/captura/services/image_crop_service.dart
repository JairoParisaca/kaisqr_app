import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image_library;

import '../models/documento_capturado.dart';

class ImageCropService {
  Future<File> recortarDocumento({
    required File archivo,
    required List<PuntoPoligono> poligono,
  }) async {
    if (poligono.length < 4) {
      throw StateError('El recorte necesita al menos cuatro puntos.');
    }

    final bytes = await archivo.readAsBytes();
    final decodificada = image_library.decodeImage(bytes);
    if (decodificada == null) {
      throw StateError('No se pudo leer la imagen capturada.');
    }

    final orientada = image_library.bakeOrientation(decodificada);
    final imagen = orientada.numChannels == 3
        ? orientada
        : orientada.convert(numChannels: 3);
    final puntos = poligono
        .map(
          (punto) => image_library.Point(
            punto.x * imagen.width,
            punto.y * imagen.height,
          ),
        )
        .toList();
    final esquinas = _obtenerEsquinas(puntos);
    final contorno = puntos.length >= 8
        ? puntos.take(8).toList()
        : esquinas;
    final imagenEnmascarada = _enmascararFueraDelContorno(imagen, contorno);

    final ancho = math.max(
      1,
      math.max(
        _distancia(esquinas[0], esquinas[1]),
        _distancia(esquinas[3], esquinas[2]),
      ).round(),
    ).toInt();
    final alto = math.max(
      1,
      math.max(
        _distancia(esquinas[0], esquinas[3]),
        _distancia(esquinas[1], esquinas[2]),
      ).round(),
    ).toInt();

    final recortada = image_library.copyRectify(
      imagenEnmascarada,
      topLeft: esquinas[0],
      topRight: esquinas[1],
      bottomLeft: esquinas[3],
      bottomRight: esquinas[2],
      interpolation: image_library.Interpolation.cubic,
      toImage: image_library.Image(width: ancho, height: alto, numChannels: 3),
    );
    final rutaRecortada = File('${archivo.path}.recortado.jpg');
    await rutaRecortada.writeAsBytes(
      image_library.encodeJpg(recortada, quality: 90),
      flush: true,
    );
    return rutaRecortada;
  }

  static List<image_library.Point> _obtenerEsquinas(
    List<image_library.Point> puntos,
  ) {
    if (puntos.length >= 8) {
      return <image_library.Point>[puntos[0], puntos[2], puntos[4], puntos[6]];
    }
    return puntos.take(4).toList();
  }

  static image_library.Image _enmascararFueraDelContorno(
    image_library.Image imagen,
    List<image_library.Point> contorno,
  ) {
    final resultado = image_library.Image.from(imagen, noAnimation: true);
    for (var y = 0; y < resultado.height; y++) {
      for (var x = 0; x < resultado.width; x++) {
        if (!_estaDentroDelPoligono(x + 0.5, y + 0.5, contorno)) {
          resultado.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
    }
    return resultado;
  }

  static bool _estaDentroDelPoligono(
    double x,
    double y,
    List<image_library.Point> puntos,
  ) {
    var dentro = false;
    for (var indice = 0; indice < puntos.length; indice++) {
      final siguiente = (indice + 1) % puntos.length;
      final actual = puntos[indice];
      final proximo = puntos[siguiente];
      final cruzaHorizontalmente = (actual.y > y) != (proximo.y > y);
      if (!cruzaHorizontalmente) continue;

      final interseccion =
          (proximo.x - actual.x) * (y - actual.y) /
              (proximo.y - actual.y) +
          actual.x;
      if (x < interseccion) dentro = !dentro;
    }
    return dentro;
  }

  static double _distancia(
    image_library.Point primero,
    image_library.Point segundo,
  ) {
    final diferenciaX = segundo.x - primero.x;
    final diferenciaY = segundo.y - primero.y;
    return math.sqrt(
      (diferenciaX * diferenciaX) + (diferenciaY * diferenciaY),
    ).toDouble();
  }
}
