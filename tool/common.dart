// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

String getFlutterSdkPath() {
  // This depends on the dart SDK being in <flutter-sdk>/bin/cache/dart-sdk/bin.
  return path.dirname(path.dirname(
      path.dirname(path.dirname(path.dirname(Platform.resolvedExecutable)))));
}

Map<String, String> calculateFlutterVersion() {
  String flutterPath = path.join(getFlutterSdkPath(), 'bin/flutter');
  ProcessResult result =
      Process.runSync(flutterPath, ['--version', '--machine']);
  if (result.exitCode != 0) {
    throw 'Error from flutter --version';
  }

  return (jsonDecode(result.stdout.toString().trim()) as Map)
      .cast<String, String>();
}
