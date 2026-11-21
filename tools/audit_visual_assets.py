"""Audit the *entire* image repository and produce a transparent QA inventory.

Usage (from project root):
    python3 -m pip install Pillow
    python3 tools/audit_visual_assets.py

The program checks file integrity, metadata, dimensions, duplicate images and
mapping provenance. It DOES NOT pretend automated checks can verify biomechanics.
Contact sheets and a per-exercise CSV permit human review of execution/anatomy.
"""
from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, UnidentifiedImageError

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "images"
OUTPUT = ROOT / "build" / "image-audit"
PROFILES = ("masculine", "feminine", "neutral")
KINDS = ("exercises", "muscles")
CATALOG = (ROOT / "lib" / "data" / "mock_data.dart").read_text(encoding="utf-8")
REGISTRY = (ROOT / "lib" / "services" / "illustration_assets.dart").read_text(encoding="utf-8")

ROW = re.compile(
    r"_exercise\('(?P<id>[^']+)',\s*'(?P<name>[^']+)',\s*"
    r"'(?P<english>[^']+)',\s*MuscleGroup\.(?P<group>\w+),\s*"
    r"EquipmentType\.(?P<equipment>\w+)(?P<remaining>[^\n]*)"
)
REVIEW_BLOCK = REGISTRY.split("executionArtworkUnderReview = {", 1)[1].split("};", 1)[0]
REVIEW = set(re.findall(r"'([^']+)'", REVIEW_BLOCK))

OUTPUT.mkdir(parents=True, exist_ok=True)
catalog = []
for matched in ROW.finditer(CATALOG):
    data = matched.groupdict()
    explicit = re.search(r"visualAssetId:\s*'([^']+)'", data["remaining"])
    catalog.append(
        dict(id=data["id"], name=data["name"], group=data["group"],
             equipment=data["equipment"], explicit_stem=explicit.group(1) if explicit else "")
    )
assert len(catalog) == 124 and len({e["id"] for e in catalog}) == 124, (
    "Catalog IDs changed: inspect this check before releasing new art"
)

problems = []
warnings = []
dimensions = Counter()
all_hashes = defaultdict(list)
metadata = {}
for path in sorted(ASSETS.rglob("*.webp")):
    relative = str(path.relative_to(ROOT))
    try:
        with Image.open(path) as photo:
            if photo.format != "WEBP":
                raise ValueError("wrong file encoding")
            width, height = photo.size
            photo.verify()
        if width < 160 or height < 120 or width / height < 0.45 or width / height > 3.5:
            warnings.append(f"UNUSUAL_DIMENSIONS: {relative} ({width}x{height})")
        dimensions[(width, height)] += 1
        metadata[relative] = {"width": width, "height": height, "bytes": path.stat().st_size}
        all_hashes[hashlib.sha256(path.read_bytes()).hexdigest()].append(relative)
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        problems.append(f"CORRUPT_IMAGE: {relative}: {exc}")

for profile in PROFILES:
    for kind in KINDS:
        folder = ASSETS / kind / profile
        items = sorted(folder.glob("*.webp"))
        expected = 33 if kind == "exercises" else 32
        if len(items) != expected:
            problems.append(
                f"UNEXPECTED_BASE_SET: {kind}/{profile} count={len(items)} expected={expected}")
        for item in items:
            if item.stem == "abs_forearm_plank" and kind == "exercises":
                continue  # Dedicated execution uses existing abs_plank anatomy.
            peer = ASSETS / ("muscles" if kind == "exercises" else "exercises") / profile / item.name
            if not peer.is_file():
                problems.append(f"MISSING_PAIR: {item.relative_to(ROOT)}")
    for group in ("chest", "back", "shoulders", "biceps", "triceps", "legs", "abs"):
        if not (ASSETS / "groups" / profile / (group + ".webp")).is_file():
            problems.append(f"MISSING_GROUP: {profile}/{group}")
    for kind in ("cardio", "cardio_activation"):
        for name in ("outdoor_run", "treadmill", "walk", "cycling",
                     "stationary_bike", "elliptical", "stair_climber",
                     "rowing", "jump_rope"):
            if not (ASSETS / kind / profile / (name + ".webp")).is_file():
                problems.append(f"MISSING_CARDIO: {kind}/{profile}/{name}")

rows = []
for e in catalog:
    state = ("dedicated_new_execution_art" if e["id"] == "plank"
             else "execution_mismatch_confirmed" if e["id"] in REVIEW
             else "explicit_asset_not_biomechanically_verified" if e["explicit_stem"]
             else "shared_family_art_pending_validation")
    for profile in PROFILES:
        stem = e["explicit_stem"]
        for kind in KINDS:
            if e["id"] == "plank" and kind == "exercises":
                stem = "abs_forearm_plank"
            elif e["id"] == "plank" and kind == "muscles":
                stem = "abs_plank"
            if stem:
                target = ASSETS / kind / profile / (stem + ".webp")
                if not target.exists():
                    problems.append(f"MISSING_EXPLICIT: {e['id']} {kind}/{profile}/{stem}")
            else:
                target = None
            rows.append({
                "exercise_id": e["id"], "exercise_name": e["name"],
                "muscle_group": e["group"], "equipment": e["equipment"],
                "profile": profile, "view": kind,
                "explicit_stem": stem or "(resolved by Flutter fallback)",
                "status": state,
                "asset": str(target.relative_to(ROOT)) if target else "(Dart fallback)",
            })

# Same bytes across different activity types is a clear reason for manual review.
duplicates = [locations for locations in all_hashes.values() if len(locations) > 1]
for paths in duplicates:
    warnings.append("DUPLICATE_BYTES: " + ", ".join(paths))

def sheet(profile: str, kind: str) -> None:
    paths = sorted((ASSETS / kind / profile).glob("*.webp"))
    w, h, gap, columns = 180, 176, 12, 6
    lines = (len(paths) + columns - 1) // columns
    board = Image.new("RGB", (columns * (w + gap) + gap, lines * (h + gap) + gap), "#08131c")
    draw = ImageDraw.Draw(board)
    for index, file in enumerate(paths):
        x = gap + index % columns * (w + gap)
        y = gap + index // columns * (h + gap)
        draw.rounded_rectangle((x, y, x + w, y + h), radius=10, fill="#13222f")
        try:
            with Image.open(file) as original:
                preview = original.convert("RGB")
                preview.thumbnail((w - 12, h - 34), Image.Resampling.LANCZOS)
                x0 = x + (w - preview.width) // 2
                y0 = y + (h - 30 - preview.height) // 2
                board.paste(preview, (x0, y0))
        except (OSError, UnidentifiedImageError):
            pass
        draw.text((x + 9, y + h - 22), file.stem[:24], fill="#e2f4f7")
    board.save(OUTPUT / f"contact-sheet-{kind}-{profile}.jpg", quality=88, optimize=True)

for profile in PROFILES:
    for kind in KINDS:
        sheet(profile, kind)

with (OUTPUT / "exercise-image-mapping.csv").open("w", newline="", encoding="utf-8") as output_file:
    writer = csv.DictWriter(output_file, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)

report = {
    "catalog_exercises": len(catalog),
    "profiles": list(PROFILES),
    "base_execution_files": {p: len(list((ASSETS / "exercises" / p).glob("*.webp"))) for p in PROFILES},
    "base_muscle_files": {p: len(list((ASSETS / "muscles" / p).glob("*.webp"))) for p in PROFILES},
    "catalog_profile_view_links": len(rows),
    "manual_review_exercises": sorted(REVIEW),
    "total_webp_files": len(metadata),
    "dimensions": {f"{w}x{h}": count for (w, h), count in dimensions.items()},
    "duplicate_binary_groups": duplicates,
    "errors": problems,
    "warnings": warnings,
    "semantics_verified_automatically": False,
    "next_step": "Review all six contact sheets and replace mismatched base illustrations before declaring the art ready.",
}
(OUTPUT / "audit-summary.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({
    "exercise_count": len(catalog), "webp_assets": len(metadata),
    "profile_view_links": len(rows),
    "under_review": len(REVIEW), "warnings": len(warnings),
    "errors": len(problems),
}, ensure_ascii=False))
for message in problems:
    print("ERROR:", message)
for message in warnings[:25]:
    print("WARN:", message)
if problems:
    raise SystemExit(1)
