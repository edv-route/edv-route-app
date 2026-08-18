import 'package:flutter/material.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// Opens a keyboard-aware, rounded-top modal bottom sheet (the "modal that rises"
/// on mobile) hosting a [DraftSheetScaffold]. Returns whatever the sheet pops.
Future<T?> showDraftSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: builder,
  );
}

/// Shell for the wizard's draft modals (document / vehicle / payment): a title
/// bar with a close button, a scrollable body and a pinned footer (Cancelar +
/// confirm). Mirrors the shape of the admin's `*-draft-modal` dialogs.
class DraftSheetScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String confirmLabel;
  final bool canConfirm;
  final VoidCallback onConfirm;
  final String? errorText;

  const DraftSheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.confirmLabel,
    required this.canConfirm,
    required this.onConfirm,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.ink,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: child,
              ),
            ),
            if (errorText != null && errorText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  errorText!,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + media.padding.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary900,
                        side: const BorderSide(color: AppColors.fieldBorder),
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: confirmLabel,
                      onPressed: canConfirm ? onConfirm : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
