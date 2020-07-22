// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'flutter/colors_cupertino.dart';
import 'flutter/colors_material.dart';
import 'generated/colors_cupertino.dart' as cupertino;
import 'generated/colors_material.dart' as material;
import 'stubs.dart';

const String outputFolder = 'resources/colors';

Future<void> main(List<String> args) async {
  // Verify that we're running from the project root.
  if (path.basename(Directory.current.path) != 'tools_metadata') {
    print('Please run this script from the directory root.');
    exit(1);
  }

  print('Generating property files:');
  generatePropertiesFiles();

  print('Generating JSON files:');
  generateJsonFiles();
}

void generatePropertiesFiles() {
  generateProperties(material.colors, '$outputFolder/material.properties');
  generateProperties(cupertino.colors, '$outputFolder/cupertino.properties');
}

void generateJsonFiles() {
  generateJson(material.colors, '$outputFolder/material.json');
  generateJson(cupertino.colors, '$outputFolder/cupertino.json');
}

const List<int> validShades = <int>[
  50,
  100,
  200,
  300,
  350,
  400,
  500,
  600,
  700,
  800,
  850,
  900
];

void generateProperties(Map<String, Color> colors, String filename) {
  final StringBuffer buf = StringBuffer();
  buf.writeln('# Generated file - do not edit.');
  buf.writeln();
  buf.writeln('# suppress inspection "UnusedProperty" for whole file');
  buf.writeln();

  writeColors(
      colors, (String name, String value) => buf.writeln('$name=$value'));

  File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

void generateJson(Map<String, Color> colors, String filename) {
  final StringBuffer buf = StringBuffer();
  buf.writeln('{');
  writeColors(colors,
      (String name, String value) => buf.writeln('\t"$name": "$value",'));
  buf.writeln('};');
  buf.writeln();

  File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

void writeColors(
    Map<String, Color> colors, void writeColor(String name, String value)) {
  for (final String name in colors.keys) {
    final Color color = colors[name];
    if (color is MaterialColor) {
      writeColor('$name.primary', '$color');
      for (final int shade in validShades) {
        if (color[shade] != null) {
          writeColor('$name[$shade]', '${color[shade]}');
        }
      }
    } else if (color is MaterialAccentColor) {
      writeColor('$name.primary', '$color');
      for (final int shade in validShades) {
        if (color[shade] != null) {
          writeColor('$name[$shade]', '${color[shade]}');
        }
      }
    } else if (color is CupertinoDynamicColor) {
      writeColor(name, '${color.color}');
      writeColor('$name.darkColor', '${color.darkColor}');
      writeColor('$name.darkElevatedColor', '${color.darkElevatedColor}');
      writeColor(
          '$name.darkHighContrastColor', '${color.darkHighContrastColor}');
      writeColor('$name.darkHighContrastElevatedColor',
          '${color.darkHighContrastElevatedColor}');
      writeColor('$name.elevatedColor', '${color.elevatedColor}');
      writeColor('$name.highContrastColor', '${color.highContrastColor}');
      writeColor('$name.highContrastElevatedColor',
          '${color.highContrastElevatedColor}');
    } else {
      writeColor(name, '$color');
    }
  }
}
