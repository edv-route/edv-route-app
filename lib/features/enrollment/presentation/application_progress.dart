import '../../../domain/entities/checklist.dart';
import '../../../domain/entities/identity.dart';

/// Where a section of the solicitud stands, as the applicant reads it.
enum SectionTone {
  /// Approved by the office.
  done,

  /// Sent; the office has not answered yet.
  review,

  /// Something for HIM to do (missing or rejected).
  action,
}

enum HubSection { identity, documents, vehicle }

class SectionState {
  final HubSection section;
  final SectionTone tone;

  /// The chip ("Aprobada", "1 por corregir", "Pendiente"…).
  final String chip;
  const SectionState(this.section, this.tone, this.chip);
}

/// The one thing the hub asks him to do next.
class NextStep {
  final HubSection section;
  final String title;
  final String? detail;
  final String action;
  const NextStep({required this.section, required this.title, this.detail, required this.action});
}

/// "Completa tu solicitud" (redesign 2026-11-12, approved by Luis): three
/// sections — identity, documents, vehicle — each with a plain state, and ONE
/// highlighted next step. Pure functions: the screen only paints them.
class ApplicationProgress {
  const ApplicationProgress({required this.identity, required this.checklist});

  /// Null until loaded (or when it could not be): shown as pending, never
  /// as a false "falta".
  final IdentityView? identity;
  final Checklist checklist;

  SectionState get identitySection {
    final status = identity?.status;
    return switch (status) {
      IdentityStatus.approved => const SectionState(HubSection.identity, SectionTone.done, 'Aprobada'),
      IdentityStatus.rejected => const SectionState(HubSection.identity, SectionTone.action, 'Por corregir'),
      IdentityStatus.missing => const SectionState(HubSection.identity, SectionTone.action, 'Falta'),
      IdentityStatus.pending || null => const SectionState(HubSection.identity, SectionTone.review, 'En revisión'),
    };
  }

  SectionState get documentsSection {
    final c = checklist;
    final rejected = c.driverDocuments.where((d) => d.isRejected).length;
    if (rejected > 0) {
      return SectionState(HubSection.documents, SectionTone.action, '$rejected por corregir');
    }
    if (c.driverActionable > 0) {
      final n = c.driverActionable;
      return SectionState(HubSection.documents, SectionTone.action, n == 1 ? 'Falta 1' : 'Faltan $n');
    }
    if (c.driverTotal == 0 || c.driverApproved == c.driverTotal) {
      return const SectionState(HubSection.documents, SectionTone.done, 'Aprobados');
    }
    return const SectionState(HubSection.documents, SectionTone.review, 'En revisión');
  }

  SectionState get vehicleSection {
    final c = checklist;
    if (!c.hasVehicle) return const SectionState(HubSection.vehicle, SectionTone.action, 'Pendiente');
    if (c.vehiclesActionable > 0) return const SectionState(HubSection.vehicle, SectionTone.action, 'Por corregir');
    if (c.vehiclesApproved == c.vehicleCount) {
      return const SectionState(HubSection.vehicle, SectionTone.done, 'Aprobado');
    }
    return const SectionState(HubSection.vehicle, SectionTone.review, 'En revisión');
  }

  List<SectionState> get sections => [identitySection, documentsSection, vehicleSection];

  int get doneCount => sections.where((s) => s.tone == SectionTone.done).length;

  /// The first section that needs HIM, in the order the office reviews them.
  /// Null when nothing is in his hands (all sent or approved).
  NextStep? get nextStep {
    if (identitySection.tone == SectionTone.action) {
      return identity?.status == IdentityStatus.rejected
          ? const NextStep(
              section: HubSection.identity,
              title: 'Toma de nuevo tu foto',
              detail: 'La oficina rechazó una de tus fotos de identidad.',
              action: 'Ver el motivo',
            )
          : const NextStep(
              section: HubSection.identity,
              title: 'Envía tus fotos de identidad',
              detail: 'Tu foto tipo carnet y tu cédula por ambos lados.',
              action: 'Tomar fotos',
            );
    }
    if (documentsSection.tone == SectionTone.action) {
      final docs = checklist.driverDocuments;
      final rejected = docs.where((d) => d.isRejected).toList();
      if (rejected.isNotEmpty) {
        final doc = rejected.first;
        return NextStep(
          section: HubSection.documents,
          title: 'Corrige tu ${doc.requirementName.toLowerCase()}',
          detail: doc.rejectionReason,
          action: 'Corregir ahora',
        );
      }
      final missing = docs.where((d) => d.needsAction).toList();
      return NextStep(
        section: HubSection.documents,
        title: missing.isEmpty ? 'Sube tus documentos' : 'Sube tu ${missing.first.requirementName.toLowerCase()}',
        action: 'Subir ahora',
      );
    }
    if (vehicleSection.tone == SectionTone.action) {
      return checklist.hasVehicle
          ? const NextStep(
              section: HubSection.vehicle,
              title: 'Corrige tu vehículo',
              detail: 'La oficina pidió cambios en tu vehículo o en sus papeles.',
              action: 'Corregir ahora',
            )
          : const NextStep(
              section: HubSection.vehicle,
              title: 'Agrega tu vehículo',
              // Generic on purpose: the vehicle papers are a catalogue the
              // office edits, so naming them here would go stale.
              detail: 'Con sus papeles, para que la oficina lo revise.',
              action: 'Agregar vehículo',
            );
    }
    return null;
  }
}
