#!/bin/bash
set -euo pipefail

# Usage: bash Scripts/generate_symbol_map.sh <Mach-O binary> <symbol_map.json>
#        [--arch arm64] [--dsym <matching .dSYM bundle or DWARF file>]
# Generate after linking, before stripping. Copy the JSON into the application's
# resources so Bundle.main can load it. With Xcode's debug dylib enabled, pass
# <App>.app/<App>.debug.dylib, NOT the small launcher executable.
# A universal binary requires --arch; each architecture has a different UUID.
task_script_dir=$(cd "$(dirname "$0")" && pwd)
exec /usr/bin/python3 "$task_script_dir/generate_symbol_map.py" "$@"
