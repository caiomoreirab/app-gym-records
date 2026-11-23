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
curated=('barbell_bench_press','barbell_squat','deadlift')
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
print('Curated vectors: 3 distinct movements x 3 profiles (9 SVG files).')
print('Important: dedicated illustrations still do not cover all 124 exercises; unmatched items use equipment-neutral art.')
if problems:
    print('\nFOUND ISSUES:')
    for issue in problems:print('- '+issue)
    sys.exit(1)
print('OK: no missing explicit paths or identical base files.')
