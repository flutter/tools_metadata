#!/bin/bash
set -e # exit on errors

BOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$BOTDIR/.."

git clone https://github.com/flutter/flutter --branch dev "$BOTDIR/temp/flutter"
export PATH="$BOTDIR/temp/flutter/bin:$PATH"

flutter config --no-analytics
flutter doctor -v

echo "Fetching dependencies..."
flutter pub get

echo "Analyzing project"
flutter analyze

echo "Analyzing icon_generator"
pushd tool/icon_generator
flutter analyze
popd

echo "Generating all content"
# TODO(dantup): Remove "generate" from the end after #8 lands.
flutter pub run grinder generate
