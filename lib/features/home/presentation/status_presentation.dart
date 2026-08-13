import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../auth/domain/entities/driver.dart';

/// UI mapping for a driver status: a Spanish label and a brand-consistent color
/// for the status chip. Presentation-only (colors never live in the domain).
({String label, Color color}) statusChip(DriverStatus status) => switch (status) {
      DriverStatus.approved => (label: 'Aprobado', color: Color(0xFF16A34A)),
      DriverStatus.pending => (label: 'En revisión', color: AppColors.gold600),
      DriverStatus.suspended => (label: 'Suspendido', color: AppColors.primary),
      DriverStatus.rejected => (label: 'Rechazado', color: AppColors.primary),
      DriverStatus.unknown => (label: 'Activo', color: AppColors.muted),
    };
