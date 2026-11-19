"""Offline QA for GymRecords visual catalog, without Flutter or external services.

Produces tools/visual_audit.csv and tools/visual_audit_summary.json.
Checks every catalog exercise and every profile, missing file paths, exact
binary duplicates, and the coverage ceiling imposed by shared execution art.
No claim of semantic correctness is inferred from existence alone.
"""
from pathlib import Path
import csv, re, json, hashlib
from collections import Counter, defaultdict

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT/'lib/data/mock_data.dart').read_text(encoding='utf-8')
REGISTRY = (ROOT/'lib/services/illustration_assets.dart').read_text(encoding='utf-8')
PROFILES = ['masculine','feminine','neutral']

# Map switch-case fallbacks from Dart, respecting grouped case statements.
segment = REGISTRY.split('static String? _executionOverride', 1)[1].split('static String _chestFallback',1)[0]
case_overrides = {}
pending = []
for line in segment.splitlines():
    case = re.search(r"case '([^']+)':", line)
    return_ = re.search(r"return '([^']+)';", line)
    if case: pending.append(case.group(1))
    if return_:
        for key in pending: case_overrides[key]=return_.group(1)
        pending=[]

entries=[]
for line in SOURCE.splitlines():
    if not re.search(r"\b_exercise\('",line):continue
    pat=r"_exercise\('([^']+)', '([^']+)', '([^']+)', MuscleGroup\.(\w+), EquipmentType\.(\w+)"
    m=re.search(pat,line)
    if not m:raise ValueError('Unhandled catalog line: '+line.strip())
    asset=re.search(r"visualAssetId: '([^']+)'",line)
    subgroup=re.search(r"subgroup: '([^']+)'",line)
    entries.append({'id':m.group(1),'name_pt':m.group(2),'group':m.group(4),'equipment':m.group(5),'explicit':asset.group(1) if asset else '', 'subgroup':subgroup.group(1) if subgroup else ''})
assert len(entries)==124, f'{len(entries)} catalog exercises, expected 124'


def stem(e):
    if e['explicit']:return e['explicit']
    if e['id'] in case_overrides:return case_overrides[e['id']]
    group=e['group'];eq=e['equipment'];sub=e['subgroup'].lower();ident=e['id']
    if group=='chest':return 'chest_3' if eq=='cable' else 'chest_0'
    if group=='back':return 'back_0' if eq=='cable' else ('back_1' if eq=='machine' else 'back_3')
    if group=='shoulders':return 'shoulders_2' if eq=='cable' else ('shoulders_0' if eq=='machine' else 'shoulders_1')
    if group=='biceps':return 'biceps_1' if eq=='cable' else 'biceps_0'
    if group=='triceps':return 'triceps_0' if eq=='cable' else ('triceps_1' if eq=='machine' else 'triceps_2')
    if group=='abs':
        if eq=='machine':return 'abs_machine'
        if eq=='cable':return 'abs_cable'
        for key,val in [('hanging','abs_hanging'),('captain','abs_hanging'),('plank','abs_plank'),('wheel','abs_plank'),('reverse','abs_reverse')]:
            if key in ident:return val
        return 'abs_crunch'
    if group=='legs':
        if 'posterior' in sub or 'isqui' in sub:return 'lying_leg_curl'
        if 'panturr' in sub:return 'seated_calf'
        if 'abdutor' in sub or 'glúteos' in sub:return 'hip_abductor'
        if 'adutor' in sub:return 'hip_adductor'
        if eq=='machine' and 'quadr' in sub:return 'leg_extension'
        if eq in ('barbell','dumbbell','smith','bodyweight'):return 'hack_squat'
        return 'leg_press_45'
    raise ValueError(group)

# No shadow photographic fallback in the strength anatomical view.
rows=[];missing=[]
for e in entries:
    e['stem']=stem(e)
    for profile in PROFILES:
        base=f'assets/images/exercises/{profile}/{e["stem"]}.webp'
        muscle=f'assets/images/muscles/{profile}/{e["stem"]}.webp'
        for path in (base,muscle):
            if not (ROOT/path).is_file():missing.append(path)
        rows.append({**e,'profile':profile,'execution_path':base,'muscle_path':muscle,
                     'execution_hash':hashlib.sha256((ROOT/base).read_bytes()).hexdigest()[:16] if (ROOT/base).exists() else '',
                     'muscle_hash':hashlib.sha256((ROOT/muscle).read_bytes()).hexdigest()[:16] if (ROOT/muscle).exists() else '',
                     'execution_source':'catalog_explicit' if e['explicit'] else 'reused_fallback'})

for profile in PROFILES:
    for name in ['outdoor_run','treadmill','walk','cycling','stationary_bike','elliptical','stair_climber','rowing','jump_rope']:
        for sub in ['cardio','cardio_activation']:
            path=ROOT/'assets/images'/sub/profile/f'{name}.webp'
            if not path.exists():missing.append(str(path))
    for group in ['chest','back','shoulders','biceps','triceps','legs','abs']:
        path=ROOT/'assets/images/groups'/profile/f'{group}.webp'
        if not path.exists():missing.append(str(path))
    path=ROOT/'assets/images/cardio/groups'/f'{profile}.webp'
    if not path.exists():missing.append(str(path))

if missing:
    raise FileNotFoundError('\n'.join(sorted(set(missing))))

out=ROOT/'tools/visual_audit.csv'
with out.open('w',encoding='utf-8-sig',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)

summary={
 'catalog_total':len(entries),
 'profiles':PROFILES,
 'execution_base_images_per_profile':len(list((ROOT/'assets/images/exercises/feminine').glob('*.webp'))),
 'muscle_base_images_per_profile':len(list((ROOT/'assets/images/muscles/feminine').glob('*.webp'))),
 'cardio_activities':9,
 'missing_paths':len(missing),
 'per_profile':{},
 'warning':'An asset path is not proof that the illustrated exercise is biomechanically correct; reused execution art requires manual review.'
}
for profile in PROFILES:
    records=[r for r in rows if r['profile']==profile]
    assetcounts=Counter(r['execution_path'] for r in records)
    hashes=Counter(r['execution_hash'] for r in records)
    summary['per_profile'][profile]={
        'unique_exercise_paths':len(assetcounts),
        'shared_execution_exercises':sum(1 for r in records if assetcounts[r['execution_path']]>1),
        'unique_execution_hashes':len(hashes),
        'dedicated_explicit_references':sum(1 for r in records if r['explicit']),
        'most_reused_execution':assetcounts.most_common(8),
    }
(ROOT/'tools/visual_audit_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
