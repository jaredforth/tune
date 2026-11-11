#!/bin/sh
# Compiles the pure logic (Tune/Pitch.swift) with tools/test/main.swift and runs it.
set -e
cd "$(dirname "$0")"
t=$(mktemp -d)
swiftc -O Tune/Pitch.swift tools/test/main.swift -o "$t/test"
"$t/test"; rm -rf "$t"
