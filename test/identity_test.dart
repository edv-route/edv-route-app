import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/core/network/api_exception.dart';
import 'package:edv_route_mobile/domain/entities/checklist.dart';
import 'package:edv_route_mobile/domain/entities/identity.dart';
import 'package:edv_route_mobile/domain/entities/picked_image.dart';
import 'package:edv_route_mobile/domain/repositories/identity_repository.dart';
import 'package:edv_route_mobile/features/enrollment/presentation/application_progress.dart';
import 'package:edv_route_mobile/features/identity/presentation/controllers/identity_flow_controller.dart';

/// Builds what `/me/identity` would answer.
IdentityView viewOf(Map<IdentityKind, IdentityPhotoStatus> photos, {bool required = false}) {
  return IdentityView.fromJson({
    'status': _summary(photos),
    'required': required,
    'photos': [
      for (final e in photos.entries)
        {
          'kind': e.key.apiValue,
          'status': e.value.name,
          'rejectionReason': e.value == IdentityPhotoStatus.rejected ? 'Está borrosa' : null,
          'url': 'https://signed/${e.key.apiValue}',
        },
    ],
  });
}

String _summary(Map<IdentityKind, IdentityPhotoStatus> photos) {
  if (photos.length < 3) return 'missing';
  if (photos.values.contains(IdentityPhotoStatus.rejected)) return 'rejected';
  if (photos.values.contains(IdentityPhotoStatus.pending)) return 'pending';
  return 'approved';
}

/// Scriptable stand-in for the server.
class _FakeRepo implements IdentityRepository {
  _FakeRepo([Map<IdentityKind, IdentityPhotoStatus>? initial]) : photos = {...?initial};

  final Map<IdentityKind, IdentityPhotoStatus> photos;
  final List<IdentityKind> uploads = [];
  final Set<IdentityKind> failNext = {};

  /// The upload reaches the server but its answer is lost on the way back.
  final Set<IdentityKind> loseAnswer = {};

  @override
  Future<IdentityView> load() async => viewOf(photos);

  @override
  Future<IdentityView> upload(IdentityKind kind, PickedImage image) async {
    if (failNext.remove(kind)) throw const ApiException('Sin conexión');
    uploads.add(kind);
    photos[kind] = IdentityPhotoStatus.pending;
    if (loseAnswer.remove(kind)) throw const ApiException('El servidor tardó demasiado en responder.');
    return viewOf(photos);
  }
}

const _jpg = PickedImage(bytes: [0xff, 0xd8, 0xff], filename: 'x.jpg');

void _captureAll(IdentityFlowController c) {
  for (final k in IdentityKind.values) {
    c.capture(k, _jpg);
  }
}

ChecklistDocument _doc(String name, {String? status, bool exists = true}) => ChecklistDocument(
      requirementId: name.hashCode,
      requirementName: name,
      isRequired: true,
      documentId: exists ? 'doc-$name' : null,
      hasFile: exists,
      approvalStatus: status,
      rejectionReason: status == 'rejected' ? 'No se lee la fecha' : null,
    );

void main() {
  group('IdentityView', () {
    test('parses the server answer and knows which slots take a photo', () {
      final view = viewOf({
        IdentityKind.selfie: IdentityPhotoStatus.approved,
        IdentityKind.idFront: IdentityPhotoStatus.rejected,
      });
      expect(view.status, IdentityStatus.missing);
      expect(view.photos[IdentityKind.idFront]!.rejectionReason, 'Está borrosa');
      expect(view.canTake(IdentityKind.selfie), isFalse, reason: 'approved is final');
      expect(view.canTake(IdentityKind.idFront), isTrue, reason: 'rejected is retaken');
      expect(view.canTake(IdentityKind.idBack), isTrue, reason: 'empty slot');
    });

    test('only missing and rejected stop the person at the gate', () {
      expect(IdentityStatus.missing.needsAction, isTrue);
      expect(IdentityStatus.rejected.needsAction, isTrue);
      expect(IdentityStatus.pending.needsAction, isFalse);
      expect(IdentityStatus.approved.needsAction, isFalse);
      expect(IdentityStatus.fromApi('algo-nuevo'), IdentityStatus.missing);
    });
  });

  group('IdentityFlowController — registration', () {
    test('cannot send until the three photos are taken', () {
      final c = IdentityFlowController(repository: _FakeRepo(), createAccount: () async {});
      c.capture(IdentityKind.selfie, _jpg);
      expect(c.stillNeeded, [IdentityKind.idFront, IdentityKind.idBack]);
      expect(c.canSubmit, isFalse);
      c.capture(IdentityKind.idFront, _jpg);
      c.capture(IdentityKind.idBack, _jpg);
      expect(c.canSubmit, isTrue);
      c.dispose();
    });

    test('creates the account ONCE even when a photo fails and is retried', () async {
      final repo = _FakeRepo()..failNext.add(IdentityKind.idBack);
      var created = 0;
      final c = IdentityFlowController(repository: repo, createAccount: () async => created++);
      _captureAll(c);

      expect(await c.submit(), isFalse);
      expect(created, 1);
      expect(c.accountCreated, isTrue, reason: 'the form must not be sent again');
      expect(c.error, contains('Tu cuenta ya se creó'));
      expect(repo.uploads, [IdentityKind.selfie, IdentityKind.idFront]);

      expect(await c.submit(), isTrue);
      expect(created, 1, reason: 'a retry never registers twice');
      expect(repo.uploads, [IdentityKind.selfie, IdentityKind.idFront, IdentityKind.idBack]);
      c.dispose();
    });

    test('a failed registration sends no photo and lets him go back', () async {
      final repo = _FakeRepo();
      final c = IdentityFlowController(
        repository: repo,
        createAccount: () async => throw const ApiException('Esta cédula ya está registrada'),
      );
      _captureAll(c);
      expect(await c.submit(), isFalse);
      expect(c.accountCreated, isFalse);
      expect(c.error, 'Esta cédula ya está registrada');
      expect(repo.uploads, isEmpty);
      c.dispose();
    });
  });

  group('IdentityFlowController — existing account', () {
    test('only empty and rejected slots take a new photo', () {
      final c = IdentityFlowController(
        repository: _FakeRepo(),
        initial: viewOf({
          IdentityKind.selfie: IdentityPhotoStatus.pending,
          IdentityKind.idFront: IdentityPhotoStatus.rejected,
          IdentityKind.idBack: IdentityPhotoStatus.approved,
        }),
      );
      c.capture(IdentityKind.selfie, _jpg); // in review: ignored
      c.capture(IdentityKind.idBack, _jpg); // approved: ignored
      expect(c.slotOf(IdentityKind.selfie), SlotState.inReview);
      expect(c.slotOf(IdentityKind.idBack), SlotState.approved);
      expect(c.slotOf(IdentityKind.idFront), SlotState.rejected);
      expect(c.canSubmit, isFalse);

      c.capture(IdentityKind.idFront, _jpg);
      expect(c.slotOf(IdentityKind.idFront), SlotState.captured);
      expect(c.canSubmit, isTrue);
      c.dispose();
    });

    test('an upload whose answer was lost is not sent again', () async {
      final repo = _FakeRepo({
        IdentityKind.selfie: IdentityPhotoStatus.pending,
        IdentityKind.idFront: IdentityPhotoStatus.pending,
      })..loseAnswer.add(IdentityKind.idBack);
      final c = IdentityFlowController(repository: repo, initial: await repo.load());
      c.capture(IdentityKind.idBack, _jpg);

      // The server got it; the app only saw a timeout. Reconciling with the
      // server turns that into success instead of a "ya está en revisión" loop.
      expect(await c.submit(), isTrue);
      expect(repo.uploads, [IdentityKind.idBack]);
      expect(c.slotOf(IdentityKind.idBack), SlotState.inReview);
      c.dispose();
    });
  });

  group('ApplicationProgress (Completa tu solicitud)', () {
    final noVehicle = Checklist(driverDocuments: [_doc('Licencia de conducir', status: 'approved')], vehicles: const []);

    test('identity comes first in the next step', () {
      final p = ApplicationProgress(identity: viewOf({}), checklist: noVehicle);
      expect(p.identitySection.tone, SectionTone.action);
      expect(p.nextStep!.section, HubSection.identity);
      expect(p.nextStep!.action, 'Tomar fotos');
    });

    test('a rejected document is named with its reason', () {
      final checklist = Checklist(
        driverDocuments: [_doc('Licencia de conducir', status: 'rejected')],
        vehicles: const [],
      );
      final identity = viewOf({
        IdentityKind.selfie: IdentityPhotoStatus.approved,
        IdentityKind.idFront: IdentityPhotoStatus.approved,
        IdentityKind.idBack: IdentityPhotoStatus.approved,
      });
      final p = ApplicationProgress(identity: identity, checklist: checklist);
      expect(p.identitySection.tone, SectionTone.done);
      expect(p.documentsSection.chip, '1 por corregir');
      expect(p.nextStep!.title, 'Corrige tu licencia de conducir');
      expect(p.nextStep!.detail, 'No se lee la fecha');
    });

    test('an unknown identity reads "en revisión", never a false "falta"', () {
      final p = ApplicationProgress(identity: null, checklist: noVehicle);
      expect(p.identitySection.tone, SectionTone.review);
      expect(p.nextStep!.section, HubSection.vehicle, reason: 'the vehicle is what is really missing');
      expect(p.doneCount, 1);
    });
  });
}
