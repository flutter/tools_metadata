// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../common.dart';

// TODO(dantup): Use this from the local Flutter checkout.
const String flutterPackageSourceUrl =
    'https://raw.githubusercontent.com/flutter/flutter/'
    '$flutterBranch/packages/flutter/lib/src';
const String materialColorsUrl =
    '$flutterPackageSourceUrl/material/colors.dart';
const String cupertinoColorsUrl =
    '$flutterPackageSourceUrl/cupertino/colors.dart';
final File materialFile = File('tool/colors/flutter/colors_material.dart');
final File cupertinoFile = File('tool/colors/flutter/colors_cupertino.dart');
const String generatedFilesPath = 'tool/colors/generated';

Future<void> main(List<String> args) async {
  // Verify that we're running from the project root.
  if (path.basename(Directory.current.path) != 'tools_metadata') {
    print('Please run this script from the directory root.');
    exit(1);
  }

  print('Generating dart files:');
  await generateDartFiles();
}

Future<void> generateDartFiles() async {
  // TODO(dantup): Use the files from the local flutter checkout instead of a download
  // download material/colors.dart and cupertino/colors.dart
  await Future.wait(<Future<void>>[
    downloadFile(materialColorsUrl, materialFile),
    downloadFile(cupertinoColorsUrl, cupertinoFile)
  ]);

  // parse into metadata
  final List<String> materialColors = extractColorNames(materialFile);
  final List<String> cupertinoColors = extractColorNames(cupertinoFile);

  // generate .properties files
  generateDart(materialColors, 'colors_material.dart', 'Colors');
  generateDart(cupertinoColors, 'colors_cupertino.dart', 'CupertinoColors');
}

Future<void> downloadFile(String url, File file) async {
  final RegExp imports = RegExp(r'(?:^import.*;\n{1,})+', multiLine: true);
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    final List<String> data = await utf8.decoder.bind(response).toList();
    final String contents = data.join('').replaceFirst(imports, '''
// ignore_for_file: unused_import
import 'package:meta/meta.dart';
import '../stubs.dart';
\n''');

    file.writeAsStringSync(
      '// This file was downloaded by update_colors.dart.\n\n'
      '$contents',
    );
  } finally {
    client.close();
  }
}

// The pattern below is meant to match lines like:
//   'static const Color black45 = Color(0x73000000);'
//   'static const MaterialColor cyan = MaterialColor('
//   'static const CupertinoDynamicColor activeBlue = systemBlue;'
//   'static const CupertinoDynamicColor systemGreen = CupertinoDynamicColor.withBrightnessAndContrast('
final RegExp regexpColor = RegExp(r'static const \w*Color (\S+) =');

List<String> extractColorNames(File file) {
  final String data = file.readAsStringSync();

  final List<String> names = regexpColor
      .allMatches(data)
      .map((Match match) => match.group(1))
      .toList();

  // Remove any duplicates.
  return Set<String>.from(names).toList()..sort();
}

void generateDart(List<String> colors, String filename, String className) {
  final StringBuffer buf = StringBuffer();
  buf.writeln('''
// Generated file - do not edit.

import '../flutter/$filename';
import '../stubs.dart';

final Map<String, Color> colors = <String, Color>{''');

  for (final String colorName in colors) {
    buf.writeln("  '$colorName': $className.$colorName,");
  }

  buf.writeln('};');

  final File out = File('$generatedFilesPath/$filename');
  out.writeAsStringSync(buf.toString());

  print('wrote ${out.path}');
}
