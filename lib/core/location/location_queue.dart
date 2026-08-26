import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// One position taken by the phone, waiting to be sent.
class QueuedPoint {
  const QueuedPoint({
    required this.lat,
    required this.lon,
    required this.recordedAt,
    this.accuracyM,
  });

  final double lat;
  final double lon;
  final DateTime recordedAt;
  final double? accuracyM;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        if (accuracyM != null) 'accuracyM': accuracyM,
      };

  static QueuedPoint fromJson(Map<String, dynamic> json) => QueuedPoint(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        accuracyM: (json['accuracyM'] as num?)?.toDouble(),
      );
}

/// Positions the phone took but has not managed to send yet.
///
/// Venezuela has real gaps in coverage, and without this the trail would come
/// out full of holes exactly where it matters most. Points are kept on disk and
/// flushed when the connection comes back.
///
/// A FILE rather than a database: the whole thing is a short list of tiny
/// records, and — this is the part that decides it — the tracking runs in a
/// separate isolate from the app, so whatever holds the queue has to be
/// reachable from both. A file is; an in-memory store is not.
class LocationQueue {
  LocationQueue({String fileName = 'location_queue.json'}) : _fileName = fileName;

  final String _fileName;

  /// Beyond this the oldest are dropped. At the default ten-minute interval this
  /// is well over a day of queue — and anything older than 24 h is refused by
  /// the server anyway, so keeping more would just be hoarding.
  static const int maxPoints = 200;

  /// Writes are serialised: the tracking isolate appends while a flush may be
  /// removing, and two concurrent read-modify-writes would lose points.
  Future<void> _lock = Future<void>.value();

  File? _cached;

  Future<File> _file() async {
    final cached = _cached;
    if (cached != null) return cached;
    final dir = await getApplicationDocumentsDirectory();
    return _cached = File('${dir.path}/$_fileName');
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _lock = _lock.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  Future<List<QueuedPoint>> _read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => QueuedPoint.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // A truncated or corrupt file is not worth crashing the tracker over: the
      // queue is a convenience, and losing it costs a few points, not a session.
      return [];
    }
  }

  Future<void> _write(List<QueuedPoint> points) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(points.map((p) => p.toJson()).toList()));
  }

  /// Appends a point, dropping the oldest if the queue is full.
  Future<void> add(QueuedPoint point) => _synchronized(() async {
        final points = await _read()..add(point);
        // Oldest go first: a fresh position is worth more than a stale one, and
        // the stale ones are the ones the server is about to refuse.
        final trimmed =
            points.length > maxPoints ? points.sublist(points.length - maxPoints) : points;
        await _write(trimmed);
      });

  /// Everything waiting, oldest first.
  Future<List<QueuedPoint>> all() => _synchronized(_read);

  /// Drops the first [count] points — the ones the server just accepted.
  ///
  /// Removing by COUNT rather than clearing the file: the tracker may have
  /// appended a new point while the flush was in flight, and clearing would
  /// throw it away unsent.
  Future<void> removeFirst(int count) => _synchronized(() async {
        if (count <= 0) return;
        final points = await _read();
        await _write(count >= points.length ? [] : points.sublist(count));
      });

  /// Empties it. Used on logout: the next driver on this phone must not inherit
  /// the previous one's positions.
  Future<void> clear() => _synchronized(() async {
        final file = await _file();
        if (await file.exists()) await file.delete();
      });
}
