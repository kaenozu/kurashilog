import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workflow = File('.github/workflows/ci.yml').readAsStringSync();

  test('CI pins the Flutter SDK used to resolve the committed lockfile', () {
    expect(workflow, contains('flutter-version: 3.44.0'));
  });

  test('CI validates the checkout without recreating the Flutter project', () {
    expect(workflow, isNot(contains('flutter create')));
    expect(
      workflow,
      contains('Assert dependency resolution kept tracked sources clean'),
    );
  });
}
