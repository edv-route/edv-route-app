import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/checklist.dart';
import '../controllers/checklist_controller.dart';
import '../../../../shared/widgets/checklist_widgets.dart';
import '../../../../shared/widgets/media_picker.dart';

/// Detail of a single document. Identified by [requirementId] (+ [vehicleId] for a
/// vehicle's document), it re-derives the document from the shared controller's
/// checklist on every rebuild — never holding the immutable instance — so after a
/// re-upload (which reloads the checklist) the screen reflects the new state.
///
/// Business rules surfaced here:
/// - can upload/replace while NOT approved (missing, without file, under review or
///   rejected) — the applicant can fix a mistake until the admin approves.
/// - approved → read-only (the backend invalidates any re-upload; changes are the
///   office's job), so no action is offered — but the file stays visible.
/// - rejected → shows the reason and lets the applicant re-upload to replace it.
/// - the uploaded file is previewed inline: images with [Image.network], PDFs with
///   an "open" button (the system viewer), via a short-lived signed URL.
class DocumentDetailScreen extends StatefulWidget {
  final ChecklistController controller;
  final int requirementId;
  final String? vehicleId;

  const DocumentDetailScreen({
    super.key,
    required this.controller,
    required this.requirementId,
    this.vehicleId,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  ChecklistController get _controller => widget.controller;

  // Preview state for the uploaded file. The signed URL is short-lived (~60s), so
  // it's fetched on demand and reloaded after a replace or when it expires.
  String? _fileUrl;
  bool _fileLoading = false;
  String? _fileError;
  String? _loadedDocId;

  /// Re-derives the document from the current checklist by its stable key.
  ChecklistDocument? _findDoc(Checklist c) {
    final list = widget.vehicleId == null ? c.driverDocuments : _vehicleDocs(c);
    for (final d in list) {
      if (d.requirementId == widget.requirementId) return d;
    }
    return null;
  }

  List<ChecklistDocument> _vehicleDocs(Checklist c) {
    for (final v in c.vehicles) {
      if (v.id == widget.vehicleId) return v.documents;
    }
    return const [];
  }

  ChecklistDocument? _currentDoc() {
    final c = _controller.checklist;
    return c == null ? null : _findDoc(c);
  }

  /// Schedules a one-shot fetch of the file's signed URL when needed (has a file,
  /// not already loaded for this document, not loading, no pending error).
  void _ensureFileLoaded(ChecklistDocument doc) {
    final id = doc.documentId;
    if (id == null || !doc.hasFile) return;
    if (_loadedDocId == id || _fileLoading || _fileError != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFileFor(id);
    });
  }

  Future<void> _loadFileFor(String documentId) async {
    setState(() {
      _fileLoading = true;
      _fileError = null;
    });
    try {
      final url = await _controller.documentFileUrl(documentId);
      if (!mounted) return;
      // Warm the image cache within this SAME loading so the inline preview
      // appears ready — one spinner (URL fetch + image download), not two.
      if (!_isPdf(url)) {
        await precacheImage(NetworkImage(url), context);
        if (!mounted) return;
      }
      setState(() {
        _fileUrl = url;
        _loadedDocId = documentId;
        _fileLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fileError = e.message;
        _fileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fileError = 'No se pudo cargar el documento.';
        _fileLoading = false;
      });
    }
  }

  Future<void> _upload(ChecklistDocument doc) async {
    final image = await pickDocument(context);
    if (image == null || !mounted) return;
    await _controller.uploadDocument(doc: doc, vehicleId: widget.vehicleId, image: image);
    if (!mounted) return;
    if (_controller.actionError != null) {
      _showActionErrorIfAny();
      return;
    }
    // Success: the checklist reloaded. Force the preview to re-fetch the new file.
    setState(() {
      _loadedDocId = null;
      _fileUrl = null;
      _fileError = null;
    });
  }

  void _reloadFile() {
    final doc = _currentDoc();
    if (doc?.documentId == null) return;
    setState(() {
      _loadedDocId = null;
      _fileError = null;
    });
    _loadFileFor(doc!.documentId!);
  }

  Future<void> _openExternally(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No se pudo abrir el documento.')));
    }
  }

  void _showActionErrorIfAny() {
    if (_controller.actionError != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_controller.actionError!)));
      _controller.clearActionError();
    }
  }

  bool _isPdf(String url) => url.split('?').first.toLowerCase().endsWith('.pdf');

  String _actionLabel(ChecklistDocument doc) {
    if (doc.isRejected) return 'Volver a subir';
    if (doc.hasFile) return 'Reemplazar documento';
    return 'Subir documento';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final checklist = _controller.checklist;
          final doc = checklist == null ? null : _findDoc(checklist);
          if (doc != null) _ensureFileLoaded(doc);
          return Column(
            children: [
              AuthHeader(title: doc?.requirementName ?? 'Documento', showBack: true),
              Expanded(child: doc == null ? _unavailable() : _scrollContent(doc)),
              // The action button is pinned to the bottom (outside the scroll) so it
              // never jumps when the preview loads.
              if (doc != null && doc.canUpload) _actionFooter(doc),
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
            'Este documento ya no está disponible.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ),
      );

  /// Scrollable content: state, rejection reason and the inline preview. The
  /// action button lives in [_actionFooter], pinned below.
  Widget _scrollContent(ChecklistDocument doc) {
    final hasFile = doc.hasFile && doc.documentId != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        _StatusHeadline(doc: doc),
        if (doc.isRejected && doc.rejectionReason != null) ...[
          const SizedBox(height: 16),
          RejectionReasonBox(reason: doc.rejectionReason!),
        ],
        if (hasFile) ...[
          const SizedBox(height: 20),
          const Text(
            'Documento subido',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          _previewBody(),
        ],
      ],
    );
  }

  /// The upload/replace action, pinned to the bottom of the screen so it stays
  /// put while the preview loads above it.
  Widget _actionFooter(ChecklistDocument doc) {
    final uploading = _controller.isUploading(widget.requirementId, vehicleId: widget.vehicleId);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardGrey)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (uploading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: CircularProgressIndicator(),
                )
              else
                PrimaryButton(label: _actionLabel(doc), onPressed: () => _upload(doc)),
              const SizedBox(height: 8),
              Text(
                doc.hasFile
                    ? 'Puedes reemplazarlo mientras no esté aprobado. Foto o archivo (imagen o PDF), máx 10 MB.'
                    : 'Puedes subir una foto o un archivo (imagen o PDF), máx 10 MB.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewBody() {
    if (_fileLoading) {
      return const _PreviewLoading();
    }
    if (_fileError != null) {
      return _PreviewError(message: _fileError!, onRetry: _reloadFile);
    }
    final url = _fileUrl;
    if (url == null) {
      return const _PreviewLoading();
    }
    if (_isPdf(url)) {
      return _PdfCard(onOpen: () => _openExternally(url));
    }
    return _ImagePreview(url: url, onReload: _reloadFile);
  }
}

/// The big state summary at the top of the detail: an icon, the state in words
/// and a one-line explanation of what it means / what to do.
class _StatusHeadline extends StatelessWidget {
  final ChecklistDocument doc;

  const _StatusHeadline({required this.doc});

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, description) = _describe(doc);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                    DocBadge(doc: doc),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String) _describe(ChecklistDocument doc) {
    if (doc.isApproved) {
      return (
        Icons.check_circle,
        const Color(0xFF166534),
        'Aprobado',
        'Este documento fue aprobado. Ya no puedes modificarlo desde la app; si necesitas cambiarlo, contacta a la oficina.',
      );
    }
    if (doc.isRejected) {
      return (
        Icons.cancel,
        AppColors.primary700,
        'Rechazado',
        'Revisa el motivo, corrige lo indicado y vuelve a subir el documento.',
      );
    }
    if (doc.isMissing) {
      return (
        Icons.upload_file,
        AppColors.primary700,
        doc.isRequired ? 'Falta subirlo' : 'Opcional',
        doc.isRequired
            ? 'Aún no has subido este documento. Es obligatorio para tu ingreso.'
            : 'Este documento es opcional. Puedes subirlo si lo tienes.',
      );
    }
    if (doc.needsFile) {
      return (
        Icons.upload_file,
        AppColors.primary700,
        'Sin archivo',
        'Ya se registró, pero falta adjuntar el archivo.',
      );
    }
    return (
      Icons.hourglass_top,
      AppColors.gold700,
      'En revisión',
      'Lo estamos revisando. Puedes reemplazarlo mientras no lo aprueben.',
    );
  }
}

/// Inline image preview of the uploaded file. Rebuilds a reload affordance if the
/// signed URL has expired by the time it loads.
class _ImagePreview extends StatelessWidget {
  final String url;
  final VoidCallback onReload;

  const _ImagePreview({required this.url, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardGrey),
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: const BoxConstraints(maxHeight: 380),
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stack) => _PreviewError(
            message: 'La vista previa expiró.',
            onRetry: onReload,
          ),
        ),
      ),
    );
  }
}

/// Centered loading area for the preview, sized so the spinner sits in the middle
/// of where the file will appear (not pinned to the top).
class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 240,
        width: double.infinity,
        child: Center(child: CircularProgressIndicator()),
      );
}

/// PDF placeholder: the file is a PDF, opened with the system viewer (the app has
/// no embedded PDF renderer).
class _PdfCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _PdfCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Documento en PDF',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// A preview failure with a retry (load error or expired signed URL).
class _PreviewError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PreviewError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_not_supported_outlined, color: AppColors.muted, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Recargar')),
        ],
      ),
    );
  }
}
