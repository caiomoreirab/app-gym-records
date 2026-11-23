"""GymRecords visual validation: use from project root with `python tools/verify_visual_assets.py`."""
from pathlib import Path
from collections import defaultdict
from hashlib import sha256
import re,sys
from xml.etree import ElementTree
root=Path(__file__).resolve().parent.parent
assets=root/'assets'/'images'
catalog=(root/'lib'/'data'/'mock_data.dart').read_text(encoding='utf-8')
ids=re.findall(r"_exercise\('([^']+)'",catalog)
refs=re.findall(r"_exercise\('([^']+)'.*?visualAssetId: '([^']+)'",catalog)
profiles=('masculine','feminine','neutral')
problems=[]
if len(ids)!=124 or len(set(ids))!=len(ids):problems.append(f'Unexpected catalog count/duplicate: {len(ids)}, unique {len(set(ids))}')
for profile in profiles:
    for group in ('chest','back','legs','shoulders','biceps','triceps','abs'):
        path=assets/'groups'/profile/(group+'.webp')
        if not path.is_file():problems.append(f'Missing group {path}')
    for exercise,stem in refs:
        for kind in ('exercises','muscles'):
            path=assets/kind/profile/(stem+'.webp')
            if not path.is_file():problems.append(f'Missing {kind} {exercise}: {path}')
    group=assets/'cardio'/'groups'/(profile+'.webp')
    if not group.is_file():problems.append(f'Missing cardio group {profile}')
    for kind in ('outdoor_run','treadmill','walk','cycling','stationary_bike','elliptical','stair_climber','rowing','jump_rope'):
        for directory in ('cardio','cardio_activation'):
            path=assets/directory/profile/(kind+'.webp')
            if not path.is_file():problems.append(f'Missing {directory} {profile} {kind}')

# Every curated movement is available for each on-device visual preference.
# Missing or malformed SVGs fail CI instead of showing a broken icon.
curated=('barbell_bench_press','barbell_squat','deadlift','dumbbell_bench_press','barbell_curl','dumbbell_lateral_raise','pull_up')
vector_dir=root/'assets'/'illustrations'/'movements'
for exercise in curated:
    if exercise not in ids:
        problems.append(f'Curated movement missing from catalog: {exercise}')
    for profile in profiles:
        path=vector_dir/profile/(exercise+'.svg')
        if not path.is_file():
            problems.append(f'Missing curated SVG: {path}')
            continue
        try:
            tree=ElementTree.parse(path)
            svg=tree.getroot()
            if not svg.tag.endswith('svg') or 'viewBox' not in svg.attrib:
                problems.append(f'Invalid SVG viewport: {path}')
            if path.stat().st_size < 300:
                problems.append(f'Empty artwork: {path}')
        except ElementTree.ParseError as error:
            problems.append(f'Malformed SVG {path}: {error}')

# Legacy cover crops exercise bodies; the adaptive exercise pipeline must
# preserve the full frame independently of source aspect ratio.
adaptive=(root/'lib'/'widgets'/'adaptive_illustration.dart').read_text(
    encoding='utf-8')
if 'fit: BoxFit.contain' not in adaptive:
    problems.append('Exercise media must use BoxFit.contain')

# Verify source WebP dimensions, not only file presence. The UI uses
# BoxFit.contain for movement images: no stretching/cropping on small screens.
def webp_dimensions(path):
    raw = path.read_bytes()[:40]
    if len(raw) < 30 or raw[:4] != b'RIFF' or raw[8:12] != b'WEBP':
        raise ValueError('Invalid WebP header')
    kind = raw[12:16]
    if kind == b'VP8X':
        width = int.from_bytes(raw[24:27], 'little') + 1
        height = int.from_bytes(raw[27:30], 'little') + 1
    elif kind == b'VP8L' and raw[20] == 0x2f:
        bits = int.from_bytes(raw[21:25], 'little')
        width = (bits & 0x3fff) + 1
        height = ((bits >> 14) & 0x3fff) + 1
    elif kind == b'VP8 ' and raw[23:26] == b'\x9d\x01\x2a':
        width = int.from_bytes(raw[26:28], 'little') & 0x3fff
        height = int.from_bytes(raw[28:30], 'little') & 0x3fff
    else:
        raise ValueError(f'Unrecognized WebP format: {kind!r}')
    if width < 1 or height < 1:
        raise ValueError('Invalid image dimensions')
    return width, height

dimensions = []
extreme_ratios = []
for picture in assets.rglob('*.webp'):
    try:
        width, height = webp_dimensions(picture)
        dimensions.append((picture, width, height))
        if max(width, height) / min(width, height) > 3:
            extreme_ratios.append(f'{picture.relative_to(root)}: {width}x{height}')
    except ValueError as error:
        problems.append(f'{picture.relative_to(root)}: {error}')
print(f'WebP image sources checked: {len(dimensions)}')
if dimensions:
    print('WebP dimensions: minimum side', min(min(w,h) for _,w,h in dimensions),
          '| maximum side', max(max(w,h) for _,w,h in dimensions))
if extreme_ratios:
    print('Unusual image aspect ratios (review composition, no stretch):')
    for issue in extreme_ratios[:30]: print('-', issue)

print(f'Exercise catalog: {len(ids)} unique names: {len(set(ids))}')
print(f'Explicit exercise asset IDs: {len(refs)} (unique stems: {len(set(b for a,b in refs))})')
for profile in profiles:
    ec=list((assets/'exercises'/profile).glob('*.webp'))
    ms=list((assets/'muscles'/profile).glob('*.webp'))
    print(f'{profile}: {len(ec)} execution image files, {len(ms)} muscle image files')
    for kind,paths in [('execution',ec),('muscle',ms)]:
        hashes=defaultdict(list)
        for p in paths:hashes[sha256(p.read_bytes()).hexdigest()].append(p.stem)
        repeated=[names for names in hashes.values() if len(names)>1]
        if repeated:problems.append(f'{profile} {kind} identical files: {repeated}')
print(f'Cardio: 9 activities x {len(profiles)} profiles x 2 views')
print(f'Curated vectors: {len(curated)} distinct movements x 3 profiles ({len(curated)*3} SVG files).')
print('Important: dedicated illustrations still do not cover all 124 exercises; unmatched items use equipment-neutral art.')
if problems:
    print('\nFOUND ISSUES:')
    for issue in problems:print('- '+issue)
    sys.exit(1)
print('OK: no missing explicit paths or identical base files.')
