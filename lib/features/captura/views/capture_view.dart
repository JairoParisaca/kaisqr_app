import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../sala/controllers/sala_controller.dart';
import '../controllers/capture_controller.dart';
import '../models/documento_capturado.dart';
import 'camera_capture_view.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({
    required this.salaController,
    required this.onCompleted,
    super.key,
  });

  final SalaController salaController;
  final Future<void> Function() onCompleted;

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  late final CaptureController _captureController;

  @override
  void initState() {
    super.initState();
    _captureController = CaptureController(
      salaController: widget.salaController,
    );
    _captureController.addListener(_actualizarVista);
    unawaited(_captureController.recuperarCapturaPendiente());
  }

  @override
  void dispose() {
    _captureController.removeListener(_actualizarVista);
    _captureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: <Widget>[
          Expanded(child: _buildDocumentos(context)),
          if (_captureController.mensajeError != null) ...<Widget>[
            const SizedBox(height: 8),
            _buildError(_captureController.mensajeError!),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _captureController.enviando
                      ? null
                      : _captureController.seleccionarImagen,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _captureController.enviando ? null : _abrirCamara,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Cámara'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed:
                _captureController.enviando ||
                    _captureController.documentos.isEmpty
                ? null
                : _enviarDocumentos,
            icon: _captureController.enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _captureController.enviando ? 'Enviando...' : 'Enviar documentos',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentos(BuildContext context) {
    final documentos = _captureController.documentos;
    if (documentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.document_scanner_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Todavía no hay documentos'),
            const SizedBox(height: 6),
            const Text(
              'Toma una fotografía para comenzar.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: documentos.length,
      itemBuilder: (context, index) =>
          _buildDocumentoCard(context, documentos[index]),
    );
  }

  Widget _buildDocumentoCard(
    BuildContext context,
    DocumentoCapturado documento,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Image.file(File(documento.archivo.path), fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    documento.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _captureController.enviando
                      ? null
                      : () => _captureController.eliminarDocumento(documento),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
          _buildDocumentStatus(documento),
        ],
      ),
    );
  }

  Widget _buildDocumentStatus(DocumentoCapturado documento) {
    final (Color color, String label) = switch (documento.estado) {
      EstadoDocumento.pendiente => (Colors.black54, 'Pendiente'),
      EstadoDocumento.enviando => (Colors.orange, 'Enviando'),
      EstadoDocumento.enviado => (Colors.green, 'Enviado'),
      EstadoDocumento.error => (Colors.red, 'Error'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }

  Future<void> _enviarDocumentos() async {
    final completado = await _captureController.enviarDocumentos();
    if (completado && mounted) await widget.onCompleted();
  }

  void _actualizarVista() {
    if (mounted) setState(() {});
  }

  Future<void> _abrirCamara() async {
    final imagen = await Navigator.of(context).push<XFile>(
      MaterialPageRoute<XFile>(builder: (_) => const CameraCaptureView()),
    );

    if (!mounted || imagen == null) return;
    _captureController.agregarImagen(imagen);
  }
}
