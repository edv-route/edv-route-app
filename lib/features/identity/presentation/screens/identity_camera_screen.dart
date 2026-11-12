import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../domain/entities/identity.dart';
import '../../../../domain/entities/picked_image.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/camera_overlays.dart';
import 'photo_review_screen.dart';

/// What changes between the selfie camera and the cédula camera. One screen,
/// one capture flow; only the lens, the guide and the words differ.
class _CameraSpec {
  final CameraLensDirection lens;
  final ResolutionPreset resolution;
  final String title;
  final String topHint;
  final String guideHint;
  final List<(IconData, String)> tips;
  final String caption;
  final CustomPainter painter;
  final Rect Function(Size) guideRect;

  /// 1 = front of the cédula, 2 = back; null for the selfie.
  final int? side;

  const _CameraSpec({
    required this.lens,
    required this.resolution,
    required this.title,
    required this.topHint,
    required this.guideHint,
    required this.tips,
    required this.caption,
    required this.painter,
    required this.guideRect,
    this.side,
  });

  static const _idTips = [
    (Icons.flare_rounded, 'Sin reflejos'),
    (Icons.visibility_outlined, 'Datos legibles'),
    (Icons.crop_free_rounded, 'Sin cortar bordes'),
  ];

  static _CameraSpec forKind(IdentityKind kind) => switch (kind) {
        // FRONT camera only, by decision (2026-11-12): the face must be taken
        // here and now, not picked from somewhere. 720p is plenty for a face.
        IdentityKind.selfie => const _CameraSpec(
            lens: CameraLensDirection.front,
            resolution: ResolutionPreset.high,
            title: 'Foto tipo carnet',
            topHint: 'Mira de frente a la cámara',
            guideHint: 'Centra tu cara dentro del óvalo',
            tips: [
              (Icons.light_mode_outlined, 'Buena luz'),
              (Icons.remove_red_eye_outlined, 'Sin lentes'),
              (Icons.do_not_disturb_on_outlined, 'Sin gorra'),
              (Icons.crop_portrait_rounded, 'Fondo liso'),
            ],
            caption: 'Solo con la cámara frontal · sin galería',
            painter: OvalGuidePainter(),
            guideRect: OvalGuidePainter.ovalFor,
          ),
        // The back camera, at 1080p: the office must READ the cédula.
        IdentityKind.idFront => const _CameraSpec(
            lens: CameraLensDirection.back,
            resolution: ResolutionPreset.veryHigh,
            title: 'Tu cédula',
            topHint: 'Apoya la cédula sobre una mesa',
            guideHint: 'Coloca el frente dentro del marco',
            tips: _idTips,
            caption: 'Solo cámara · después te pedimos el reverso',
            painter: CardGuidePainter(),
            guideRect: CardGuidePainter.frameFor,
            side: 1,
          ),
        IdentityKind.idBack => const _CameraSpec(
            lens: CameraLensDirection.back,
            resolution: ResolutionPreset.veryHigh,
            title: 'Tu cédula',
            topHint: 'Dale la vuelta a tu cédula',
            guideHint: 'Coloca el reverso dentro del marco',
            tips: _idTips,
            caption: 'Solo cámara · sin galería',
            painter: CardGuidePainter(),
            guideRect: CardGuidePainter.frameFor,
            side: 2,
          ),
      };
}

/// Takes one identity photo with the app's own camera — never the gallery —
/// and returns it as a [PickedImage] once the person accepted it in the review
/// step. Pops null if he backs out.
class IdentityCameraScreen extends StatefulWidget {
  const IdentityCameraScreen({super.key, required this.kind});

  final IdentityKind kind;

  @override
  State<IdentityCameraScreen> createState() => _IdentityCameraScreenState();
}

class _IdentityCameraScreenState extends State<IdentityCameraScreen> with WidgetsBindingObserver {
  late final _CameraSpec _spec = _CameraSpec.forKind(widget.kind);
  CameraController? _controller;
  String? _error;
  bool _permissionProblem = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// The camera must be released when the app leaves the foreground and
  /// reopened on return — Android hands it to whoever asks next.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      if (controller == null || !controller.value.isInitialized) return;
      _controller = null;
      controller.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _init();
    }
  }

  Future<void> _init() async {
    setState(() {
      _error = null;
      _permissionProblem = false;
    });
    try {
      final cameras = await availableCameras();
      CameraDescription? chosen;
      for (final c in cameras) {
        if (c.lensDirection == _spec.lens) {
          chosen = c;
          break;
        }
      }
      if (chosen == null) {
        setState(() => _error = _spec.lens == CameraLensDirection.front
            ? 'Tu teléfono no tiene cámara frontal: no es posible tomar la foto tipo carnet.'
            : 'No encontramos la cámara trasera de tu teléfono.');
        return;
      }
      final controller = CameraController(
        chosen,
        _spec.resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('AccessDenied') || e.code.contains('Restricted');
      setState(() {
        _permissionProblem = denied;
        _error = denied
            ? 'Necesitamos permiso para usar la cámara. Actívalo en los ajustes de tu teléfono.'
            : 'No se pudo abrir la cámara (${e.description ?? e.code}).';
      });
    }
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final use = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => PhotoReviewScreen(bytes: bytes, kind: widget.kind)),
      );
      if (!mounted) return;
      if (use == true) {
        Navigator.of(context).pop(PickedImage(bytes: bytes, filename: '${widget.kind.apiValue}.jpg'));
      }
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo tomar la foto (${e.description ?? e.code}).')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final guide = _spec.guideRect(size);
          return Stack(
            children: [
              Positioned.fill(child: _preview()),
              Positioned.fill(child: CustomPaint(painter: _spec.painter)),
              SafeArea(child: _topBar()),
              if (_error != null)
                Positioned.fill(child: _errorPanel())
              else ...[
                Positioned(left: 0, right: 0, top: guide.bottom + 22, child: _hints()),
                Positioned(left: 0, right: 0, bottom: 36, child: SafeArea(top: false, child: _shutter())),
              ],
            ],
          );
        },
      ),
    );
  }

  /// The live image, cropped to fill the screen (the sensor is landscape).
  Widget _preview() {
    final controller = _controller;
    final previewSize = controller?.value.previewSize;
    if (controller == null || !controller.value.isInitialized || previewSize == null) {
      return const ColoredBox(color: Color(0xFF2A2626));
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.close_rounded,
                label: 'Cerrar cámara',
                onTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  _spec.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 14),
          if (_spec.side != null) _SideIndicator(active: _spec.side!),
          const SizedBox(height: 12),
          Text(
            _spec.topHint,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _hints() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _spec.guideHint,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (icon, label) in _spec.tips)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 22),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _shutter() {
    final ready = _controller?.value.isInitialized ?? false;
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Tomar foto',
          child: GestureDetector(
            onTap: ready && !_busy ? _shoot : null,
            child: Container(
              width: 78,
              height: 78,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ready && !_busy ? Colors.white : Colors.white38,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _spec.caption,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _errorPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 44),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 22),
            if (_permissionProblem)
              FilledButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Abrir ajustes'),
              ),
            TextButton(
              onPressed: _init,
              child: const Text('Intentar de nuevo', style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1 · Frente / 2 · Reverso": where the person is in the cédula pair.
class _SideIndicator extends StatelessWidget {
  const _SideIndicator({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    Widget pill(int n, String label) {
      final on = n == active;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$n · $label',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: on ? AppColors.ink : Colors.white.withValues(alpha: 0.75),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [pill(1, 'Frente'), const SizedBox(width: 4), pill(2, 'Reverso')],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 20)),
        ),
      ),
    );
  }
}
