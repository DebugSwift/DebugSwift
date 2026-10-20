#!/bin/bash
set -euo pipefail

task_build_dir=$(mktemp -d /tmp/debugswift-symbol-map-tests.XXXXXX)
task_fixture="Example/ExampleTests/Tests/Features/App/Crash/Native"
task_binary="$task_build_dir/SymbolMapFixture"
task_output="$task_build_dir/symbol_map.json"

xcrun swiftc -g -c -module-cache-path "$task_build_dir/module-cache" \
    -module-name SymbolMapFixture "$task_fixture/SymbolMapFixture.swift" -o "$task_build_dir/Fixture.o"
xcrun swiftc -g "$task_build_dir/Fixture.o" -o "$task_binary"
xcrun dsymutil "$task_binary" -o "$task_binary.dSYM"
bash Scripts/generate_symbol_map.sh "$task_binary" "$task_output" --dsym "$task_binary.dSYM"
/usr/bin/python3 - "$task_binary" "$task_output" <<'PY'
import json, re, subprocess, sys
with open(sys.argv[2]) as stream:
    table = json.load(stream)
identity = re.search(r"UUID: ([0-9A-F-]+)", subprocess.check_output(
    ["xcrun", "dwarfdump", "--uuid", sys.argv[1]], text=True)).group(1)
assert table["imageUUID"] == identity
symbols = [s for s in table["symbols"] if "debugSwiftSymbolMapFixture" in s["name"]]
assert symbols, "Swift names were not demangled"
assert any(s["line"] > 0 and s["file"].endswith("SymbolMapFixture.swift") for s in symbols)
assert all(s["address"] >= table["loadAddress"] for s in table["symbols"])
print("PASS: linked UUID, preferred addresses, Swift names and source locations")
PY

# A stripped executable must still resolve its private functions through its dSYM.
xcrun strip -x "$task_binary"
bash Scripts/generate_symbol_map.sh "$task_binary" "$task_build_dir/stripped.json" --dsym "$task_binary.dSYM"
cmp "$task_output" "$task_build_dir/stripped.json"
echo "PASS: matching dSYM recovers symbols removed from the binary"

xcrun clang -dynamiclib -g -arch arm64 -arch x86_64 \
    "$task_fixture/SignalCaptureFixture.c" -o "$task_build_dir/Other.dylib"
if bash Scripts/generate_symbol_map.sh "$task_build_dir/Other.dylib" "$task_output"; then
    echo "FAIL: accepted ambiguous universal binary" >&2
    exit 1
fi
cmp "$task_output" "$task_build_dir/stripped.json"
echo "PASS: universal binary requires explicit architecture and preserves prior output"

if bash Scripts/generate_symbol_map.sh "$task_build_dir/Other.dylib" "$task_output" \
    --arch arm64 --dsym "$task_binary.dSYM"; then
    echo "FAIL: accepted mismatched dSYM" >&2
    exit 1
fi
cmp "$task_output" "$task_build_dir/stripped.json"
echo "PASS: mismatched UUID is rejected without replacing the map"
bash Scripts/generate_symbol_map.sh "$task_build_dir/Other.dylib" "$task_build_dir/x86_64.json" --arch x86_64
echo "PASS: explicit architecture selects the correct Mach-O slice"
