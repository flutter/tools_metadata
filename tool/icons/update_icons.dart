// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

const outputFolder = 'resources/icons';

void main() async {
  // download material/icons.dart and cupertino/icons.dart
  String materialData =
      await downloadUrl('https://raw.githubusercontent.com/flutter/flutter/'
          'master/packages/flutter/lib/src/material/icons.dart');
  String cupertinoData =
      await downloadUrl('https://raw.githubusercontent.com/flutter/flutter/'
          'master/packages/flutter/lib/src/cupertino/icons.dart');

  // parse into metadata
  List<Icon> materialIcons = parseIconData(materialData);
  List<Icon> cupertinoIcons = parseIconData(cupertinoData);

  // generate .properties files
  generateProperties(
      materialIcons, '$outputFolder/material.properties', 'material');
  generateProperties(
      cupertinoIcons, '$outputFolder/cupertino.properties', 'cupertino');

  // generate dart code
  generateDart(materialIcons, 'tool/icon_generator/lib/material.dart', 'Icons',
      'material');
  generateDart(cupertinoIcons, 'tool/icon_generator/lib/cupertino.dart',
      'CupertinoIcons', 'cupertino');

  // generate the icons using the flutter app
  await generateIcons('tool/icon_generator');
}

Future<String> downloadUrl(String url) async {
  final client = new HttpClient();
  try {
    HttpClientRequest request = await client.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    List<String> data = await utf8.decoder.bind(response).toList();
    return data.join('');
  } finally {
    client.close();
  }
}

// The pattern below is meant to match lines like:
//   'static const IconData threesixty = IconData(0xe577,'
final RegExp regexp =
    new RegExp(r'static const IconData (\S+) = IconData\(0x(\S+),');

List<Icon> parseIconData(String data) {
  return regexp.allMatches(data).map((Match match) {
    return Icon(match.group(1), int.parse(match.group(2), radix: 16));
  }).toList();
}

void generateProperties(List<Icon> icons, String filename, String pathSegment) {
  StringBuffer buf = StringBuffer();
  buf.writeln('# Generated file - do not edit.');
  buf.writeln();
  buf.writeln('# suppress inspection "UnusedProperty" for whole file');

  Set<int> set = new Set();

  for (Icon icon in icons) {
    buf.writeln();

    if (set.contains(icon.codepoint)) {
      buf.write('# ');
    }

    buf.writeln('${icon.codepoint.toRadixString(16)}.codepoint=${icon.name}');
    buf.writeln('${icon.name}=/flutter/$pathSegment/${icon.name}.png');

    set.add(icon.codepoint);
  }

  new File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

void generateDart(
    List<Icon> icons, String filename, String prefix, String import) {
  StringBuffer buf = StringBuffer();
  buf.writeln('''
// Generated file - do not edit.

import 'package:flutter/$import.dart';

class IconTuple {
  final IconData data;
  final String name;
  final Key smallKey = new UniqueKey();
  final Key largeKey = new UniqueKey();

  IconTuple(this.data, this.name);
}

final List<IconTuple> icons = [''');

  for (Icon icon in icons) {
    buf.writeln('  new IconTuple($prefix.${icon.name}, \'${icon.name}\'),');
  }

  buf.writeln('];');

  new File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

Future<void> generateIcons(String appFolder) async {
  final proc = await Process.start('flutter', ['run', '-d', 'flutter-tester'],
      workingDirectory: appFolder);
  await Future.wait([
    proc.stdout.pipe(stdout),
    proc.stderr.pipe(stderr),
  ]);
}

class Icon {
  final String name;
  final int codepoint;

  Icon(this.name, this.codepoint);

  String toString() => '$name 0x${codepoint.toRadixString(16)}';
}
