## What's this?

This repo holds generated metadata about the Flutter framework.

The metadata is useful for Flutter related tooling and is currently used by
Flutter IDE tools such as the Flutter IntelliJ and VS Code plugins.

If you're using this metadata, please let us know! You can open an [issue] on the
repo (please use the `d: tools_metadata` label) or add your tool to this readme
via a pull request.

## Tools that use this metadata

- the [Flutter IntelliJ] plugin (for IntelliJ and Android Studio)
- the [Dart-Code] VS Code plugin

## Available metadata

The generated framework data lives at
https://github.com/flutter/tools_metadata/tree/master/resources.

### Widget Catalog

Available
[here](https://github.com/flutter/tools_metadata/blob/master/resources/catalog/widgets.json),
this is the full set of all public widgets from the Flutter framework. It
includes information like the widget name, it's parent, the library it's defined
in - like `material`, and the description of the widget.

### Colors

This is a mapping of Flutter framework color names to color values, for both the
Material and Cupertino sets of colors. It's available in property file and json
formats.

Note: Colors are in the format `AARRGGBB` matching Flutter constructor calls (`Color(0xAARRGGBB)`)
which has alpha in a different position than HTML/CSS hex colors (`#RRGGBBAA`).

https://github.com/flutter/tools_metadata/tree/master/resources/colors

### Icons

This is a mapping of:

- font codepoints to icon names, and
- icon names to file paths for preview icons

This information is available for both the Material and Cupertino icons. In
addition, each framework icon has 16x16 and 32x32 preview png images.

https://github.com/flutter/tools_metadata/tree/master/resources/icons

## Working on the repo

### Existing issues

We track issues for this repo in the flutter/flutter issue tracker. See issues
with the [d: tools_metadata][issue] label for all open issues.

### Regenerating metadata

To re-generate the metadata, run `flutter pub run grind generate` from the
command line. That will regenerate the metadata from the version of the flutter
framework currently in use. Note that we do not want to commit generated
metadata from versions of the framework from Flutter's master channel; currently
we're regenerating from the dev channel.

[Flutter IntelliJ]: https://github.com/flutter/flutter-intellij
[Dart-Code]: https://github.com/Dart-Code/Dart-Code
[issue]: https://github.com/flutter/flutter/labels/d%3A%20tools_metadata
