// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import '../common.dart';

const String outputFolder = 'resources/icons';

Future<void> main() async {
  final String materialData =
      File('$flutterSdkPath/packages/flutter/lib/src/material/icons.dart')
          .readAsStringSync();
  final String cupertinoData =
      File('$flutterSdkPath/packages/flutter/lib/src/cupertino/icons.dart')
          .readAsStringSync();

  // parse into metadata
  final List<Icon> materialIcons = parseIconData(materialData);
  materialIcons.sort((a, b) => a.name.compareTo(b.name));

  final List<Icon> cupertinoIcons = parseIconData(cupertinoData);
  cupertinoIcons.sort((a, b) => a.name.compareTo(b.name));

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
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    final List<String> data = await utf8.decoder.bind(response).toList();
    return data.join('');
  } finally {
    client.close();
  }
}

// The pattern below is meant to match lines like:
//   'static const IconData threesixty = IconData(0xe577,'
final RegExp regexp =
    RegExp(r'static const IconData (\S+) = IconData\(0x(\S+),');

List<Icon> parseIconData(String data) {
  return regexp.allMatches(data).map((Match match) {
    return Icon(match.group(1)!, int.parse(match.group(2)!, radix: 16));
  }).toList();
}

void generateProperties(List<Icon> icons, String filename, String pathSegment) {
  final StringBuffer buf = StringBuffer();
  buf.writeln('# Generated file - do not edit.');
  buf.writeln();
  buf.writeln('# suppress inspection "UnusedProperty" for whole file');

  final Set<int> set = <int>{};

  for (final Icon icon in icons) {
    buf.writeln();

    if (set.contains(icon.codepoint)) {
      buf.write('# ');
    }

    buf.writeln('${icon.codepoint.toRadixString(16)}.codepoint=${icon.name}');
    buf.writeln('${icon.name}=$pathSegment/${icon.name}.png');

    set.add(icon.codepoint);
  }

  File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

void generateDart(
    List<Icon> icons, String filename, String prefix, String import) {
  final StringBuffer buf = StringBuffer();
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

  for (final Icon icon in icons) {
    buf.writeln('  new IconTuple($prefix.${icon.name}, \'${icon.name}\'),');
  }

  buf.writeln('];');

  File(filename).writeAsStringSync(buf.toString());

  print('wrote $filename');
}

Future<void> generateIcons(String appFolder) async {
  final Process proc = await Process.start(
      'flutter', <String>['run', '-d', 'flutter-tester'],
      workingDirectory: appFolder);
  // Errors in the Flutter app will not set the exit code, so we need to
  // watch stdout/stderr for errors.
  bool hasError = false;
  proc.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    if (line.contains('ERROR:')) {
      hasError = true;
    }
    stdout.writeln(line);
  });
  proc.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    hasError = true;
    stderr.writeln(line);
  });

  final int exitCode = await proc.exitCode;
  if (exitCode != 0 || hasError) {
    throw 'Process exited with error ($exitCode)';
  }
}

class Icon {
  Icon(this.name, this.codepoint);

  final String name;
  final int codepoint;

  @override
  String toString() => '$name 0x${codepoint.toRadixString(16)}';
}
