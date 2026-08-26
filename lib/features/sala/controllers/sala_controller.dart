import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/evento_sala.dart';
import '../models/sala.dart';
import '../services/sala_service.dart';

class SalaController extends ChangeNotifier {
  SalaController(this._salaService);

  final SalaService _salaService;
  StreamSubscription<EventoSala>? _eventSubscription;

  Sala? salaActual;
  bool cargando = false;
  bool enviando = false;
  String mensajeEstado = 'Ingresa un código o escanea un QR para comenzar.';
  String? mensajeError;
  int cantidadDocumentos = 0;

  bool get salaConectada => salaActual != null;

  Future<void> unirsePorCodigo(String codigo) async {
    final codigoNormalizado = codigo.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(codigoNormalizado)) {
      mensajeError = 'El código debe tener exactamente 6 números.';
      notifyListeners();
      return;
    }

    await _ejecutarIngreso(
      () => _salaService.unirsePorCodigo(codigoNormalizado),
    );
  }

  Future<void> unirsePorQr(String contenidoQr) async {
    await _ejecutarIngreso(() async => _salaService.unirsePorQr(contenidoQr));
  }

  Future<void> enviarDocumento(
    File archivo, {
    String? nombrePersonalizado,
  }) async {
    final sala = salaActual;
    if (sala == null) throw StateError('No existe una sala activa');

    await _salaService.registrarDocumento(
      sala: sala,
      archivo: archivo,
      nombrePersonalizado: nombrePersonalizado,
    );
    cantidadDocumentos += 1;
    mensajeEstado = 'Documento enviado ($cantidadDocumentos).';
    notifyListeners();
  }

  Future<void> finalizarSala() async {
    final sala = salaActual;
    if (sala == null) throw StateError('No existe una sala activa');

    enviando = true;
    mensajeError = null;
    mensajeEstado = 'Finalizando la sala...';
    notifyListeners();

    try {
      final respuesta = await _salaService.finalizarSala(sala);
      mensajeEstado =
          respuesta['mensaje']?.toString() ?? 'Sala finalizada correctamente.';
    } catch (error) {
      mensajeError = _obtenerMensajeError(error);
      rethrow;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    mensajeError = null;
    notifyListeners();
  }

  Future<void> salirSala() async {
    if (salaActual == null && _eventSubscription == null) return;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _salaService.cerrarSala();
    salaActual = null;
    cantidadDocumentos = 0;
    mensajeEstado = 'Sala cerrada.';
    notifyListeners();
  }

  Future<void> _ejecutarIngreso(Future<Sala> Function() ingresar) async {
    cargando = true;
    mensajeError = null;
    mensajeEstado = 'Conectando con la sala...';
    notifyListeners();

    try {
      await _eventSubscription?.cancel();
      final sala = await ingresar();
      salaActual = sala;
      final eventos = await _salaService.conectarSala(sala);
      _eventSubscription = eventos.listen(
        _procesarEvento,
        onError: (Object error) {
          mensajeError = _obtenerMensajeError(error);
          notifyListeners();
        },
      );
      mensajeEstado = 'Conectado. Esperando documentos.';
    } catch (error) {
      salaActual = null;
      mensajeError = _obtenerMensajeError(error);
      mensajeEstado = 'No fue posible conectarse a la sala.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void _procesarEvento(EventoSala evento) {
    if (evento.tipo == 'sala_conectada') {
      mensajeEstado = 'Sala conectada. Ya puedes capturar documentos.';
    } else if (evento.tipo == 'documento_recibido') {
      cantidadDocumentos = evento.cantidadDocumentos ?? cantidadDocumentos;
      mensajeEstado = 'El servidor recibió un documento.';
    } else if (evento.tipo == 'estado_sala') {
      mensajeEstado = evento.mensaje ?? evento.estado ?? mensajeEstado;
    }
    notifyListeners();
  }

  String _obtenerMensajeError(Object error) {
    final texto = error.toString();
    return texto.startsWith('ApiException') ? texto.split(': ').last : texto;
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    unawaited(_salaService.cerrarSala());
    super.dispose();
  }
}
