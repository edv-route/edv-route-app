import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/checklist.dart';
import '../../../../domain/entities/vehicle_full.dart';
import '../controllers/checklist_controller.dart';
import '../../../../shared/widgets/checklist_widgets.dart';
import './document_detail_screen.dart';

/// Detail of a single vehicle: a photo carousel + full data (brand, model, year,
/// color, plate, type) from GET /me/vehicles, plus its documents as navigable rows
/// (from the shared checklist). The documents re-derive from the controller so they
/// stay in sync; the full data + photos are loaded once here.
class VehicleDetailScreen extends StatefulWidget {
  final ChecklistController controller;
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.controller, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  VehicleFull? _full;
  bool _fullLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  Future<void> _loadFull() async {
    try {
      final list = await Dependencies.instance.registrationRepository.loadVehicles();
      if (!mounted) return;
      VehicleFull? found;
      for (final v in list) {
        if (v.id == widget.vehicleId) {
          found = v;
          break;
        }
      }
      setState(() {
        _full = found;
        _fullLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _fullLoading = false);
    }
  }

  ChecklistVehicle? _findVehicle(Checklist c) {
    for (final v in c.vehicles) {
      if (v.id == widget.vehicleId) return v;
    }
    return null;
  }

  void _openDocument(ChecklistDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          controller: widget.controller,
          requirementId: doc.requirementId,
          vehicleId: widget.vehicleId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final checklist = widget.controller.checklist;
          final vehicle = checklist == null ? null : _findVehicle(checklist);
          final title = vehicle?.label ?? _full?.label ?? 'Vehículo';
          return Column(
            children: [
              AuthHeader(title: title, showBack: true),
              Expanded(
                child: (vehicle == null && _full == null && !_fullLoading)
                    ? _unavailable()
                    : _detail(vehicle),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _unavailable() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este vehículo ya no está disponible.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ),
      );

  Widget _detail(ChecklistVehicle? vehicle) {
    final status = _full?.approvalStatus ?? vehicle?.approvalStatus ?? 'pending';
    final reason = _full?.rejectionReason ?? vehicle?.rejectionReason;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        _carousel(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Estado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
            VehicleBadge(status: status),
          ],
        ),
        if (status == 'rejected' && reason != null) ...[
          const SizedBox(height: 12),
          RejectionReasonBox(reason: reason),
        ],
        const SizedBox(height: 16),
        _dataCard(vehicle),
        const SizedBox(height: 20),
        const Text(
          'Documentos del vehículo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        if (vehicle == null || vehicle.documents.isEmpty)
          const ChecklistEmptyLine('No hay documentos requeridos para este vehículo.')
        else
          for (final d in vehicle.documents)
            ChecklistTile(
              icon: Icons.description_outlined,
              title: d.requirementName + (d.isRequired ? '' : ' (opcional)'),
              trailing: DocBadge(doc: d),
              onTap: () => _openDocument(d),
            ),
      ],
    );
  }

  Widget _carousel() {
    if (_fullLoading) {
      return const _CarouselFrame(child: Center(child: CircularProgressIndicator()));
    }
    final images = _full?.images ?? const [];
    if (images.isEmpty) {
      return const _CarouselFrame(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined, color: AppColors.muted, size: 32),
              SizedBox(height: 6),
              Text('Sin fotos', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
        ),
      );
    }
    return _PhotoCarousel(images: images);
  }

  Widget _dataCard(ChecklistVehicle? vehicle) {
    final full = _full;
    final rows = <(String, String)>[
      ('Marca / modelo', full?.label ?? vehicle?.label ?? '—'),
      ('Año', full?.year?.toString() ?? '—'),
      ('Color', (full?.color?.isNotEmpty ?? false) ? full!.color! : '—'),
      ('Placa', full?.plate ?? vehicle?.plate ?? '—'),
      ('Tipo', (full?.vehicleType?.isNotEmpty ?? false) ? full!.vehicleType! : '—'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardGrey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(rows[i].$1, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  ),
                  Text(rows[i].$2, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fixed-height rounded frame for the carousel / its placeholders.
class _CarouselFrame extends StatelessWidget {
  final Widget child;

  const _CarouselFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Horizontal photo carousel with page dots.
class _PhotoCarousel extends StatefulWidget {
  final List<VehicleImage> images;

  const _PhotoCarousel({required this.images});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CarouselFrame(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Image.network(
              widget.images[i].url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stack) => const Center(
                child: Icon(Icons.broken_image_outlined, color: AppColors.muted, size: 32),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.images.length; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? AppColors.primary : AppColors.cardGrey,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
