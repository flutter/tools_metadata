#!/bin/bash
set -e # exit on errors

BOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$BOTDIR/.."

if [ ! -d "$BOTDIR/temp/flutter" ]; then
	git clone https://github.com/flutter/flutter --branch beta "$BOTDIR/temp/flutter"
fi
export PATH="$BOTDIR/temp/flutter/bin:$PATH"

flutter config --no-analytics
flutter doctor -v

echo "Fetching dependencies..."
flutter pub get
pushd tool/icon_generator
flutter pub get
popd

echo "Analyzing project"
flutter analyze

echo "Analyzing icon_generator"
pushd tool/icon_generator
flutter analyze
popd

echo "Generating all content"
flutter pub run grinder
