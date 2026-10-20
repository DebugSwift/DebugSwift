#!/usr/bin/env python3
"""Build a UUID-checked, link-addressed symbol map using the Xcode toolchain."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import uuid


def tool(name, *arguments, input_text=None):
    result = subprocess.run(
        ["xcrun", name, *map(str, arguments)], input=input_text,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
    )
    return result.stdout


def image_ids(path):
    result = {}
    for identity, arch in re.findall(r"UUID: ([0-9A-Fa-f-]+) \(([^)]+)\)", tool("dwarfdump", "--uuid", path)):
        result[arch] = str(uuid.UUID(identity)).upper()
    if not result:
        raise ValueError(f"No Mach-O image UUID in {path}")
    return result


def dwarf_file(path):
    if path.is_dir():
        candidates = list((path / "Contents/Resources/DWARF").iterdir())
        if len(candidates) != 1 or not candidates[0].is_file():
            raise ValueError("Pass the specific DWARF file when a dSYM has multiple images")
        return candidates[0]
    return path


def generate(binary, arch, dsym):
    identities = image_ids(binary)
    if arch is None:
        if len(identities) != 1:
            raise ValueError("Universal binary: specify --arch (" + ", ".join(identities) + ")")
        arch = next(iter(identities))
    if arch not in identities:
        raise ValueError(f"Architecture {arch} is absent from {binary}")
    symbols_image = dwarf_file(dsym) if dsym else binary
    if image_ids(symbols_image).get(arch) != identities[arch]:
        raise ValueError("dSYM UUID/architecture does not match the linked binary")

    commands = tool("otool", "-arch", arch, "-l", binary)
    segment = re.search(r"segname __TEXT\s+vmaddr (0x[0-9a-fA-F]+)\s+vmsize (0x[0-9a-fA-F]+)", commands)
    if not segment:
        raise ValueError("Missing __TEXT segment")
    base, size = (int(value, 16) for value in segment.groups())
    addresses = {}
    for line in tool("nm", "-arch", arch, "-n", symbols_image).splitlines():
        match = re.match(r"^([0-9a-fA-F]+)\s+[tT]\s+(.+)$", line)
        if not match:
            continue
        address, name = int(match[1], 16), match[2]
        if base <= address < base + size and not name.startswith(("__mh_", "ltmp")):
            addresses.setdefault(address, name)
    if not addresses:
        raise ValueError("No code symbols: use an unstripped binary or its matching --dsym")
    ordered = sorted(addresses)
    # Batch stdin avoids ARG_MAX and does not launch a process per function.
    names = tool("swift-demangle", "--compact", input_text="\n".join(addresses[a] for a in ordered) + "\n").splitlines()
    locations = tool(
        "atos", "-arch", arch, "-o", symbols_image, "-l", hex(base), "-f", "/dev/stdin",
        input_text="\n".join(hex(a) for a in ordered) + "\n",
    ).splitlines()
    if len(names) != len(ordered) or len(locations) != len(ordered):
        raise ValueError("Symbolication tool returned an unexpected number of results")
    entries = []
    for address, name, location in zip(ordered, names, locations):
        source = re.search(r"\(([^()]+):(\d+)\)$", location)
        # Mach-O's leading underscore is not part of a C function's source name.
        if name == addresses[address] and name.startswith("_"):
            name = name[1:]
        entries.append({
            "address": address, "name": name,
            "file": source[1] if source else "", "line": int(source[2]) if source else 0,
        })
    return {"imageUUID": identities[arch], "loadAddress": base, "symbols": entries}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path, help="Linked Mach-O image (use the debug dylib if enabled)")
    parser.add_argument("output", type=Path, help="Output symbol_map.json resource")
    parser.add_argument("--arch", help="Required for universal binaries, e.g. arm64 or x86_64")
    parser.add_argument("--dsym", type=Path, help="Matching dSYM bundle or specific DWARF file")
    args = parser.parse_args()
    try:
        if args.output.resolve() == args.binary.resolve():
            parser.error("Output must not overwrite the binary")
        if args.dsym and args.output.resolve() == dwarf_file(args.dsym).resolve():
            parser.error("Output must not overwrite DWARF symbols")
        result = generate(args.binary, args.arch, args.dsym)
        # Write only after all tools and identity checks succeed; keep a previous
        # usable map intact on failure. The temporary file is ours alone.
        temporary = args.output.with_name(args.output.name + "." + uuid.uuid4().hex + ".tmp")
        try:
            with temporary.open("x", encoding="utf-8") as stream:
                json.dump(result, stream, ensure_ascii=False, separators=(",", ":"))
                stream.write("\n")
            os.replace(temporary, args.output)
        finally:
            if temporary.exists():
                temporary.unlink()
        print(f"Generated {args.output}: {result['imageUUID']}, {len(result['symbols'])} symbols")
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stderr, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
