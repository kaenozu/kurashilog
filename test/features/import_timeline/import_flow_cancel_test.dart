import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kurashilog/features/import_timeline/import_flow_controller.dart';

void main() {
  test('cancel returns to idle and removes the temporary file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kurashilog-cancel-',
    );
    final cacheFile = File(
      '${directory.path}${Platform.pathSeparator}timeline.json',
    );
    await cacheFile.writeAsString('{}');

    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final container = ProviderContainer(
      overrides: [
        importFlowProvider.overrideWith(
          () => _ImportingStateNotifier(
            ImportFlowState(
              phase: ImportPhase.importing,
              cachePath: cacheFile.path,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(importFlowProvider.notifier);
    await notifier.cancel();

    expect(container.read(importFlowProvider).phase, ImportPhase.idle);
    expect(await cacheFile.exists(), isFalse);
  });
}

class _ImportingStateNotifier extends ImportFlowNotifier {
  _ImportingStateNotifier(this.initialState);

  final ImportFlowState initialState;

  @override
  ImportFlowState build() => initialState;
}
