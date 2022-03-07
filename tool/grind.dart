// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:grinder/grinder.dart';

import 'common.dart';

Future<void> main(List<String> args) => grind(args);

@DefaultTask()
@Depends(version, colors, icons, catalog)
void generate() {}

@Task('Generate Flutter color information')
Future<void> colors() async {
  await Dart.runAsync('tool/colors/update_colors.dart');
  await flutterRun('tool/colors/generate_files.dart');
}

@Task('Generate Flutter icon information')
Future<void> icons() async {
  // Run tool/icons/update_icons.dart.
  await Dart.runAsync('tool/icons/update_icons.dart');
}

@Task('Generate Flutter catalog')
Future<void> catalog() async {
  await Dart.runAsync('tool/catalog/generate_widget_catalog.dart');
}

@Task('Generate the version.json file')
Future<void> version() async {
  final Map<String, String> versionInfo = calculateFlutterVersion();

  final String actualChannel = versionInfo['channel']!;
  if (actualChannel != flutterBranch) {
    throw 'You are currently using the Flutter $actualChannel channel, please '
        'generate these files using the $flutterBranch channel.';
  }

  // Avoid generating needless diffs by mapping SSH clones onto the HTTPS URL.
  // - git@github.com:flutter/flutter.git (SSH)
  // - https://github.com/flutter/flutter (HTTPS)
  versionInfo['repositoryUrl'] = versionInfo['repositoryUrl']!
      .replaceAll('git@github.com:', 'https://github.com/')
      .replaceAll(RegExp(r'.git$'), '');

  // Remove the local installed flutter path.
  versionInfo.remove('flutterRoot');

  final File versionFile = File('resources/version.json');
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  versionFile.writeAsStringSync('${encoder.convert(versionInfo)}\n');
  log('${versionInfo['frameworkVersion']} / ${versionInfo['channel']}');
  log('Wrote ${versionFile.path}');
}
