// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:grinder/grinder.dart';

import 'common.dart';

main(List<String> args) => grind(args);

@DefaultTask()
@Depends(colors, icons, catalog, version)
generate() => null;

@Task('Generate Flutter color information')
colors() async {
  await Dart.runAsync('tool/colors/update_colors.dart');
  await Dart.runAsync('tool/colors/generate_properties.dart',
      arguments: context.invocation.arguments.arguments);
}

@Task('Generate Flutter icon information')
icons() async {
  // Run tool/icons/update_icons.dart.
  await Dart.runAsync('tool/icons/update_icons.dart');
}

@Task('Generate Flutter catalog')
catalog() async {
  await Dart.runAsync('tool/catalog/generate_widget_catalog.dart');
}

@Task('Generate the version.json file')
version() async {
  Map<String, String> versionInfo = calculateFlutterVersion();

  File versionFile = File('resources/version.json');
  JsonEncoder encoder = JsonEncoder.withIndent('  ');
  versionFile.writeAsStringSync('${encoder.convert(versionInfo)}\n');
  log('${versionInfo['frameworkVersion']} / ${versionInfo['channel']}');
  log('Wrote ${versionFile.path}');
}
