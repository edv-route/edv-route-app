import 'package:flutter/material.dart';

import '../../../../shared/widgets/auth_header.dart';
import '../../domain/entities/checklist.dart';
import '../controllers/checklist_controller.dart';
import '../widgets/checklist_widgets.dart';
import 'document_detail_screen.dart';

/// The applicant's driver documents, one navigable row each. Tapping a row opens
/// its detail (where it can be uploaded/replaced). Non-blocking: any document can
/// be opened in any order. Shares the hub's [ChecklistController].
class DocumentsListScreen extends StatelessWidget {
  final ChecklistController controller;

  const DocumentsListScreen({super.key, required this.controller});

  void _openDetail(BuildContext context, ChecklistDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          controller: controller,
          requirementId: doc.requirementId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Tus documentos',
            subtitle: 'Toca un documento para ver su estado y subirlo',
            showBack: true,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final checklist = controller.checklist;
                if (checklist == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      if (checklist.driverDocuments.isEmpty)
                        const ChecklistEmptyLine('No hay documentos requeridos.')
                      else
                        for (final d in checklist.driverDocuments)
                          ChecklistTile(
                            icon: Icons.description_outlined,
                            title: d.requirementName + (d.isRequired ? '' : ' (opcional)'),
                            trailing: DocBadge(doc: d),
                            onTap: () => _openDetail(context, d),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
