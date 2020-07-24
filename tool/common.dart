// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const String flutterBranch = 'dev';

final String flutterSdkPath = _getFlutterSdkPath();

String _getFlutterSdkPath() {
  // This depends on the dart SDK being in <flutter-sdk>/bin/cache/dart-sdk/bin.
  if (!Platform.resolvedExecutable.contains('bin/cache/dart-sdk')) {
    throw 'Please run this script from the version of dart in the Flutter SDK.';
  }

  return path.dirname(path.dirname(
      path.dirname(path.dirname(path.dirname(Platform.resolvedExecutable)))));
}

Map<String, String> calculateFlutterVersion() {
  final String flutterPath = path.join(flutterSdkPath, 'bin/flutter');
  final ProcessResult result =
      Process.runSync(flutterPath, <String>['--version', '--machine']);
  if (result.exitCode != 0) {
    throw 'Error from flutter --version';
  }

  return (jsonDecode(result.stdout.toString().trim()) as Map<String, dynamic>)
      .cast<String, String>();
}

Future<void> flutterRun(String script) async {
  final Process proc = await Process.start(
      'flutter', <String>['run', '-d', 'flutter-tester', '-t', script]);
  proc.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(stdout.writeln);
  proc.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(stderr.writeln);
  final int exitCode = await proc.exitCode;
  if (exitCode != 0) {
    throw 'Process exited with code $exitCode';
  }
}
