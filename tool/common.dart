// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const String flutterBranch = 'dev';

String getFlutterSdkPath() {
  // This depends on the dart SDK being in <flutter-sdk>/bin/cache/dart-sdk/bin.
  if (!Platform.resolvedExecutable.contains('bin/cache/dart-sdk')) {
    throw 'Please run this script from the version of dart in the Flutter SDK.';
  }

  return path.dirname(path.dirname(
      path.dirname(path.dirname(path.dirname(Platform.resolvedExecutable)))));
}

Map<String, String> calculateFlutterVersion() {
  final String flutterPath = path.join(getFlutterSdkPath(), 'bin/flutter');
  final ProcessResult result =
      Process.runSync(flutterPath, <String>['--version', '--machine']);
  if (result.exitCode != 0) {
    throw 'Error from flutter --version';
  }

  return (jsonDecode(result.stdout.toString().trim()) as Map<String, dynamic>)
      .cast<String, String>();
}
