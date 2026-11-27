#!/usr/bin/env python3
"""Build the KPM .kpkg after the four generated Polish keymaps are added."""
from __future__ import annotations
import gzip
import hashlib
import json
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PKG = ROOT / "package"
KEYMAPS = PKG / "keymaps"
OUT = ROOT / "polish-keyboard_1.0.0_kindlehf.kpkg"
EXPECTED = {
    "en_GB-1236x1648-PL-clean-safe.keymap.gz": "en-GB",
    "en_GB-1648x1236-PL-clean-safe.keymap.gz": "en-GB",
    "en_US-1236x1648-PL-clean-safe.keymap.gz": "en-US",
    "en_US-1648x1236-PL-clean-safe.keymap.gz": "en-US",
}
REMOVED = {(4, 0), (8, 0), (9, 0), (10, 0), (104, 1), (108, 1), (109, 1), (110, 1)}
POLISH = {
    (1, 0): [("ą", "ą"), ("a", "a")],
    (2, 0): [("ć", "ć"), ("c", "c")],
    (3, 0): [("ę", "ę"), ("e", "e")],
    (5, 0): [("ń", "ń"), ("n", "n")],
    (6, 0): [("ó", "ó"), ("o", "o")],
    (7, 0): [("ś", "ś"), ("s", "s")],
    (11, 0): [("ł", "ł"), ("l", "l")],
    (12, 0): [("ż", "ż"), ("ź", "ź"), ("z", "z")],
    (101, 1): [("Ą", "Ą"), ("A", "A")],
    (102, 1): [("Ć", "Ć"), ("C", "C")],
    (103, 1): [("Ę", "Ę"), ("E", "E")],
    (105, 1): [("Ń", "Ń"), ("N", "N")],
    (106, 1): [("Ó", "Ó"), ("O", "O")],
    (107, 1): [("Ś", "Ś"), ("S", "S")],
    (111, 1): [("Ł", "Ł"), ("L", "L")],
    (112, 1): [("Ż", "Ż"), ("Ź", "Ź"), ("Z", "Z")],
}


def validate_keymap(path: Path, expected_lang: str) -> None:
    try:
        with gzip.open(path, "rt", encoding="utf-8") as stream:
            data = json.load(stream)
    except Exception as exc:
        raise RuntimeError(f"{path.name}: gzip/JSON invalid: {exc}") from exc
    if data.get("keyboard_language") != expected_lang:
        raise RuntimeError(
            f"{path.name}: keyboard_language={data.get('keyboard_language')!r}, expected {expected_lang!r}"
        )
    layouts = data.get("layouts")
    if not isinstance(layouts, list) or len(layouts) != 41:
        raise RuntimeError(f"{path.name}: expected exactly 41 layouts")
    present = {
        (x.get("diacritical"), x.get("modifier"))
        for x in layouts if x.get("type") == 8192
    }
    if present & REMOVED:
        raise RuntimeError(f"{path.name}: one or more Y/U/I/D popup definitions remain")
    for pid, mod in REMOVED:
        main_comment = "lowercase, three rows for alpha" if mod == 0 else "uppercase, three rows for alpha"
        main = [x for x in layouts if x.get("comment") == main_comment]
        if len(main) != 1:
            raise RuntimeError(f"{path.name}: could not locate {main_comment}")
        expected_label = {
            (9, 0): "y", (8, 0): "u", (4, 0): "i", (10, 0): "d",
            (109, 1): "Y", (108, 1): "U", (104, 1): "I", (110, 1): "D",
        }[(pid, mod)]
        keys = [k for k in main[0].get("keys", []) if k.get("label") == expected_label]
        if len(keys) != 1 or "hold" in keys[0]:
            raise RuntimeError(f"{path.name}: unwanted hold remains on {expected_label}")
    for key, pairs in POLISH.items():
        found = [x for x in layouts if x.get("type") == 8192 and x.get("diacritical") == key[0] and x.get("modifier") == key[1]]
        if len(found) != 1:
            raise RuntimeError(f"{path.name}: missing Polish popup {key}")
        actual = [(k.get("label"), k.get("value")) for k in found[0].get("keys", [])]
        if actual != pairs:
            raise RuntimeError(f"{path.name}: Polish popup {key} does not match expected contents")


def main() -> None:
    manifest = json.loads((PKG / "manifest.json").read_text(encoding="utf-8"))
    if manifest.get("manifest_version") != 2:
        raise RuntimeError("This build targets KPM package manifest version 2.")

    for filename, language in EXPECTED.items():
        path = KEYMAPS / filename
        if not path.is_file():
            raise FileNotFoundError(f"Missing generated keymap: {path}")
        validate_keymap(path, language)
        print(f"Validated: {filename}")

    if OUT.exists():
        raise FileExistsError(f"Refusing to overwrite existing package: {OUT}")

    # Write checksum list used by install.sh and activate.sh.
    rows = []
    for filename in EXPECTED:
        digest = hashlib.sha256((KEYMAPS / filename).read_bytes()).hexdigest()
        rows.append(f"{digest}  {filename}")
    sums_path = KEYMAPS / "SHA256SUMS"
    if sums_path.exists():
        old = sums_path.read_text(encoding="utf-8")
        if old != "\n".join(rows) + "\n":
            raise FileExistsError("Existing SHA256SUMS differs; refusing to overwrite it.")
    else:
        sums_path.write_text("\n".join(rows) + "\n", encoding="utf-8", newline="\n")

    members = []
    for path in sorted(PKG.rglob("*")):
        if not path.is_file():
            continue
        if path.name == "PUT_FOUR_GENERATED_KEYMAPS_HERE.txt":
            continue
        members.append(path)
    with tarfile.open(OUT, mode="w:gz", compresslevel=5) as archive:
        for path in members:
            archive.add(path, arcname=path.relative_to(PKG).as_posix(), recursive=False)
    with tarfile.open(OUT, mode="r:gz") as archive:
        names = set(archive.getnames())
        required = {"manifest.json", "install.sh", "launch.sh", "activate.sh", "uninstall.sh", "scriptlets/Polska klawiatura.sh", "keymaps/SHA256SUMS"}
        required |= {f"keymaps/{f}" for f in EXPECTED}
        missing = required - names
        if missing:
            OUT.unlink(missing_ok=True)
            raise RuntimeError(f"Package validation failed; missing: {sorted(missing)}")
        inner_manifest = json.load(archive.extractfile("manifest.json"))
        if inner_manifest != manifest:
            OUT.unlink(missing_ok=True)
            raise RuntimeError("Manifest changed unexpectedly in archive.")
    print(f"\nCreated KPM package: {OUT}")
    print(f"Size: {OUT.stat().st_size} bytes")

if __name__ == "__main__":
    main()
