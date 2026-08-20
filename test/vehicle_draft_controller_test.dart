import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/core/network/api_exception.dart';
import 'package:edv_route_mobile/data/repositories/vehicle_draft_store.dart';
import 'package:edv_route_mobile/domain/entities/enrollment_cost.dart';
import 'package:edv_route_mobile/domain/entities/payment_method_option.dart';
import 'package:edv_route_mobile/domain/entities/picked_image.dart';
import 'package:edv_route_mobile/domain/entities/requirement.dart';
import 'package:edv_route_mobile/domain/entities/vehicle_draft.dart';
import 'package:edv_route_mobile/domain/entities/vehicle_type_option.dart';
import 'package:edv_route_mobile/domain/repositories/catalogs_repository.dart';
import 'package:edv_route_mobile/domain/repositories/enrollment_repository.dart';
import 'package:edv_route_mobile/features/enrollment/presentation/controllers/vehicle_draft_controller.dart';

/// The vehicle draft end to end, minus the network: the real store writing to a
/// real folder, and a fake backend that can also refuse. What matters most here
/// is what happens when the send FAILS — the draft is the driver's only copy.

class _FakeCatalogs implements CatalogsRepository {
  _FakeCatalogs(this.requirements);
  final List<Requirement> requirements;
  int loads = 0;

  @override
  Future<List<Requirement>> loadVehicleRequirements() async {
    loads++;
    return requirements;
  }

  @override
  Future<List<VehicleTypeOption>> loadVehicleTypes() async =>
      const [VehicleTypeOption(id: 1, name: 'moto'), VehicleTypeOption(id: 2, name: 'camioneta')];

  @override
  Future<MembershipInfo?> loadMembership() async => null;

  @override
  Future<List<PaymentMethodOption>> loadPaymentMethods() async => const [];
}

class _FakeEnrollment implements EnrollmentRepository {
  _FakeEnrollment({this.failure});

  /// When set, every send throws it.
  final ApiException? failure;
  VehicleDraft? sent;
  String? resubmittedTo;

  @override
  Future<String> submitVehicleDraft(VehicleDraft draft) async {
    if (failure != null) throw failure!;
    sent = draft;
    return 'vehicle-1';
  }

  @override
  Future<String> resubmitVehicleDraft(String vehicleId, VehicleDraft draft) async {
    if (failure != null) throw failure!;
    sent = draft;
    resubmittedTo = vehicleId;
    return vehicleId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late Directory tmp;
  late VehicleDraftStore store;

  const requirements = [
    Requirement(id: 7, name: 'Titulo', description: null, appliesTo: 'vehicle', isRequired: true),
    Requirement(id: 9, name: 'Permiso', description: null, appliesTo: 'vehicle', isRequired: true),
  ];

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('edv_draft_ctrl');
    store = VehicleDraftStore(Directory('${tmp.path}/vehicle_draft'));
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  PickedImage image(String name) => PickedImage(bytes: [1, 2, 3], filename: name);

  Future<VehicleDraftController> ready(_FakeEnrollment enrollment) async {
    final controller = VehicleDraftController(store, enrollment, _FakeCatalogs(requirements));
    await controller.load();
    await controller.updateData(plate: 'AB123CD', vehicleTypeId: 1);
    await controller.setPhoto(image('foto.jpg'));
    await controller.setDocument(7, image('titulo.pdf'));
    await controller.setDocument(9, image('permiso.pdf'));
    return controller;
  }

  test('loading brings the requirements in as empty slots', () async {
    final controller = VehicleDraftController(store, _FakeEnrollment(), _FakeCatalogs(requirements));
    await controller.load();
    expect(controller.draft.documents.length, 2);
    expect(controller.draft.isReadyToSend, isFalse);
    expect(controller.vehicleTypes.length, 2);
  });

  test('what he picks is copied into the app folder, not merely referenced', () async {
    final controller = VehicleDraftController(store, _FakeEnrollment(), _FakeCatalogs(requirements));
    await controller.load();
    await controller.setPhoto(image('foto.jpg'));
    final path = controller.draft.photoPath;
    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    expect(await File(path).readAsBytes(), [1, 2, 3]);
  });

  test('replacing the photo drops the copy it supersedes', () async {
    final controller = VehicleDraftController(store, _FakeEnrollment(), _FakeCatalogs(requirements));
    await controller.load();
    await controller.setPhoto(image('primera.jpg'));
    final first = controller.draft.photoPath!;
    await controller.setPhoto(image('segunda.jpg'));
    expect(controller.draft.photoPath, isNot(first));
    expect(File(first).existsSync(), isFalse, reason: 'la carpeta no debe crecer con cada retoma');
  });

  test('an incomplete draft is not sent at all', () async {
    final enrollment = _FakeEnrollment();
    final controller = VehicleDraftController(store, enrollment, _FakeCatalogs(requirements));
    await controller.load();
    await controller.updateData(plate: 'AB123CD', vehicleTypeId: 1);
    expect(await controller.send(), isFalse);
    expect(enrollment.sent, isNull, reason: 'ni siquiera debe intentar la llamada');
  });

  test('a complete draft goes out whole and then stops existing on the phone', () async {
    final enrollment = _FakeEnrollment();
    final controller = await ready(enrollment);
    expect(controller.draft.isReadyToSend, isTrue);

    expect(await controller.send(), isTrue);
    expect(enrollment.sent!.plate, 'AB123CD');
    expect(enrollment.sent!.documents.every((d) => d.isFilled), isTrue);
    expect(await store.load(), isNull, reason: 'ya vive en el servidor: las copias sobran');
  });

  test('if the send FAILS the draft survives with everything he cargó', () async {
    // The one that matters: a rejected plate, no signal, a 500 — losing his work
    // there would mean loading the vehicle and its papers all over again.
    final enrollment = _FakeEnrollment(failure: const ApiException('Ya existe un vehículo con esa placa'));
    final controller = await ready(enrollment);

    expect(await controller.send(), isFalse);
    expect(controller.error, 'Ya existe un vehículo con esa placa');
    expect(controller.draft.isReadyToSend, isTrue, reason: 'sigue completo, listo para reintentar');

    final stored = await store.load();
    expect(stored, isNotNull);
    expect(stored!.plate, 'AB123CD');
    expect(File(stored.photoPath!).existsSync(), isTrue);
  });

  test('correcting a rejected vehicle goes to it, not to a new one', () async {
    final enrollment = _FakeEnrollment();
    final controller = VehicleDraftController(store, enrollment, _FakeCatalogs(requirements));
    await controller.load(correctingVehicleId: 'vehiculo-rechazado');
    expect(controller.isCorrection, isTrue);
    await controller.updateData(plate: 'XY987ZW', vehicleTypeId: 2);
    await controller.setPhoto(image('foto.jpg'));
    await controller.setDocument(7, image('titulo.pdf'));
    await controller.setDocument(9, image('permiso.pdf'));

    expect(await controller.send(), isTrue);
    expect(enrollment.resubmittedTo, 'vehiculo-rechazado');
  });

  test('starting a correction throws away a draft of a different vehicle', () async {
    final controller = VehicleDraftController(store, _FakeEnrollment(), _FakeCatalogs(requirements));
    await controller.load();
    await controller.updateData(plate: 'VIEJO12', vehicleTypeId: 1);
    expect((await store.load())!.plate, 'VIEJO12');

    final other = VehicleDraftController(store, _FakeEnrollment(), _FakeCatalogs(requirements));
    await other.load(correctingVehicleId: 'otro-vehiculo');
    expect(other.draft.plate, isNull, reason: 'un solo borrador a la vez');
    expect(other.draft.correctingVehicleId, 'otro-vehiculo');
  });

  test('a draft in progress comes back when he reopens the screen', () async {
    final first = VehicleDraftController(store, _FakeEnrollment(), _FakeCatalogs(requirements));
    await first.load();
    await first.updateData(plate: 'AB123CD', brand: 'Toyota');
    await first.setDocument(7, image('titulo.pdf'));

    final second = VehicleDraftController(store, _FakeEnrollment(), _FakeCatalogs(requirements));
    await second.load();
    expect(second.draft.plate, 'AB123CD');
    expect(second.draft.brand, 'Toyota');
    expect(second.draft.documents.firstWhere((d) => d.requirementId == 7).isFilled, isTrue);
  });

  test('discarding leaves nothing behind', () async {
    final controller = await ready(_FakeEnrollment());
    await controller.discard();
    expect(controller.draft.isReadyToSend, isFalse);
    expect(await store.load(), isNull);
  });
}
