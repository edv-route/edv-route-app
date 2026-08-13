import 'package:flutter/material.dart';

import '../../domain/entities/picked_image.dart';
import '../../domain/entities/registration_drafts.dart';
import '../../domain/entities/requirement.dart';
import 'draft_sheet_scaffold.dart';
import 'media_picker.dart';
import 'registration_fields.dart';

/// Add/edit-document modal for the wizard (driver OR vehicle documents). Mirrors
/// the admin's `document-draft-modal`: pick a requirement + capture its file.
/// Unlike the admin, the photo is required here (the app exists to collect it).
/// On confirm it pops a [DocDraft]; the caller accumulates it in a list.
class DocumentDraftSheet extends StatefulWidget {
  /// "del chofer" / "del vehículo" — used in the subtitle only.
  final String ownerLabel;

  /// Requirements the user may pick (available ones + the edited one).
  final List<Requirement> available;
  final DocDraft? initial;

  const DocumentDraftSheet({
    super.key,
    required this.ownerLabel,
    required this.available,
    this.initial,
  });

  @override
  State<DocumentDraftSheet> createState() => _DocumentDraftSheetState();
}

class _DocumentDraftSheetState extends State<DocumentDraftSheet> {
  Requirement? _requirement;
  PickedImage? _image;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      for (final r in widget.available) {
        if (r.id == initial.requirementId) {
          _requirement = r;
          break;
        }
      }
      _image = initial.image;
    }
  }

  bool get _canConfirm => _requirement != null && _image != null;

  Future<void> _pickRequirement() async {
    final chosen = await pickFromSheet<Requirement>(
      context,
      title: 'Requerimiento',
      items: widget.available,
      // Required ones flagged with * (mirrors the admin); optional ones plain.
      labelOf: (r) => r.isRequired ? '${r.name} *' : r.name,
    );
    if (chosen != null) setState(() => _requirement = chosen);
  }

  Future<void> _capture() async {
    final img = await pickDocument(context);
    if (img != null) setState(() => _image = img);
  }

  void _confirm() {
    final req = _requirement;
    if (req == null) {
      setState(() => _error = 'Elige el requerimiento.');
      return;
    }
    if (_image == null) {
      setState(() => _error = 'Adjunta la foto o el archivo del documento.');
      return;
    }
    Navigator.of(context).pop(
      DocDraft(requirementId: req.id, requirementName: req.name, image: _image!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return DraftSheetScaffold(
      title: editing ? 'Editar documento' : 'Agregar documento',
      subtitle: 'Documento ${widget.ownerLabel} + su foto',
      confirmLabel: editing ? 'Guardar' : 'Agregar documento',
      canConfirm: _canConfirm,
      onConfirm: _confirm,
      errorText: _error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickerField(
            label: 'Requerimiento',
            value: _requirement?.name,
            hint: 'Elige un requerimiento',
            onTap: _pickRequirement,
          ),
          const SizedBox(height: 16),
          CaptureTile(
            title: _requirement?.name ?? 'Foto del documento',
            description: 'Foto o PDF (máx. 10 MB)',
            image: _image,
            onPick: _capture,
          ),
        ],
      ),
    );
  }
}
