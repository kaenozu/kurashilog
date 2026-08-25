import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kurashilog/platform');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('openLocationSettings', () {
    test('maps the direct public location settings destination', () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return 'locationSources';
      });

      final result = await AppPlatform(channel: channel).openLocationSettings();

      expect(received?.method, 'openLocationSettings');
      expect(received?.arguments, isNull);
      expect(result, LocationSettingsDestination.locationSources);
    });

    test('reports when Android opened general settings as fallback', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => 'generalSettings',
      );

      final result = await AppPlatform(channel: channel).openLocationSettings();

      expect(result, LocationSettingsDestination.generalSettings);
    });

    test('fails closed on an unknown native response', () async {
      messenger.setMockMethodCallHandler(channel, (_) async => 'other');

      await expectLater(
        AppPlatform(channel: channel).openLocationSettings(),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'INVALID_RESPONSE',
          ),
        ),
      );
    });

    test('preserves structured native errors without guessing', () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'ACTIVITY_NOT_FOUND',
          message: '設定画面を開けませんでした',
        );
      });

      await expectLater(
        AppPlatform(channel: channel).openLocationSettings(),
        throwsA(
          isA<PlatformException>()
              .having((error) => error.code, 'code', 'ACTIVITY_NOT_FOUND')
              .having((error) => error.message, 'message', '設定画面を開けませんでした'),
        ),
      );
    });
  });

  test('picker cancellation and no pending share remain null', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, anyOf('pickJsonFile', 'takeSharedFile'));
      return null;
    });
    final platform = AppPlatform(channel: channel);

    expect(await platform.pickJsonFile(), isNull);
    expect(await platform.takeSharedFile(), isNull);
  });

  test(
    'copyUriToCache sends the URI only across the private channel',
    () async {
      const uri = 'content://private-provider/timeline';
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'copyUriToCache');
        expect(call.arguments, <String, Object?>{'uri': uri});
        return '/private/cache/timeline.json';
      });

      final result = await AppPlatform(channel: channel).copyUriToCache(uri);

      expect(result, '/private/cache/timeline.json');
    },
  );

  test('copyUriToCache rejects a null native path', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);

    await expectLater(
      AppPlatform(
        channel: channel,
      ).copyUriToCache('content://private-provider/timeline'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'IO_ERROR',
        ),
      ),
    );
  });

  test('deleteCacheFile deletes existing files and accepts null', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kurashilog-app-platform-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File('${directory.path}${Platform.pathSeparator}cache.json');
    await file.writeAsString('{}');

    await deleteCacheFile(file.path);
    await deleteCacheFile(null);

    expect(await file.exists(), isFalse);
  });

  test(
    'Android source uses public intents and redacts private identifiers',
    () {
      final source = File(
        'android/app/src/main/kotlin/com/kurashilog/kurashilog/'
        'MainActivity.kt',
      ).readAsStringSync();

      expect(source, contains('Settings.ACTION_LOCATION_SOURCE_SETTINGS'));
      expect(source, contains('Settings.ACTION_SETTINGS'));
      expect(source, contains('ACTIVITY_NOT_FOUND'));
      expect(source, contains('SECURITY_ERROR'));
      expect(source, contains('PLATFORM_ERROR'));
      expect(source, isNot(contains(r'cannot open $uri')));
      expect(source, isNot(contains('e.message')));
      expect(source, isNot(contains('result.error("IO_ERROR", uri')));
    },
  );

  test('Android picker fails closed on overlap and ignores stale results', () {
    final source = File(
      'android/app/src/main/kotlin/com/kurashilog/kurashilog/'
      'MainActivity.kt',
    ).readAsStringSync();

    expect(source, contains('if (pickResult != null)'));
    expect(source, contains('PICK_IN_PROGRESS'));
    expect(source, contains('val r = pickResult ?: return'));
    expect(source, contains('pickResult = null'));
  });
}
