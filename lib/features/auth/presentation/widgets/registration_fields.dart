import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/payment_method_option.dart';
import '../../domain/entities/picked_image.dart';

/// Shared building blocks for the registration wizard and its modals: capture
/// tiles, branded picker fields, a date field, the photo grid, method rows and a
/// bottom-sheet list picker. Kept public so the screen and the draft sheets reuse
/// the exact same look instead of drifting.

/// Opens a titled, scrollable bottom sheet listing [items] (rendered with
/// [labelOf]) and returns the tapped item, or null if dismissed.
Future<T?> pickFromSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final it in items)
                    ListTile(title: Text(labelOf(it)), onTap: () => Navigator.pop(ctx, it)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A tile to capture (and preview) one document/receipt photo or PDF.
class CaptureTile extends StatelessWidget {
  final String title;
  final String? description;
  final PickedImage? image;
  final Future<void> Function() onPick;

  const CaptureTile({
    super.key,
    required this.title,
    this.description,
    required this.image,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final has = image != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: has ? AppColors.gold : AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: !has
                  ? Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.description_outlined, color: AppColors.muted),
                    )
                  : image!.isPdf
                      ? Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                        )
                      : Image.memory(Uint8List.fromList(image!.bytes), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(description!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onPick,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(has ? 'Cambiar' : 'Agregar'),
          ),
        ],
      ),
    );
  }
}

/// A read-only field that opens a picker on tap; shows the value or a hint plus a
/// chevron. Paints a red border + message when [errorText] is set.
class PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary900),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: hasError ? Border.all(color: AppColors.primary, width: 1.5) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    v ?? hint,
                    style: TextStyle(color: v == null ? AppColors.muted : AppColors.ink, fontSize: 15),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

/// A tappable field that opens a date picker and shows the chosen date. Paints a
/// red border + message when [errorText] is set (required-field feedback).
class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary900),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: hasError ? Border.all(color: AppColors.primary, width: 1.5) : null,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
                const SizedBox(width: 10),
                Text(
                  v == null
                      ? 'Seleccionar fecha'
                      : '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}',
                  style: TextStyle(color: v == null ? AppColors.muted : AppColors.ink, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

/// A wrap of photo thumbnails with remove buttons plus an "add" tile while under
/// the max. Used for a vehicle's photos.
class PhotoGrid extends StatelessWidget {
  final List<PickedImage> photos;
  final bool canAdd;
  final Future<void> Function() onAdd;
  final void Function(int) onRemove;

  const PhotoGrid({
    super.key,
    required this.photos,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < photos.length; i++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  Uint8List.fromList(photos[i].bytes),
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.cardGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppColors.muted),
                  SizedBox(height: 4),
                  Text('Subir', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A selectable payment-method row (radio-style).
class MethodTile extends StatelessWidget {
  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback onTap;

  const MethodTile({super.key, required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.name,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only card showing where to pay (the method's destination details).
class DestinationCard extends StatelessWidget {
  final List<MapEntry<String, String>> rows;

  const DestinationCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paga a esta cuenta',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary900, fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(r.key, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      r.value,
                      style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Slim progress bar under the header showing how far along the wizard is.
class WizardProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const WizardProgressBar({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: (step + 1) / total,
          minHeight: 6,
          backgroundColor: AppColors.fieldBorder,
          valueColor: const AlwaysStoppedAnimation(AppColors.gold),
        ),
      ),
    );
  }
}

/// Forces its input to uppercase (used for the vehicle plate).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Live input filters mirroring the admin's `appLetters` directive: keeps letters
/// (any language), space, apostrophe and hyphen, and caps the length. Same double
/// layer the panel uses (strip-as-you-type + validator). For names and color.
List<TextInputFormatter> letterInputFormatters(int maxLength) => [
      FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '-]", unicode: true)),
      LengthLimitingTextInputFormatter(maxLength),
    ];

/// Live input filters mirroring the admin's `appAlnumDash` directive: letters,
/// digits, space and hyphen; caps the length (vehicle brand / model).
List<TextInputFormatter> alnumDashInputFormatters(int maxLength) => [
      FilteringTextInputFormatter.allow(RegExp(r'[\p{L}\p{N} -]', unicode: true)),
      LengthLimitingTextInputFormatter(maxLength),
    ];

/// A dashed "Agregar…" tile that opens a draft modal (documents, vehicles, pago).
class AddTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const AddTile({super.key, required this.label, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.cardGrey,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A summary row in a step list (document / vehicle / payment) with Editar/Quitar.
class DraftRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback? onEdit;
  final VoidCallback onRemove;
  final Widget? trailingBelow;

  const DraftRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.onEdit,
    required this.onRemove,
    this.trailingBelow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Editar'),
                ),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Quitar'),
              ),
            ],
          ),
          if (trailingBelow != null) trailingBelow!,
        ],
      ),
    );
  }
}
