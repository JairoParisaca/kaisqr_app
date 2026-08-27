import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../sala/controllers/sala_controller.dart';
import '../models/documento_capturado.dart';

class CaptureController extends ChangeNotifier {
  CaptureController({required this.salaController, ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final SalaController salaController;
  final ImagePicker _imagePicker;
  final List<DocumentoCapturado> _documentos = <DocumentoCapturado>[];

  bool enviando = false;
  String? mensajeError;

  List<DocumentoCapturado> get documentos => List.unmodifiable(_documentos);

  Future<void> seleccionarImagen() =>
      _seleccionarImagenYReconectar(ImageSource.gallery);

  Future<void> recuperarCapturaPendiente() async {
    final resultado = await _imagePicker.retrieveLostData();
    if (resultado.isEmpty) return;

    if (resultado.files != null) {
      for (final imagen in resultado.files!) {
        agregarImagen(imagen);
      }
    }

    if (resultado.exception != null) {
      mensajeError = 'No se pudo recuperar la fotografía anterior.';
      notifyListeners();
    }
  }

  void eliminarDocumento(DocumentoCapturado documento) {
    _documentos.remove(documento);
    notifyListeners();
  }

  Future<bool> enviarDocumentos() async {
    if (enviando) return false;

    if (_documentos.isEmpty) {
      mensajeError = 'Captura al menos un documento antes de enviar.';
      notifyListeners();
      return false;
    }

    enviando = true;
    mensajeError = null;
    notifyListeners();

    try {
      for (final documento in _documentos) {
        if (documento.estado == EstadoDocumento.enviado) continue;

        if (!await documento.archivo.exists()) {
          throw StateError(
            'La fotografía ${documento.nombre} ya no está disponible en el dispositivo.',
          );
        }

        documento.estado = EstadoDocumento.enviando;
        notifyListeners();
        try {
          await salaController.enviarDocumento(
            documento.archivo,
            nombrePersonalizado: documento.nombre,
          );
          documento.estado = EstadoDocumento.enviado;
          documento.mensajeError = null;
        } catch (error) {
          documento.estado = EstadoDocumento.error;
          documento.mensajeError = error.toString();
          rethrow;
        }
        notifyListeners();
      }

      await salaController.finalizarSala();
      return true;
    } catch (error) {
      mensajeError = error.toString();
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  Future<void> _seleccionarImagenYReconectar(ImageSource source) async {
    try {
      await _seleccionarImagen(source);
    } finally {
      await salaController.reconectarSala();
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    mensajeError = null;
    try {
      final imagen = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2800,
      );
      if (imagen == null) return;

      agregarImagen(imagen);
    } on PlatformException catch (error) {
      mensajeError =
          'No se pudo abrir la cámara o la galería: ${error.message ?? error.code}';
      notifyListeners();
    }
  }

  void agregarImagen(XFile imagen) {
    final archivo = File(imagen.path);
    _documentos.add(
      DocumentoCapturado(archivo: archivo, nombre: _crearNombre(archivo)),
    );
    mensajeError = null;
    notifyListeners();
  }

  String _crearNombre(File archivo) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'documento_$timestamp.jpg';
  }
}
