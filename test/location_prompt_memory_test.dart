import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/core/location/location_prompt_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> store;

  setUp(() {
    store = {};
    // The plugin talks to the Keystore, which does not exist in a test. Serve it
    // from a map instead: what is under test is the remembering, not Android.
    FlutterSecureStorage.setMockInitialValues(store);
  });

  test('the explanation is remembered, so it is not repeated every launch',
      () async {
    final memory = LocationPromptMemory();
    expect(await memory.wasShown(), isFalse);

    await memory.markShown();
    // A brand new instance: this only counts if it survived the object, which is
    // what "every launch" means.
    expect(await LocationPromptMemory().wasShown(), isTrue);
  });

  test('logout forgets it: the next driver gets the explanation too', () async {
    final memory = LocationPromptMemory();
    await memory.markShown();
    await memory.clear();

    expect(await memory.wasShown(), isFalse);
  });
}
