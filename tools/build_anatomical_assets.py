"""Rebuild GymRecords independent anatomical activation illustrations.

Source is an original six-panel anatomy atlas generated for GymRecords.
The resulting activation images are *not* recolored execution photos:
front/rear anatomical models are separate from exercise photographs.
This art is schematic, not a medical description of isolated muscle activity.
Requires: pillow, numpy, opencv-python. Use `python tools/build_anatomical_assets.py`.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
import cv2
import sys

PROJECT = Path(__file__).resolve().parents[1]
ATLAS = PROJECT / 'tools' / 'anatomy_atlas_source.png'
OUTPUT = PROJECT / 'assets/images'
STYLES = {'masculine': 0, 'feminine': 1, 'neutral': 2}

# Region coordinates are relative to each atlas cell, front/rear anatomical poses.
REGIONS = {
    'chest': [('front', .43,.235,.14,.065), ('front', .57,.235,.14,.065)],
    'shoulders': [('front',.31,.192,.065,.068),('front',.69,.192,.065,.068),('back',.31,.196,.072,.069),('back',.69,.196,.072,.069)],
    'biceps': [('front',.285,.313,.047,.085),('front',.715,.313,.047,.085)],
    'triceps': [('back',.29,.324,.055,.092),('back',.71,.324,.055,.092)],
    'forearms': [('front',.236,.426,.047,.078),('front',.764,.426,.047,.078)],
    'lats': [('back',.395,.312,.11,.108),('back',.605,.312,.11,.108)],
    'traps': [('back',.5,.215,.14,.070)],
    'lumbar': [('back',.5,.430,.13,.074)],
    'abs': [('front',.5,.361,.118,.105)],
    'obliques': [('front',.38,.366,.057,.104),('front',.62,.366,.057,.104)],
    'hip_flexors': [('front',.465,.507,.045,.070),('front',.535,.507,.045,.070)],
    'quads': [('front',.412,.635,.095,.142),('front',.59,.635,.095,.142)],
    'adductors': [('front',.470,.634,.042,.126),('front',.530,.634,.042,.126)],
    'hamstrings': [('back',.412,.676,.087,.123),('back',.587,.676,.087,.123)],
    'glutes': [('back',.415,.555,.094,.070),('back',.585,.555,.094,.070)],
    'calves': [('front',.412,.814,.055,.101),('front',.595,.814,.055,.101),('back',.41,.813,.062,.105),('back',.585,.813,.062,.105)],
}

# First group = primary; second = supporting. More anatomical than existing
# color-overlay-on-execution images. These are schematic approximations.
EXERCISE_FOCUS = {
    'abs_0': (['abs'], []),
    'abs_machine': (['abs','obliques'], ['hip_flexors']),
    'abs_cable': (['abs'], ['obliques','hip_flexors']),
    'abs_crunch': (['abs'], ['obliques']),
    'abs_reverse': (['abs','hip_flexors'], ['obliques']),
    'abs_hanging': (['abs','hip_flexors'], ['forearms']),
    'abs_plank': (['abs','obliques'], ['shoulders']),
    'chest_0': (['chest'], ['triceps','shoulders']),
    'chest_1': (['chest'], ['shoulders']),
    'chest_2': (['chest','shoulders'], ['triceps']),
    'chest_3': (['chest'], ['shoulders','abs']),
    'back_0': (['lats'], ['biceps']),
    'back_1': (['lats'], ['biceps','traps']),
    'back_2': (['lats','biceps'], ['traps']),
    'back_3': (['lats','traps'], ['biceps']),
    'back_4': (['lats','traps'], ['lumbar']),
    'shoulders_0': (['shoulders'], ['triceps']),
    'shoulders_1': (['shoulders'], []),
    'shoulders_2': (['shoulders','traps'], []),
    'biceps_0': (['biceps'], ['forearms']),
    'biceps_1': (['biceps','forearms'], []),
    'triceps_0': (['triceps'], ['shoulders']),
    'triceps_1': (['triceps'], ['forearms']),
    'triceps_2': (['triceps'], ['chest']),
    'leg_press_45': (['quads'], ['glutes','hamstrings']),
    'hack_squat': (['quads'], ['glutes']),
    'leg_extension': (['quads'], []),
    'lying_leg_curl': (['hamstrings'], ['calves']),
    'seated_leg_curl': (['hamstrings'], ['calves','glutes']),
    'hip_abductor': (['glutes'], []),
    'hip_adductor': (['adductors'], []),
    'seated_calf': (['calves'], []),
}
CARDIO_FOCUS = {
    'outdoor_run': (['quads','hamstrings','calves'], ['glutes','abs']),
    'treadmill': (['quads','calves'], ['hamstrings','glutes','abs']),
    'walk': (['calves','quads'], ['glutes','hamstrings']),
    'cycling': (['quads','glutes'], ['hamstrings','calves','abs']),
    'stationary_bike': (['quads','glutes'], ['hamstrings','calves']),
    'elliptical': (['quads','glutes','calves'], ['shoulders','abs']),
    'stair_climber': (['quads','glutes'], ['calves','hamstrings']),
    'rowing': (['lats','quads'], ['biceps','abs','hamstrings']),
    'jump_rope': (['calves','quads'], ['shoulders','forearms','abs']),
}


def cell(img: Image.Image, col: int, row: int):
    w,h=img.size
    x0=round(col*w/3);x1=round((col+1)*w/3)
    y0=0 if row == 0 else round(h*0.452)
    y1=round(h*0.435) if row == 0 else round(h*0.928)
    # 8px inset avoids 1px grid seams on the art source.
    return np.asarray(img.crop((x0+3,y0+3,x1-3,y1-3)).convert('RGB')).copy()


def make_mask(img, groups, side):
    h,w=img.shape[:2]
    mask=np.zeros((h,w),np.float32)
    for group in groups:
        for facet,cx,cy,rx,ry in REGIONS[group]:
            if facet!=side:continue
            # Gaussian-edged ellipses avoid hard clipping through muscle fibers.
            candidate=np.zeros((h,w),np.uint8)
            cv2.ellipse(candidate,(round(cx*w),round(cy*h)),(round(rx*w),round(ry*h)),0,0,360,255,-1,cv2.LINE_AA)
            candidate=cv2.GaussianBlur(candidate,(0,0),max(1,round(w*.008)))
            mask=np.maximum(mask,candidate.astype(np.float32)/255)
    r,g,b=img.astype(np.float32).transpose(2,0,1)
    # Keep blue background untouched; isolate neutral gray anatomical silhouette.
    chroma=np.clip((r/(g+1e-3)-.76)/.16,0,1)
    light=np.clip((r-75)/55,0,1)
    silhouette=cv2.GaussianBlur((chroma*light).astype(np.float32),(0,0),1.1)
    return np.clip(mask*silhouette,0,1)


def highlight(img, primary, secondary, side):
    a=img.astype(np.float32)
    for groups,tint,opacity in ((secondary,np.array([34,133,224.],np.float32),.59),
                                (primary,np.array([0,195,255.],np.float32),.82)):
        if not groups: continue
        mask=make_mask(img,groups,side)*opacity
        # Preserve original muscle ridges and directional light.
        luminance=(a[:,:,0]*.31+a[:,:,1]*.55+a[:,:,2]*.14)
        shine=np.clip(.68+luminance/420, .74,1.18)
        target=tint[None,None,:]*shine[:,:,None]
        a=a*(1-mask[:,:,None])+target*mask[:,:,None]
    return Image.fromarray(np.clip(a,0,255).astype('uint8'),'RGB')


def render(front,back,primary,secondary):
    # Full figures, two camera angles; no embedded borders, captions, or filters.
    # This is a separate view rather than a recolored execution photo.
    out=Image.new('RGB',(840,520),(65,103,144))
    for src,side,x in ((front,'front',40),(back,'back',440)):
        drawing=highlight(src,primary,secondary,side)
        drawing=drawing.resize((360,520),Image.Resampling.LANCZOS)
        out.paste(drawing,(x,0))
    return out


def run():
    atlas=Image.open(ATLAS).convert('RGB')
    for style,col in STYLES.items():
        front=cell(atlas,col,0);back=cell(atlas,col,1)
        exdir=OUTPUT/'muscles'/style
        for key,(primary,secondary) in EXERCISE_FOCUS.items():
            target=exdir/f'{key}.webp'; target.parent.mkdir(parents=True,exist_ok=True)
            render(front,back,primary,secondary).save(target,'WEBP',quality=93,method=6)
        cardiodir=OUTPUT/'cardio_activation'/style
        for key,(primary,secondary) in CARDIO_FOCUS.items():
            target=cardiodir/f'{key}.webp';target.parent.mkdir(parents=True,exist_ok=True)
            render(front,back,primary,secondary).save(target,'WEBP',quality=94,method=6)
    print('Generated',len(STYLES)*(len(EXERCISE_FOCUS)+len(CARDIO_FOCUS)),'anatomical images')

if __name__=='__main__':run()
