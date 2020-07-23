// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:http/http.dart' as http;

import 'common.dart';

Future<void> main(List<String> args) => grind(args);

@DefaultTask()
@Depends(analysisOptions, colors, icons, catalog, version)
void generate() {}

@Task('Sync analysis_options from Flutter')
Future<void> analysisOptions() async {
  // TODO(dantup): Use this from the local Flutter checkout.
  const String analysisOptionsUrl =
      'https://raw.githubusercontent.com/flutter/flutter/$flutterBranch/analysis_options.yaml';
  final http.Client client = http.Client();
  try {
    final http.Response resp = await client.get(analysisOptionsUrl);

    // Additional exclusion for this project.
    final String additionalExclusions = <String>[
      'bots/temp/**',
      'tool/icon_generator/**',
    ].map((String ex) => "    - '$ex'\n").join();

    // Insert them into the correct place in the analysis_options content.
    final String analysisOptionsContents = resp.body.replaceAll(
      '\n  exclude:\n',
      '\n  exclude:\n$additionalExclusions',
    );

    File('analysis_options.yaml').writeAsStringSync(
      '# This file is downloaded from the Flutter repository in grind.dart.\n\n'
      '$analysisOptionsContents\n',
    );
  } finally {
    client.close();
  }
}

@Task('Generate Flutter color information')
Future<void> colors() async {
  await Dart.runAsync('tool/colors/update_colors.dart');
  await Dart.runAsync('tool/colors/generate_files.dart');
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

  final File versionFile = File('resources/version.json');
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  versionFile.writeAsStringSync('${encoder.convert(versionInfo)}\n');
  log('${versionInfo['frameworkVersion']} / ${versionInfo['channel']}');
  log('Wrote ${versionFile.path}');
}
