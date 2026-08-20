import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/domain/entities/vehicle_draft.dart';
import 'package:edv_route_mobile/data/repositories/vehicle_draft_store.dart';

/// The vehicle draft: what the phone holds before the server hears about it.
/// Exercised against a REAL temp folder — the point of this piece is that files
/// survive on disk, and a mocked filesystem would prove nothing.
void main() {
  late Directory tmp;
  late VehicleDraftStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('edv_draft_test');
    store = VehicleDraftStore(Directory('${tmp.path}/vehicle_draft'));
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<String> makeFile(String name, [String content = 'x']) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsString(content);
    return f.path;
  }

  const requirements = [(id: 7, name: 'Titulo'), (id: 9, name: 'Permiso'), (id: 10, name: 'Trimestres')];

  group('when the draft is ready to send', () {
    test('an empty draft is not, and says what it needs', () {
      const draft = VehicleDraft();
      expect(draft.isReadyToSend, isFalse);
      expect(draft.pendingReasons, isNotEmpty);
    });

    test('data and photo are not enough without the documents', () {
      final draft = const VehicleDraft(plate: 'AB123CD', vehicleTypeId: 1, photoPath: '/x.jpg')
          .syncRequirements(requirements);
      expect(draft.isReadyToSend, isFalse);
      expect(draft.missingDocuments.length, 3);
      expect(draft.pendingReasons, contains('Falta Titulo'));
    });

    test('documents without the photo are not enough either', () {
      var draft = const VehicleDraft(plate: 'AB123CD', vehicleTypeId: 1).syncRequirements(requirements);
      for (final r in requirements) {
        draft = draft.withDocumentFile(r.id, '/tmp/${r.id}.pdf', '${r.name}.pdf');
      }
      expect(draft.isReadyToSend, isFalse);
      expect(draft.pendingReasons, contains('Agrega la foto del vehículo'));
    });

    test('with the plate, the type, the photo and every document, it is ready', () {
      var draft = const VehicleDraft(plate: 'AB123CD', vehicleTypeId: 1, photoPath: '/x.jpg')
          .syncRequirements(requirements);
      for (final r in requirements) {
        draft = draft.withDocumentFile(r.id, '/tmp/${r.id}.pdf', '${r.name}.pdf');
      }
      expect(draft.isReadyToSend, isTrue);
      expect(draft.pendingReasons, isEmpty);
    });
  });

  group('requirements changing under the draft', () {
    test('a new requirement appears as an empty slot and blocks the send', () {
      var draft = const VehicleDraft(plate: 'AB123CD', vehicleTypeId: 1, photoPath: '/x.jpg')
          .syncRequirements(requirements);
      for (final r in requirements) {
        draft = draft.withDocumentFile(r.id, '/tmp/${r.id}.pdf', '${r.name}.pdf');
      }
      final withNewOne = draft.syncRequirements([...requirements, (id: 11, name: 'Seguro')]);
      expect(withNewOne.isReadyToSend, isFalse);
      expect(withNewOne.pendingReasons, contains('Falta Seguro'));
    });

    test('a requirement that no longer applies stops being demanded', () {
      var draft = const VehicleDraft(plate: 'AB123CD', vehicleTypeId: 1, photoPath: '/x.jpg')
          .syncRequirements(requirements);
      draft = draft.withDocumentFile(7, '/tmp/7.pdf', 'Titulo.pdf');
      final trimmed = draft.syncRequirements([(id: 7, name: 'Titulo')]);
      expect(trimmed.isReadyToSend, isTrue);
    });

    test('files already attached survive the sync', () {
      var draft = const VehicleDraft().syncRequirements(requirements);
      draft = draft.withDocumentFile(9, '/tmp/9.pdf', 'Permiso.pdf');
      final synced = draft.syncRequirements(requirements);
      expect(synced.documents.firstWhere((d) => d.requirementId == 9).localPath, '/tmp/9.pdf');
    });
  });

  group('surviving a restart', () {
    test('a saved draft comes back with its data and its files', () async {
      final photo = await store.importFile(await makeFile('camera.jpg'), prefix: 'photo');
      final doc = await store.importFile(await makeFile('scan.pdf'), prefix: 'doc7');
      final draft = const VehicleDraft(plate: 'XY987ZW', vehicleTypeId: 2, brand: 'Toyota')
          .syncRequirements(requirements)
          .copyWith(photoPath: photo)
          .withDocumentFile(7, doc, 'scan.pdf');
      await store.save(draft);

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.plate, 'XY987ZW');
      expect(loaded.brand, 'Toyota');
      expect(loaded.photoPath, photo);
      expect(File(loaded.photoPath!).existsSync(), isTrue,
          reason: 'la foto debe seguir en la carpeta privada de la app');
      expect(loaded.documents.firstWhere((d) => d.requirementId == 7).fileName, 'scan.pdf');
    });

    test('the copy is independent of the original the gallery hands over', () async {
      final source = await makeFile('temp_from_gallery.jpg', 'contenido');
      final copied = await store.importFile(source, prefix: 'photo');
      await File(source).delete(); // Android reclaims the temporary file
      expect(File(copied).existsSync(), isTrue);
      expect(await File(copied).readAsString(), 'contenido');
    });

    test('a file lost while the app was closed leaves its slot empty, not broken', () async {
      final doc = await store.importFile(await makeFile('scan.pdf'), prefix: 'doc7');
      final draft = const VehicleDraft(plate: 'AB123CD', vehicleTypeId: 1)
          .syncRequirements(requirements)
          .withDocumentFile(7, doc, 'scan.pdf');
      await store.save(draft);
      await File(doc).delete();

      final loaded = await store.load();
      expect(loaded!.documents.firstWhere((d) => d.requirementId == 7).isFilled, isFalse);
      expect(loaded.plate, 'AB123CD', reason: 'el resto del borrador se conserva');
    });

    test('no draft saved reads as no draft', () async {
      expect(await store.load(), isNull);
    });

    test('a corrupt file reads as no draft instead of crashing the screen', () async {
      await store.baseDir.create(recursive: true);
      await File('${store.baseDir.path}/draft.json').writeAsString('{esto no es json');
      expect(await store.load(), isNull);
    });

    test('clearing after sending removes the draft and its files', () async {
      final photo = await store.importFile(await makeFile('camera.jpg'), prefix: 'photo');
      await store.save(const VehicleDraft(plate: 'AB123CD').copyWith(photoPath: photo));
      await store.clear();
      expect(await store.load(), isNull);
      expect(File(photo).existsSync(), isFalse);
    });
  });
}
