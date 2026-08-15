import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/features/auth/domain/entities/checklist.dart';

/// Builds a document in a given review state for the assertions below.
ChecklistDocument _doc({
  int requirementId = 1,
  bool isRequired = true,
  String? documentId,
  bool hasFile = false,
  String? approvalStatus,
  String? rejectionReason,
}) =>
    ChecklistDocument(
      requirementId: requirementId,
      requirementName: 'Documento',
      isRequired: isRequired,
      documentId: documentId,
      hasFile: hasFile,
      approvalStatus: approvalStatus,
      rejectionReason: rejectionReason,
    );

void main() {
  group('ChecklistDocument.review', () {
    test('missing when no slot exists', () {
      expect(_doc(documentId: null).review, DocReview.missing);
    });

    test('pending with a slot but no verdict', () {
      final d = _doc(documentId: 'x', hasFile: true, approvalStatus: 'pending');
      expect(d.review, DocReview.pending);
    });

    test('approved / rejected follow approvalStatus', () {
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'approved').review,
          DocReview.approved);
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'rejected').review,
          DocReview.rejected);
    });

    test('needsFile when the slot exists without a file', () {
      expect(_doc(documentId: 'x', hasFile: false).needsFile, isTrue);
      expect(_doc(documentId: 'x', hasFile: true).needsFile, isFalse);
      expect(_doc(documentId: null).needsFile, isFalse);
    });
  });

  group('ChecklistDocument.canUpload — replace allowed until approved', () {
    test('allowed while missing / without file / pending / rejected', () {
      expect(_doc(documentId: null).canUpload, isTrue); // missing
      expect(_doc(documentId: 'x', hasFile: false).canUpload, isTrue); // needsFile
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'pending').canUpload,
          isTrue); // under review
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'rejected').canUpload,
          isTrue); // rejected
    });

    test('blocked once approved', () {
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'approved').canUpload,
          isFalse);
    });
  });

  group('ChecklistDocument.needsAction', () {
    test('required missing / without file, or rejected, need action', () {
      expect(_doc(documentId: null).needsAction, isTrue); // required + missing
      expect(_doc(documentId: 'x', hasFile: false).needsAction, isTrue); // required + needsFile
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'rejected').needsAction,
          isTrue);
    });

    test('optional missing does not need action; approved/pending do not', () {
      expect(_doc(isRequired: false, documentId: null).needsAction, isFalse);
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'approved').needsAction,
          isFalse);
      expect(_doc(documentId: 'x', hasFile: true, approvalStatus: 'pending').needsAction,
          isFalse);
    });
  });

  group('Checklist section summaries', () {
    final checklist = Checklist(
      driverDocuments: [
        _doc(requirementId: 1, documentId: 'a', hasFile: true, approvalStatus: 'approved'),
        _doc(requirementId: 2, documentId: 'b', hasFile: true, approvalStatus: 'rejected'),
        _doc(requirementId: 3, documentId: null), // required missing
      ],
      vehicles: const [],
    );

    test('driver counts feed the hub card', () {
      expect(checklist.driverTotal, 3);
      expect(checklist.driverApproved, 1);
      expect(checklist.driverRejected, 1);
      // rejected + required-missing both need action.
      expect(checklist.driverActionable, 2);
    });

    test('no vehicle is itself a pending action, so not ready for review', () {
      expect(checklist.hasVehicle, isFalse);
      // 2 doc actions + 1 for the missing vehicle.
      expect(checklist.pendingActions, 3);
      expect(checklist.isReadyForReview, isFalse);
    });
  });

  group('Checklist vehicles summary', () {
    test('a rejected vehicle or a vehicle with a rejected doc is actionable', () {
      final approvedClean = ChecklistVehicle(
        id: 'v1',
        brand: 'Toyota',
        model: 'Corolla',
        plate: 'ABC123',
        approvalStatus: 'approved',
        rejectionReason: null,
        documents: [
          _doc(documentId: 'd', hasFile: true, approvalStatus: 'approved'),
        ],
      );
      final rejectedVehicle = ChecklistVehicle(
        id: 'v2',
        brand: null,
        model: null,
        plate: 'XYZ',
        approvalStatus: 'rejected',
        rejectionReason: 'Foto ilegible',
        documents: const [],
      );

      final checklist = Checklist(
        driverDocuments: const [],
        vehicles: [approvedClean, rejectedVehicle],
      );

      expect(checklist.vehicleCount, 2);
      expect(checklist.vehiclesApproved, 1);
      expect(checklist.vehiclesActionable, 1); // only the rejected one
      expect(approvedClean.needsAction, isFalse);
      expect(rejectedVehicle.needsAction, isTrue);
    });
  });
}
