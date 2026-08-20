import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/vehicle_draft.dart';

/// Keeps the vehicle draft on the phone between sessions.
///
/// Two things make this necessary. A driver fills this in the street, in pieces,
/// and closing the app must not throw the work away. And the paths the gallery
/// or the camera hand over are temporary — Android reclaims them — so a draft
/// that only stored those paths would come back with broken images. Every picked
/// file is COPIED into the app's own folder, which is also private storage: the
/// papers never sit anywhere another app can read them.
///
/// The base directory is injected so this can be exercised with a real temp
/// folder in tests instead of a mocked platform channel.
class VehicleDraftStore {
  final Directory baseDir;

  VehicleDraftStore(this.baseDir);

  /// The real one: the app's private support folder.
  static Future<VehicleDraftStore> open() async {
    final dir = await getApplicationSupportDirectory();
    return VehicleDraftStore(Directory('${dir.path}/vehicle_draft'));
  }

  File get _file => File('${baseDir.path}/draft.json');
  Directory get _filesDir => Directory('${baseDir.path}/files');

  /// The stored draft, or null if there is none. A corrupt file is treated as
  /// "no draft": a half-written JSON must never keep him out of the screen.
  Future<VehicleDraft?> load() async {
    try {
      if (!await _file.exists()) return null;
      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final draft = VehicleDraft.fromJson(json.cast<String, dynamic>());
      // A file may have been wiped by the system while the app was closed; a
      // path pointing nowhere would render as a broken image, so it is dropped
      // and the slot goes back to empty.
      return await _dropMissingFiles(draft);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(VehicleDraft draft) async {
    await baseDir.create(recursive: true);
    await _file.writeAsString(jsonEncode(draft.toJson()));
  }

  /// Throws the draft away, files included. Called after a successful send: from
  /// then on the vehicle lives on the server and the copies are dead weight.
  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
    if (await _filesDir.exists()) await _filesDir.delete(recursive: true);
  }

  /// Copies a picked file into the app's folder and returns its new path. The
  /// name is unique so replacing a document never collides with the previous one
  /// (and never depends on the source name, which the user does not control).
  Future<String> importFile(String sourcePath, {required String prefix}) async {
    await _filesDir.create(recursive: true);
    final extension = _extensionOf(sourcePath);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final target = File('${_filesDir.path}/${prefix}_$stamp$extension');
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  /// Removes a copy that is no longer referenced (a replaced photo or document).
  Future<void> discardFile(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<VehicleDraft> _dropMissingFiles(VehicleDraft draft) async {
    final photoGone = draft.photoPath != null && !await File(draft.photoPath!).exists();
    final documents = <DraftDocument>[];
    for (final d in draft.documents) {
      final gone = d.localPath != null && !await File(d.localPath!).exists();
      documents.add(gone ? DraftDocument(
            requirementId: d.requirementId,
            requirementName: d.requirementName,
          ) : d);
    }
    if (!photoGone && documents.every((d) => d.localPath != null || !d.isFilled)) {
      // Nothing was lost; keep the draft as it was (cheap common path).
      final sameDocs = documents.length == draft.documents.length &&
          List.generate(documents.length, (i) => documents[i].localPath == draft.documents[i].localPath)
              .every((same) => same);
      if (sameDocs) return draft;
    }
    return VehicleDraft(
      vehicleTypeId: draft.vehicleTypeId,
      brand: draft.brand,
      model: draft.model,
      year: draft.year,
      color: draft.color,
      plate: draft.plate,
      photoPath: photoGone ? null : draft.photoPath,
      documents: documents,
      correctingVehicleId: draft.correctingVehicleId,
    );
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot < path.length - 6) return '';
    return path.substring(dot).toLowerCase();
  }
}
