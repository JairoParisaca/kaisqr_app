import 'dart:io';

import 'package:flutter/foundation.dart';
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

  Future<void> capturarDocumento() => _seleccionarImagen(ImageSource.camera);

  Future<void> seleccionarImagen() => _seleccionarImagen(ImageSource.gallery);

  void eliminarDocumento(DocumentoCapturado documento) {
    _documentos.remove(documento);
    notifyListeners();
  }

  Future<bool> enviarDocumentos() async {
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

  Future<void> _seleccionarImagen(ImageSource source) async {
    mensajeError = null;
    final imagen = await _imagePicker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2800,
    );
    if (imagen == null) return;

    final archivo = File(imagen.path);
    _documentos.add(
      DocumentoCapturado(archivo: archivo, nombre: _crearNombre(archivo)),
    );
    notifyListeners();
  }

  String _crearNombre(File archivo) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'documento_$timestamp.jpg';
  }
}
