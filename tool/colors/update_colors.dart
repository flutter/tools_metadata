// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

import '../common.dart';

final String flutterPackageSourcePath =
    '$flutterSdkPath/packages/flutter/lib/src';
final File materialColorsFile =
    File('$flutterPackageSourcePath/material/colors.dart');
final File cupertinoColorsFile =
    File('$flutterPackageSourcePath/cupertino/colors.dart');
File cssColorsFile;
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
  // Get the path to the source file
  cssColorsFile = File((await Isolate.resolvePackageUri(
          Uri.parse('package:css_colors/css_colors.dart')))
      .toFilePath());

  // parse into metadata
  final List<String> materialColors = extractColorNames(materialColorsFile);
  final List<String> cupertinoColors = extractColorNames(cupertinoColorsFile);
  final List<String> cssColors = extractColorNames(cssColorsFile);

  // generate .properties files
  generateDart(materialColors, 'material', 'Colors',
      'package:flutter/src/material/colors.dart');
  generateDart(cupertinoColors, 'cupertino', 'CupertinoColors',
      'package:flutter/src/cupertino/colors.dart');
  generateDart(cssColors, 'css', 'CSSColors',
      'package:css_colors/css_colors.dart');
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

void generateDart(
  List<String> colors,
  String colorType,
  String className,
  String importUri,
) {
  final StringBuffer buf = StringBuffer();
  buf.writeln('''
// Generated file - do not edit.

import 'dart:ui';

import '$importUri';

final Map<String, Color> colors = <String, Color>{''');

  for (final String colorName in colors) {
    buf.writeln("  '$colorName': $className.$colorName,");
  }

  buf.writeln('};');

  final File out = File('$generatedFilesPath/colors_$colorType.dart');
  out.writeAsStringSync(buf.toString());

  print('wrote ${out.path}');
}
