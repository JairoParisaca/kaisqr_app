import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/documento_capturado.dart';

class PolygonEditorView extends StatefulWidget {
  const PolygonEditorView({required this.archivo, super.key});

  final File archivo;

  @override
  State<PolygonEditorView> createState() => _PolygonEditorViewState();
}

class _PolygonEditorViewState extends State<PolygonEditorView> {
  ui.Image? _imagen;
  List<PuntoPoligono> _puntos = List<PuntoPoligono>.of(_puntosIniciales());
  bool _cargando = true;
  String? _mensajeError;
  int? _puntoActivo;

  bool get _tienePuntosIntermedios => _puntos.length == 8;

  @override
  void initState() {
    super.initState();
    _cargarImagen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ajustar hoja'),
        actions: <Widget>[
          IconButton(
            onPressed: _cargando ? null : _restablecerPuntos,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restablecer esquinas',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: _buildEditor()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Ajusta las cuatro esquinas. Puedes agregar puntos intermedios si necesitas corregir mejor los bordes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cargando || _mensajeError != null
                        ? null
                        : _alternarPuntosIntermedios,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    icon: Icon(
                      _tienePuntosIntermedios
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                    ),
                    label: Text(
                      _tienePuntosIntermedios
                          ? 'Quitar puntos intermedios'
                          : 'Agregar puntos intermedios',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargando || _mensajeError != null
                          ? null
                          : _aceptarPoligono,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Aceptar recorte'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_mensajeError != null || _imagen == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _mensajeError ?? 'No se pudo cargar la imagen.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final area = Size(constraints.maxWidth, constraints.maxHeight);
        final rect = _obtenerRectanguloImagen(area);
        final puntosEnPantalla = _puntos
            .map((punto) => _aCoordenadaPantalla(punto, rect))
            .toList();

        return SizedBox(
          width: area.width,
          height: area.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              _puntoActivo = _obtenerPuntoCercano(
                details.localPosition,
                puntosEnPantalla,
              );
            },
            onPanUpdate: (details) {
              final indice = _puntoActivo;
              if (indice == null) return;

              setState(() {
                _puntos[indice] = _aCoordenadaNormalizada(
                  details.localPosition,
                  rect,
                );
              });
            },
            onPanEnd: (_) => _puntoActivo = null,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned.fromRect(
                  rect: rect,
                  child: Image.file(widget.archivo, fit: BoxFit.fill),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PolygonPainter(
                      puntos: puntosEnPantalla,
                      imagenRectangulo: rect,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cargarImagen() async {
    try {
      final bytes = await widget.archivo.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();

      if (!mounted) return;
      setState(() {
        _imagen = frame.image;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensajeError = 'No se pudo preparar la imagen: $error';
      });
    }
  }

  Rect _obtenerRectanguloImagen(Size area) {
    final imagen = _imagen!;
    final proporcion = imagen.width / imagen.height;
    var ancho = area.width;
    var alto = ancho / proporcion;

    if (alto > area.height) {
      alto = area.height;
      ancho = alto * proporcion;
    }

    return Rect.fromLTWH(
      (area.width - ancho) / 2,
      (area.height - alto) / 2,
      ancho,
      alto,
    );
  }

  Offset _aCoordenadaPantalla(PuntoPoligono punto, Rect rect) {
    return Offset(
      rect.left + punto.x * rect.width,
      rect.top + punto.y * rect.height,
    );
  }

  PuntoPoligono _aCoordenadaNormalizada(Offset punto, Rect rect) {
    return PuntoPoligono(
      x: ((punto.dx - rect.left) / rect.width).clamp(0.0, 1.0).toDouble(),
      y: ((punto.dy - rect.top) / rect.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  int? _obtenerPuntoCercano(Offset posicion, List<Offset> puntos) {
    const distanciaMaxima = 42.0;
    int? indiceEncontrado;
    var distanciaEncontrada = distanciaMaxima * distanciaMaxima;

    for (var indice = 0; indice < puntos.length; indice++) {
      final distancia = (puntos[indice] - posicion).distanceSquared;
      if (distancia <= distanciaEncontrada) {
        indiceEncontrado = indice;
        distanciaEncontrada = distancia;
      }
    }

    return indiceEncontrado;
  }

  void _restablecerPuntos() {
    setState(() => _puntos = List<PuntoPoligono>.of(_puntosIniciales()));
  }

  void _alternarPuntosIntermedios() {
    setState(() {
      if (_tienePuntosIntermedios) {
        _puntos = <PuntoPoligono>[
          _puntos[0],
          _puntos[2],
          _puntos[4],
          _puntos[6],
        ];
        return;
      }

      final esquinas = List<PuntoPoligono>.of(_puntos);
      _puntos = <PuntoPoligono>[
        esquinas[0],
        _puntoMedio(esquinas[0], esquinas[1]),
        esquinas[1],
        _puntoMedio(esquinas[1], esquinas[2]),
        esquinas[2],
        _puntoMedio(esquinas[2], esquinas[3]),
        esquinas[3],
        _puntoMedio(esquinas[3], esquinas[0]),
      ];
    });
  }

  PuntoPoligono _puntoMedio(PuntoPoligono primero, PuntoPoligono segundo) {
    return PuntoPoligono(
      x: (primero.x + segundo.x) / 2,
      y: (primero.y + segundo.y) / 2,
    );
  }

  void _aceptarPoligono() {
    Navigator.of(context).pop(List<PuntoPoligono>.of(_puntos));
  }

  static List<PuntoPoligono> _puntosIniciales() {
    return const <PuntoPoligono>[
      PuntoPoligono(x: 0.05, y: 0.05),
      PuntoPoligono(x: 0.95, y: 0.05),
      PuntoPoligono(x: 0.95, y: 0.95),
      PuntoPoligono(x: 0.05, y: 0.95),
    ];
  }
}

class _PolygonPainter extends CustomPainter {
  const _PolygonPainter({required this.puntos, required this.imagenRectangulo});

  final List<Offset> puntos;
  final Rect imagenRectangulo;

  @override
  void paint(Canvas canvas, Size size) {
    final relleno = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final borde = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final punto = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final bordePunto = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final ruta = Path()..addPolygon(puntos, true);
    canvas.drawPath(ruta, relleno);
    canvas.drawPath(ruta, borde);

    final indicesEsquinas = puntos.length == 8
        ? <int>{0, 2, 4, 6}
        : <int>{0, 1, 2, 3};
    for (var indice = 0; indice < puntos.length; indice++) {
      final coordenada = puntos[indice];
      final esEsquina = indicesEsquinas.contains(indice);
      final radio = esEsquina ? 15.0 : 10.0;
      final pinturaPunto = esEsquina
          ? punto
          : (Paint()
              ..color = Colors.amberAccent
              ..style = PaintingStyle.fill);
      canvas.drawCircle(coordenada, radio, pinturaPunto);
      canvas.drawCircle(coordenada, radio, bordePunto);
    }

    final marco = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(imagenRectangulo, marco);
  }

  @override
  bool shouldRepaint(_PolygonPainter oldDelegate) {
    return oldDelegate.puntos != puntos ||
        oldDelegate.imagenRectangulo != imagenRectangulo;
  }
}
