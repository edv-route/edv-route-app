import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/entities/identity.dart';
import '../../../../theme/app_colors.dart';

/// "¿Se ve bien?" — the last look before a photo is kept. Pops `true` to use
/// it, `false` (or back) to take it again. A blurry cédula caught here saves a
/// rejection and a day of waiting.
class PhotoReviewScreen extends StatelessWidget {
  const PhotoReviewScreen({super.key, required this.bytes, required this.kind});

  final Uint8List bytes;
  final IdentityKind kind;

  List<String> get _checks => kind == IdentityKind.selfie
      ? const ['Se ve tu cara completa y de frente', 'Sin lentes ni gorra', 'Hay buena luz, sin sombras fuertes']
      : const ['Se leen todos tus datos', 'No hay reflejos ni sombras fuertes', 'La cédula se ve completa'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver a la cámara',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Se ve bien?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(kind.label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: const Color(0xFFE6EBF0),
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Antes de usarla, revisa que:',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    for (final check in _checks) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.check_rounded, size: 20, color: Color(0xFF166534)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(check, style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151))),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Repetir'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Usar esta foto'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
