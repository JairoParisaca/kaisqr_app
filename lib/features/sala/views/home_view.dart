import 'package:flutter/material.dart';

import '../controllers/sala_controller.dart';
import '../services/sala_service.dart';
import 'sala_view.dart';
import 'scanner_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({required this.salaService, super.key});

  final SalaService salaService;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final SalaController _salaController;
  final TextEditingController _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _salaController = SalaController(widget.salaService);
    _salaController.addListener(_actualizarVista);
  }

  @override
  void dispose() {
    _salaController.removeListener(_actualizarVista);
    _salaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildJoinCard(context),
                    const SizedBox(height: 24),
                    _buildHelpText(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Kais QR',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Conecta tu celular a una sala para enviar documentos.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildJoinCard(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Entrar a una sala',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Escanea el QR que aparece en la página o escribe el código de seis dígitos.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                labelText: 'Código de sala',
                counterText: '',
                hintText: '000000',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _salaController.cargando ? null : _conectarPorCodigo,
              icon: _salaController.cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                _salaController.cargando
                    ? 'Conectando...'
                    : 'Entrar con código',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _salaController.cargando ? null : _abrirScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Escanear código QR'),
            ),
            if (_salaController.mensajeError != null) ...<Widget>[
              const SizedBox(height: 16),
              _buildError(_salaController.mensajeError!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHelpText(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.black45),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'La sala es temporal y se cierra después de enviar los documentos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _conectarPorCodigo() async {
    await _salaController.unirsePorCodigo(_codigoController.text);
    _abrirSalaSiCorresponde();
  }

  Future<void> _abrirScanner() async {
    final resultado = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const ScannerView()),
    );
    if (!mounted || resultado == null) return;

    await _salaController.unirsePorQr(resultado);
    _abrirSalaSiCorresponde();
  }

  void _abrirSalaSiCorresponde() {
    if (!mounted || !_salaController.salaConectada) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalaView(salaController: _salaController),
      ),
    );
  }

  void _actualizarVista() {
    if (mounted) setState(() {});
  }
}
