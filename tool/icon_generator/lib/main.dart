// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'cupertino.dart' as cupertino;
import 'material.dart' as material;

final String toolsRoot = path.normalize(
  path.join(Directory.current.path, '../..'),
);
final String resourcesFolder = path.join(toolsRoot, 'resources', 'icons');

Future main() async {
  // Verify that we're running from the project root.
  if (!await _fromTheProjectRoot(toolsRoot)) {
    print('Please run this tool from the root of the project.');
    exit(1);
  }

  MyIconApp app = MyIconApp(material.icons, cupertino.icons);
  runApp(app);

  await pumpEventQueue();

  // TODO(devoncarew): Below, we could queue up some or all findAndSave()
  // operations and then wait for all futures to complete (using a Pool?).
  // Assuming we don't get out of memory issues this might finish much faster as
  // there is a decent amount of delay getting data from the gpu for each icon.

  for (material.IconTuple icon in material.icons) {
    await findAndSave(
      icon.smallKey,
      path.join(resourcesFolder, 'material', '${icon.name}.png'),
      small: true,
    );
    await findAndSave(
      icon.largeKey,
      path.join(resourcesFolder, 'material', '${icon.name}@2x.png'),
      small: false,
    );
  }

  for (cupertino.IconTuple icon in cupertino.icons) {
    await findAndSave(
      icon.smallKey,
      path.join(resourcesFolder, 'cupertino', '${icon.name}.png'),
      small: true,
    );
    await findAndSave(
      icon.largeKey,
      path.join(resourcesFolder, 'cupertino', '${icon.name}@2x.png'),
      small: false,
    );
  }

  print('Finished generating icons, quitting...');
  exit(0);
}

class MyIconApp extends StatelessWidget {
  MyIconApp(this.materialIcons, this.cupertinoIcons) : super(key: UniqueKey());

  final List<material.IconTuple> materialIcons;
  final List<cupertino.IconTuple> cupertinoIcons;

  @override
  Widget build(BuildContext context) {
    // We use this color as it works well in both light and dark themes.
    const Color color = Color(0xFF777777);

    Stack cupertinoSmallStack = Stack(
      children: cupertinoIcons.map<Widget>((cupertino.IconTuple icon) {
        return RepaintBoundary(
          child: Icon(
            icon.data,
            size: 16.0,
            color: color,
            key: icon.smallKey,
          ),
        );
      }).toList(),
    );

    Stack cupertinoLargeStack = Stack(
      children: cupertinoIcons.map<Widget>((cupertino.IconTuple icon) {
        return RepaintBoundary(
          child: Icon(
            icon.data,
            size: 32.0,
            color: color,
            key: icon.largeKey,
          ),
        );
      }).toList(),
    );

    Stack materialSmallStack = Stack(
      children: materialIcons.map<Widget>((material.IconTuple icon) {
        return RepaintBoundary(
          child: Icon(
            icon.data,
            size: 16.0,
            color: color,
            key: icon.smallKey,
          ),
        );
      }).toList(),
    );

    Stack materialLargeStack = Stack(
      children: materialIcons.map<Widget>((material.IconTuple icon) {
        return RepaintBoundary(
          child: Icon(
            icon.data,
            size: 32.0,
            color: color,
            key: icon.largeKey,
          ),
        );
      }).toList(),
    );

    return MaterialApp(
      title: 'Flutter Demo',
      home: Center(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              cupertinoSmallStack,
              materialSmallStack,
            ]),
            Row(children: <Widget>[
              cupertinoLargeStack,
              materialLargeStack,
            ]),
          ],
        ),
      ),
    );
  }
}

Future findAndSave(Key key, String path, {bool small = true}) async {
  Finder finder = find.byKey(key);

  final Iterable<Element> elements = finder.evaluate();
  Element element = elements.first;

  Future<ui.Image> imageFuture = _captureImage(element);

  final ui.Image image = await imageFuture;
  final ByteData bytes =
      (await image.toByteData(format: ui.ImageByteFormat.png))!;

  await File(path).writeAsBytes(bytes.buffer.asUint8List());

  print('wrote $path');
}

Future<ui.Image> _captureImage(Element element) {
  // Copied from package:flutter_test/src/_matchers_io.dart.
  assert(element.renderObject != null);
  RenderObject renderObject = element.renderObject!;
  while (!renderObject.isRepaintBoundary) {
    renderObject = renderObject.parent!;
  }
  assert(!renderObject.debugNeedsPaint);
  final OffsetLayer layer = renderObject.debugLayer! as OffsetLayer;
  return layer.toImage(renderObject.paintBounds);
}

/// Determine whether the environment is based from the project root
/// by validate the name of the pubspec if it exists.
Future<bool> _fromTheProjectRoot(String rootPath) async {
  final yamlPath = path.join(rootPath, 'pubspec.yaml');
  if (!File(yamlPath).existsSync()) {
    return false;
  }
  final yamlMap =
      (await loadYaml(await File(yamlPath).readAsString()) as YamlMap);
  return yamlMap['name'] == 'tool_metadata';
}
