#!/usr/bin/env python3
"""Find and quarantine unused art/sound assets in this Godot project.

Usage:
    python3 tools/find_unused_assets.py             scan + move + write manifest
    python3 tools/find_unused_assets.py --dry-run   scan + print, no moves
    python3 tools/find_unused_assets.py restore     move everything back from _unused_assets/

Scans .gd, .tscn, .tres, .gdshader, and project.godot for both literal
res:// paths and uid:// references (resolved via *.import sidecars).
Any image/audio file on disk that nothing references is moved into
_unused_assets/<original-path>/ alongside its .import sidecar, with a
.gdignore so Godot leaves it alone.
"""
import os
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
QUARANTINE = PROJECT_ROOT / "_unused_assets"

ASSET_EXT = {".png", ".jpg", ".jpeg", ".svg", ".wav", ".mp3", ".ogg", ".m4a"}
SOURCE_EXT = {".gd", ".tscn", ".tres", ".gdshader"}
SOURCE_EXTRA_BASENAMES = {"project.godot"}
EXCLUDE_DIRS = {".git", ".godot", "addons", "_unused_assets"}

ASSET_EXTS_PATTERN = "|".join(e.lstrip(".") for e in sorted(ASSET_EXT))
PATH_RE = re.compile(
    r'["\'](res://[^"\'<>\n]+?\.(?:' + ASSET_EXTS_PATTERN + r'))["\']',
    re.IGNORECASE,
)
UID_RE = re.compile(r'uid://[a-z0-9]+', re.IGNORECASE)
IMPORT_UID_RE = re.compile(r'^uid="(uid://[a-z0-9]+)"', re.MULTILINE | re.IGNORECASE)


def to_res(path: Path) -> str:
    return "res://" + path.relative_to(PROJECT_ROOT).as_posix()


def from_res(res_path: str) -> Path:
    return PROJECT_ROOT / res_path[len("res://"):]


def walk_project(extensions=None, basenames=None):
    for dirpath, dirnames, filenames in os.walk(PROJECT_ROOT):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
        for fname in filenames:
            fpath = Path(dirpath) / fname
            if extensions and fpath.suffix.lower() in extensions:
                yield fpath
            elif basenames and fname in basenames:
                yield fpath


def collect_assets():
    return {to_res(p) for p in walk_project(extensions=ASSET_EXT)}


def collect_uid_map():
    """Parse every *.import sidecar; return {uid: res:// path of source asset}."""
    uid_map = {}
    for dirpath, dirnames, filenames in os.walk(PROJECT_ROOT):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
        for fname in filenames:
            if not fname.endswith(".import"):
                continue
            fpath = Path(dirpath) / fname
            try:
                text = fpath.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            m = IMPORT_UID_RE.search(text)
            if not m:
                continue
            uid = m.group(1).lower()
            source = fpath.with_name(fname[: -len(".import")])
            if source.suffix.lower() in ASSET_EXT and source.exists():
                uid_map[uid] = to_res(source)
    return uid_map


def collect_references(uid_map):
    referenced = set()
    unresolved_uids = set()
    for fpath in walk_project(extensions=SOURCE_EXT, basenames=SOURCE_EXTRA_BASENAMES):
        try:
            text = fpath.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for m in PATH_RE.finditer(text):
            referenced.add(m.group(1))
        for m in UID_RE.finditer(text):
            uid = m.group(0).lower()
            if uid in uid_map:
                referenced.add(uid_map[uid])
            else:
                unresolved_uids.add(uid)
    return referenced, unresolved_uids


def format_size(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TB"


def quarantine_files(unused_paths, sizes):
    QUARANTINE.mkdir(parents=True, exist_ok=True)
    (QUARANTINE / ".gdignore").touch()

    moved_log_path = QUARANTINE / "MOVED.log"
    moved_lines = []
    moved_count = 0
    bytes_moved = 0

    for res_path in sorted(unused_paths):
        src = from_res(res_path)
        if not src.exists():
            continue
        rel = src.relative_to(PROJECT_ROOT)
        dst = QUARANTINE / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
        moved_lines.append(f"{rel.as_posix()}\t{QUARANTINE.name}/{rel.as_posix()}")
        moved_count += 1
        bytes_moved += sizes.get(res_path, 0)

        import_src = src.with_name(src.name + ".import")
        if import_src.exists():
            import_rel = rel.with_name(rel.name + ".import")
            import_dst = QUARANTINE / import_rel
            shutil.move(str(import_src), str(import_dst))
            moved_lines.append(
                f"{import_rel.as_posix()}\t{QUARANTINE.name}/{import_rel.as_posix()}"
            )

    log_mode = "a" if moved_log_path.exists() else "w"
    with open(moved_log_path, log_mode, encoding="utf-8") as f:
        f.write("\n".join(moved_lines) + "\n")

    return moved_count, bytes_moved


def write_manifest(unused_paths, sizes, manifest_path):
    groups = defaultdict(list)
    for res_path in sorted(unused_paths):
        parts = res_path[len("res://"):].split("/", 2)
        key = f"{parts[0]}/{parts[1]}" if len(parts) >= 2 else parts[0]
        groups[key].append(res_path)

    total_count = len(unused_paths)
    total_bytes = sum(sizes.get(p, 0) for p in unused_paths)

    lines = [
        "# Unused Assets Manifest",
        "",
        f"**Total files moved:** {total_count}",
        f"**Total size:** {format_size(total_bytes)}",
        "",
        "Files were moved to this directory preserving their original paths.",
        "",
        "Restore with: `python3 tools/find_unused_assets.py restore`",
        "",
        "## Summary by directory",
        "",
        "| Directory | Count | Size |",
        "|-----------|-------|------|",
    ]
    for key in sorted(groups.keys()):
        files = groups[key]
        size = sum(sizes.get(p, 0) for p in files)
        lines.append(f"| `{key}/` | {len(files)} | {format_size(size)} |")

    lines.append("")
    lines.append("## Full file list")
    lines.append("")

    for key in sorted(groups.keys()):
        lines.append(f"### {key}/")
        lines.append("")
        for p in sorted(groups[key]):
            lines.append(f"- `{p}` ({format_size(sizes.get(p, 0))})")
        lines.append("")

    manifest_path.write_text("\n".join(lines), encoding="utf-8")


def restore_files():
    moved_log_path = QUARANTINE / "MOVED.log"
    if not moved_log_path.exists():
        print(f"No MOVED.log found at {moved_log_path}. Nothing to restore.")
        return

    restored = 0
    missing = 0
    for line in moved_log_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        from_rel, to_rel = line.split("\t", 1)
        src = PROJECT_ROOT / to_rel
        dst = PROJECT_ROOT / from_rel
        if not src.exists():
            missing += 1
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
        restored += 1

    print(f"Restored {restored} files.")
    if missing:
        print(f"  ({missing} entries in MOVED.log no longer present in quarantine — already restored?)")


def main():
    args = sys.argv[1:]
    mode = "move"
    if args:
        if args[0] == "restore":
            mode = "restore"
        elif args[0] == "--dry-run":
            mode = "dry"
        elif args[0] in ("-h", "--help"):
            print(__doc__)
            return
        else:
            print(f"Unknown argument: {args[0]}")
            print(__doc__)
            sys.exit(1)

    if mode == "restore":
        restore_files()
        return

    print("Scanning project for assets and references...")
    assets = collect_assets()
    uid_map = collect_uid_map()
    referenced, unresolved = collect_references(uid_map)
    unused = sorted(assets - referenced)

    sizes = {}
    for p in unused:
        f = from_res(p)
        if f.exists():
            sizes[p] = f.stat().st_size

    used_count = len(assets) - len(unused)
    print(f"  Assets on disk:    {len(assets)}")
    print(f"  Referenced:        {used_count}")
    print(f"  Unused:            {len(unused)}")
    if unresolved:
        print(f"  Unresolved UIDs:   {len(unresolved)} (likely scripts/scenes, not assets — safe)")

    groups = defaultdict(list)
    for p in unused:
        parts = p[len("res://"):].split("/", 2)
        key = f"{parts[0]}/{parts[1]}" if len(parts) >= 2 else parts[0]
        groups[key].append(p)

    if mode == "dry":
        for key in sorted(groups.keys()):
            count = len(groups[key])
            size = sum(sizes.get(p, 0) for p in groups[key])
            print(f"\n{key}/ ({count} files, {format_size(size)})")
            for p in groups[key][:8]:
                print(f"  {p}")
            if count > 8:
                print(f"  ... and {count - 8} more")
        return

    if not unused:
        print("\nNo unused assets found.")
        return

    print(f"\nMoving {len(unused)} files to _unused_assets/ ...")
    moved_count, bytes_moved = quarantine_files(unused, sizes)

    manifest_path = QUARANTINE / "MANIFEST.md"
    write_manifest(unused, sizes, manifest_path)

    print(f"\nDone.")
    print(f"  Moved:    {moved_count} files")
    print(f"  Size:     {format_size(bytes_moved)}")
    print(f"  Manifest: _unused_assets/MANIFEST.md")
    print(f"  Restore:  python3 tools/find_unused_assets.py restore")

    print(f"\nTop directories:")
    for key, files in sorted(groups.items(), key=lambda kv: -len(kv[1]))[:10]:
        size = sum(sizes.get(p, 0) for p in files)
        print(f"  {len(files):4d} files ({format_size(size):>9s})  {key}/")


if __name__ == "__main__":
    main()
