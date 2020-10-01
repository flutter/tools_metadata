// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/src/cupertino/colors.dart';
import 'package:flutter/src/material/colors.dart';
import 'package:path/path.dart' as path;

import 'generated/colors_cupertino.dart' as cupertino;
import 'generated/colors_material.dart' as material;

const String outputFolder = 'resources/colors';

Future<void> main(List<String> args) async {
  // Verify that we're running from the project root.
  if (path.basename(Directory.current.path) != 'tools_metadata') {
    print('Please run this script from the directory root.');
    exitWith(1);
  }

  print('Generating property files:');
  generatePropertiesFiles();

  print('Generating JSON files:');
  generateJsonFiles();

  exitWith(0);
}

Future<void> exitWith(int code) async {
  // TODO(dantup): If this is flaky, consider an alternative such as writing a
  // well-known string that the `flutterRun` function can wait for before terminating
  // the application.

  // If we quit immediately, `flutter run` will hang trying to connect
  // to the VM Service, so allow this to happen before we quit.
  await Future<void>.delayed(const Duration(seconds: 5));
  exit(code);
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

  writeColors(colors,
      (String name, Color color) => buf.writeln('$name=${color.toHex()}'));

  File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

void generateJson(Map<String, Color> colors, String filename) {
  final StringBuffer buf = StringBuffer();
  buf.writeln('{');
  final List<String> lines = <String>[];
  writeColors(colors, (String name, Color color) {
    lines.add('\t"$name": "${color.toHex()}"');
  });
  buf.writeln(lines.join(',\n'));
  buf.writeln('}');

  File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

void writeColors(
    Map<String, Color> colors, void writeColor(String name, Color value)) {
  for (final String name in colors.keys) {
    final Color color = colors[name];
    if (color is MaterialColor) {
      writeColor('$name.primary', color);
      for (final int shade in validShades) {
        if (color[shade] != null) {
          writeColor('$name[$shade]', color[shade]);
        }
      }
    } else if (color is MaterialAccentColor) {
      writeColor('$name.primary', color);
      for (final int shade in validShades) {
        if (color[shade] != null) {
          writeColor('$name[$shade]', color[shade]);
        }
      }
    } else if (color is CupertinoDynamicColor) {
      writeColor(name, color.color);
      writeColor('$name.darkColor', color.darkColor);
      writeColor('$name.darkElevatedColor', color.darkElevatedColor);
      writeColor('$name.darkHighContrastColor', color.darkHighContrastColor);
      writeColor('$name.darkHighContrastElevatedColor',
          color.darkHighContrastElevatedColor);
      writeColor('$name.elevatedColor', color.elevatedColor);
      writeColor('$name.highContrastColor', color.highContrastColor);
      writeColor(
          '$name.highContrastElevatedColor', color.highContrastElevatedColor);
    } else {
      writeColor(name, color);
    }
  }
}

extension ColorExtensions on Color {
  String toHex() => value.toRadixString(16).padLeft(8, '0');
}
