import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:edv_route_mobile/core/location/location_queue.dart';

/// Serves the queue a real temp directory instead of the platform channel.
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('edv_queue_test');
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  QueuedPoint point(int minutesAgo) => QueuedPoint(
        lat: 10.48,
        lon: -66.90,
        accuracyM: 8,
        recordedAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      );

  test('points survive a restart: the queue is on disk, not in memory', () async {
    // This is the whole reason it is a file — the tracking runs in a separate
    // isolate from the app, so an in-memory queue would be invisible to it.
    await LocationQueue().add(point(10));
    await LocationQueue().add(point(5));

    final reopened = await LocationQueue().all();
    expect(reopened.length, 2);
    expect(reopened.first.lat, closeTo(10.48, 0.0001));
  });

  test('sent points are dropped by count, not by clearing the file', () async {
    final queue = LocationQueue();
    await queue.add(point(20));
    await queue.add(point(10));

    final pending = await queue.all();
    // A point captured WHILE the flush is in flight: clearing the file instead
    // of removing by count would throw this one away unsent.
    await queue.add(point(0));
    await queue.removeFirst(pending.length);

    final left = await queue.all();
    expect(left.length, 1, reason: 'el punto capturado durante el envío debe sobrevivir');
  });

  test('a full queue drops the OLDEST, never the newest', () async {
    final queue = LocationQueue();
    for (var i = 0; i < LocationQueue.maxPoints + 10; i++) {
      // Oldest first, so the newest carry the smallest offsets.
      await queue.add(point(LocationQueue.maxPoints + 10 - i));
    }

    final all = await queue.all();
    expect(all.length, LocationQueue.maxPoints);
    // A fresh position is worth more than a stale one — and the stale ones are
    // exactly what the server refuses past 24 h.
    final oldest = all.first.recordedAt;
    final newest = all.last.recordedAt;
    expect(newest.isAfter(oldest), isTrue);
    expect(
      DateTime.now().difference(oldest).inMinutes,
      lessThanOrEqualTo(LocationQueue.maxPoints),
    );
  });

  test('clear() empties it — the next driver on this phone starts blank', () async {
    final queue = LocationQueue();
    await queue.add(point(5));
    await queue.clear();
    expect(await queue.all(), isEmpty);
  });

  test('a corrupt file costs the queue, never a crash', () async {
    await LocationQueue().add(point(5));
    // Half-written file: a killed process mid-write is exactly how this happens.
    await File('${dir.path}/location_queue.json').writeAsString('[{"lat":10.4');

    expect(await LocationQueue().all(), isEmpty);
    // And it recovers: the next point writes a valid file again.
    await LocationQueue().add(point(1));
    expect((await LocationQueue().all()).length, 1);
  });

  test('a point survives the round trip through JSON intact', () async {
    final queue = LocationQueue();
    final original = point(7);
    await queue.add(original);

    final restored = (await queue.all()).single;
    expect(restored.lat, original.lat);
    expect(restored.lon, original.lon);
    expect(restored.accuracyM, original.accuracyM);
    // Sent as UTC so the server never has to guess the phone's timezone.
    expect(
      restored.recordedAt.toUtc().millisecondsSinceEpoch,
      original.recordedAt.toUtc().millisecondsSinceEpoch,
    );
  });

  test('concurrent adds do not lose points to a read-modify-write race',
      () async {
    final queue = LocationQueue();
    // The tracker appends while a flush may be rewriting the file; without the
    // internal lock, whichever wrote last would erase the other's work.
    await Future.wait(List.generate(20, (i) => queue.add(point(i))));
    expect((await queue.all()).length, 20);
  });
}
