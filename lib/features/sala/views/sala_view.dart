import 'package:flutter/material.dart';

import '../../captura/views/capture_view.dart';
import '../controllers/sala_controller.dart';

class SalaView extends StatelessWidget {
  const SalaView({required this.salaController, super.key});

  final SalaController salaController;

  @override
  Widget build(BuildContext context) {
    final sala = salaController.salaActual;
    if (sala == null) {
      return const Scaffold(
        body: Center(child: Text('La sala ya no está disponible.')),
      );
    }

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) salaController.salirSala();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sala ${sala.codigo}'),
          leading: IconButton(
            onPressed: () async {
              await salaController.salirSala();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: ListenableBuilder(
          listenable: salaController,
          builder: (context, child) {
            return Column(
              children: <Widget>[
                _buildStatusCard(context),
                Expanded(
                  child: CaptureView(
                    salaController: salaController,
                    onCompleted: () async {
                      await salaController.salirSala();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.cloud_done_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              salaController.mensajeEstado,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (salaController.cantidadDocumentos > 0)
            Badge(label: Text('${salaController.cantidadDocumentos}')),
        ],
      ),
    );
  }
}
