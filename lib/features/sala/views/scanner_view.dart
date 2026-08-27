import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
  );
  bool _codigoDetectado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_iniciarScanner());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      if (_scannerController.value.isRunning) {
        unawaited(_scannerController.stop());
      }
    } else if (state == AppLifecycleState.resumed && !_codigoDetectado) {
      unawaited(_iniciarScanner());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear sala'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            onPressed: () => _scannerController.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
            tooltip: 'Linterna',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _scannerController,
            onDetect: _procesarLectura,
          ),
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _codigoDetectado
                    ? 'Código encontrado...'
                    : 'Apunta la cámara al QR de la sala.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _procesarLectura(BarcodeCapture capture) {
    if (_codigoDetectado) return;

    for (final barcode in capture.barcodes) {
      final contenido = barcode.rawValue;
      if (contenido == null || contenido.trim().isEmpty) continue;

      _codigoDetectado = true;
      setState(() {});
      unawaited(_cerrarTrasLectura(contenido));
      return;
    }
  }

  Future<void> _cerrarTrasLectura(String contenido) async {
    if (_scannerController.value.isRunning) {
      await _scannerController.stop();
    }
    if (mounted) Navigator.of(context).pop(contenido);
  }

  Future<void> _iniciarScanner() async {
    if (_codigoDetectado ||
        _scannerController.value.isRunning ||
        _scannerController.value.isStarting) {
      return;
    }

    try {
      await _scannerController.start();
    } on MobileScannerException {
      // Una transición de ciclo de vida no debe dejar una excepción sin atender.
    }
  }
}
