import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({
    this.titulo = 'Capturar documento',
    this.permitirVarias = false,
    super.key,
  });

  final String titulo;
  final bool permitirVarias;

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();

  static Future<void> precargarCamaras() {
    return _CameraCaptureViewState.precargarCamaras();
  }
}

class _CameraCaptureViewState extends State<CameraCaptureView>
    with WidgetsBindingObserver {
  static Future<List<CameraDescription>>? _camarasDisponibles;

  static Future<void> precargarCamaras() async {
    try {
      await _obtenerCamaras();
    } catch (_) {
      // La inicialización real mostrará el mensaje correspondiente si falla.
    }
  }

  CameraController? _cameraController;
  bool _cargando = true;
  bool _capturando = false;
  bool _inicializando = false;
  bool _liberando = false;
  String? _mensajeError;
  final List<XFile> _capturas = <XFile>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_inicializarCamara());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      unawaited(_liberarCamara());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_inicializarCamara());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_liberarCamara());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.titulo),
        actions: <Widget>[
          IconButton(
            onPressed: _cargando ? null : _finalizarCapturas,
            icon: Icon(
              widget.permitirVarias
                  ? Icons.check_rounded
                  : Icons.close_rounded,
            ),
            tooltip: widget.permitirVarias
                ? 'Terminar capturas'
                : 'Cerrar cámara',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: _buildVistaCamara()),
            _buildControles(),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaCamara() {
    final controller = _cameraController;
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_mensajeError != null || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _mensajeError ?? 'La cámara no está disponible.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Center(child: CameraPreview(controller));
  }

  Widget _buildControles() {
    final puedeCapturar =
        !_cargando &&
        _mensajeError == null &&
        _cameraController?.value.isInitialized == true &&
        !_capturando;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: <Widget>[
          const Text(
            'Centra el documento y toma la fotografía.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (widget.permitirVarias) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Páginas capturadas: ${_capturas.length}. Puedes continuar o finalizar.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: puedeCapturar ? _capturarImagen : null,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: puedeCapturar ? Colors.white : Colors.white38,
                border: Border.all(color: Colors.white70, width: 5),
              ),
              child: _capturando
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _inicializarCamara() async {
    if (!mounted ||
        _cameraController != null ||
        _inicializando ||
        _liberando) {
      return;
    }

    _inicializando = true;

    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      final cameras = await _obtenerCamaras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No se encontró una cámara.');
      }

      final camaraTrasera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camaraTrasera,
        // Medium abre la cámara más rápido y sigue siendo suficiente para
        // capturar documentos que luego serán recortados y convertidos a PDF.
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() => _cargando = false);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensajeError = _mensajeCamara(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensajeError = 'No se pudo inicializar la cámara: $error';
      });
    } finally {
      _inicializando = false;
    }
  }

  static Future<List<CameraDescription>> _obtenerCamaras() async {
    final cache = _camarasDisponibles;
    if (cache != null) return cache;

    final consulta = availableCameras();
    _camarasDisponibles = consulta;
    try {
      return await consulta;
    } catch (_) {
      _camarasDisponibles = null;
      rethrow;
    }
  }

  Future<void> _capturarImagen() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _capturando) {
      return;
    }

    setState(() => _capturando = true);
    try {
      final imagen = await controller.takePicture();
      if (!mounted) return;

      if (widget.permitirVarias) {
        setState(() {
          _capturas.add(imagen);
          _capturando = false;
        });
      } else {
        Navigator.of(context).pop(imagen);
      }
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _capturando = false;
          _mensajeError = _mensajeCamara(error);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _capturando = false;
          _mensajeError = 'No se pudo capturar la fotografía: $error';
        });
      }
    }
  }

  void _finalizarCapturas() {
    if (widget.permitirVarias) {
      if (_capturas.isEmpty) {
        Navigator.of(context).pop(<XFile>[]);
      } else {
        Navigator.of(context).pop(List<XFile>.of(_capturas));
      }
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _liberarCamara() async {
    if (_liberando) return;

    _liberando = true;
    final controller = _cameraController;
    _cameraController = null;
    try {
      await controller?.dispose();
    } finally {
      _liberando = false;
    }
  }

  String _mensajeCamara(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' =>
        'Permite el acceso a la cámara para capturar documentos.',
      'CameraAccessRestricted' => 'El acceso a la cámara está restringido.',
      _ => error.description ?? 'La cámara no está disponible.',
    };
  }
}
