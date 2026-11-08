"""Capturas Flutter -> pitch narrado Full HD. No modifica la app ni usa el backend."""
from __future__ import annotations
import asyncio
import json
import math
import re
import subprocess
import sys
import wave
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'build/presentation'
sys.path.insert(0, str(OUT / 'deps'))
import imageio_ffmpeg
import numpy as np
from PIL import Image, ImageDraw, ImageFont

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
SCENES = json.loads((Path(__file__).with_name('scenes.json')).read_text(encoding='utf-8'))
W, H, FPS = 1920, 1080, 24
NAVY, WHITE, MUTED = '#09172F', '#F8FAFF', '#B6C6DD'
GOLD, TEAL = '#F5C44E', '#00BFA6'
FONT_DIR = ROOT / 'assets/fonts'


def font(size, bold=False):
    return ImageFont.truetype(str(FONT_DIR / ('Poppins-Bold.ttf' if bold else 'Poppins-Regular.ttf')), size)


def wrap(text, f, width):
    lines = []
    for para in text.split('\n'):
        line = ''
        for word in para.split():
            test = (line + ' ' + word).strip()
            if f.getlength(test) > width and line:
                lines.append(line)
                line = word
            else:
                line = test
        lines.append(line)
    return lines


def text_block(draw, text, xy, width, size, color=WHITE, bold=False, spacing=1.24):
    x, y = xy
    f = font(size, bold)
    for line in wrap(text, f, width):
        draw.text((x, y), line, font=f, fill=color, stroke_width=0)
        y += int(size * spacing)
    return y


def paste_rounded(canvas, picture, xy, radius=22):
    mask = Image.new('L', picture.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, picture.width-1, picture.height-1), radius, fill=255)
    canvas.paste(picture, xy, mask)


def phone(canvas, page, x, y, height=790):
    shot = Image.open(OUT / f'captures/mobile-{page}.png').convert('RGB')
    sh = height - 28
    sw = round(sh * shot.width / shot.height)
    shot = shot.resize((sw, sh), Image.Resampling.LANCZOS)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((x-8, y-8, x+sw+36, y+height+8), 52, fill='#142842')
    d.rounded_rectangle((x, y, x+sw+28, y+height), 45, fill='#02070F', outline='#65758B', width=2)
    paste_rounded(canvas, shot, (x+14, y+14), 32)
    # Marco de dispositivo ilustrativo; el contenido es una captura real de Flutter.
    d.rounded_rectangle((x+sw/2-25, y+7, x+sw/2+53, y+17), 5, fill='#02070F')
    return sw+28


def browser(canvas, page, x, y, width=1160):
    shot = Image.open(OUT / f'captures/web-{page}.png').convert('RGB')
    # Encuadre editorial: mostrar el área útil de la ventana.
    shot = shot.crop((0, 0, shot.width, shot.height - 90))
    height = round(width * shot.height / shot.width)
    shot = shot.resize((width, height), Image.Resampling.LANCZOS)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((x-3, y-3, x+width+3, y+height+47), 21, fill='#42607C')
    d.rounded_rectangle((x, y, x+width, y+height+44), 18, fill='#F5F7FB')
    for i, c in enumerate(['#EE6C6A', '#EEC052', '#65BE9A']):
        d.ellipse((x+18+i*20, y+15, x+28+i*20, y+25), fill=c)
    d.rounded_rectangle((x+105, y+9, x+width-100, y+33), 9, fill='#E4EAF2')
    d.text((x+128, y+9), 'Nearby · Experiencia web', font=font(15), fill='#52627F')
    canvas.paste(shot, (x, y+44))


def background(index):
    yy, xx = np.mgrid[0:H, 0:W]
    glow = np.exp(-((xx-1500)**2/(950**2)+(yy-260)**2/(700**2)))
    arr = np.zeros((H,W,3), dtype=np.uint8)
    for i,(base,extra) in enumerate([(7,6),(19,27),(40,32)]):
        arr[:,:,i] = base + glow*extra
    im = Image.fromarray(arr)
    d = ImageDraw.Draw(im)
    for x in range(80,W,80):
        for y in range(80,H,80):
            if x>900:
                d.ellipse((x,y,x+2,y+2),fill='#203B53')
    d.line((96,116,W-96,116),fill='#263C55',width=1)
    mark = Image.open(ROOT/'docs/brand/isotipo.png').convert('RGBA')
    mark.thumbnail((44,44), Image.Resampling.LANCZOS)
    d.rounded_rectangle((96,40,154,98),15,fill='white')
    im.paste(mark,(103+(44-mark.width)//2,47+(44-mark.height)//2),mark)
    d.text((174,43),'Nearby',font=font(35,True),fill=WHITE)
    d.text((W-520,53),'SIEMPRE CERCA PARA AYUDAR',font=font(17),fill=MUTED)
    d.text((96,H-55),f'{index+1:02d} / {len(SCENES):02d}',font=font(18),fill=MUTED)
    d.text((W-520,H-54),'Demostración · datos de ejemplo',font=font(16),fill='#8FA5BF')
    return im


def chips(draw, labels, x, y, max_width=1050):
    f=font(22,True)
    start=x
    for label in labels:
        width=round(f.getlength(label))+46
        if x+width>start+max_width:
            x=start; y+=68
        draw.rounded_rectangle((x,y,x+width,y+50),25,fill='#16364A',outline='#2B6270',width=1)
        draw.text((x+23,y+8),label,font=f,fill='#B6F5DF')
        x+=width+14


def compose(index, scene):
    im=background(index)
    d=ImageDraw.Draw(im)
    kind=scene['kind']
    compact = kind=='web'
    title_width = 510 if compact else 1040
    title_size = 59 if compact else 78
    if kind in ['hook','value','cta']:
        title_size=88
        title_width=1640
    d.text((100,165),scene['eyebrow'],font=font(21,True),fill=GOLD)
    y=text_block(d,scene['title'],(96,225),title_width,title_size,bold=True)
    y=text_block(d,scene['body'],(100,y+28),title_width,29 if compact else 33,color=MUTED,spacing=1.5)
    chips(d,scene['tags'],100,y+42,max_width=520 if compact else 1020)
    if kind in ['mobile','sos']:
        phone(im,scene['mobile'],1320,158,790)
        # Guía visual del recorrido, sin alterar las pantallas.
        dd=ImageDraw.Draw(im)
        dd.text((1320,958),'DISEÑO MÓVIL',font=font(17,True),fill=MUTED)
    elif kind=='dual':
        browser(im,scene['web'],948,345,820)
        phone(im,scene['mobile'],1300,160,790)
    elif kind=='web':
        browser(im,scene['web'],665,168,1150)
    elif kind=='hook':
        # Tres nodos forman una comunidad: animación posterior sobre la composición.
        dd=ImageDraw.Draw(im)
        points=[(1320,710),(1510,570),(1700,710)]
        dd.line(points+[points[0]],fill='#286A7A',width=4)
        for x,y in points:
            dd.ellipse((x-37,y-37,x+37,y+37),fill='#164154',outline=TEAL,width=3)
            dd.ellipse((x-9,y-15,x+9,y+3),fill='#C5F7E8')
            dd.rounded_rectangle((x-16,y+7,x+16,y+23),8,fill='#C5F7E8')
    elif kind=='value':
        dd=ImageDraw.Draw(im)
        for x,label in [(100,'COLABORAR'),(665,'CONFIAR'),(1230,'RESPONDER')]:
            dd.rounded_rectangle((x,740,x+500,865),24,fill='#12354B',outline='#326076',width=2)
            dd.text((x+40,775),label,font=font(33,True),fill=GOLD)
    elif kind=='cta':
        dd=ImageDraw.Draw(im)
        dd.line((100,785,1810,785),fill='#3C5669',width=2)
        dd.text((100,823),'NEARBY',font=font(66,True),fill=WHITE)
        dd.text((575,848),'La ayuda empieza cerca. El impacto empieza contigo.',font=font(30),fill='#C1ECD9')
    out=OUT/f'frames/scene-{index:02d}.png'
    out.parent.mkdir(parents=True,exist_ok=True)
    im.save(out)
    return out


def run(args):
    p=subprocess.run([FFMPEG,'-hide_banner','-loglevel','error','-y',*map(str,args)],capture_output=True,text=True)
    if p.returncode:
        raise RuntimeError(p.stderr[-6000:])


async def narrate():
    import edge_tts
    folder=OUT/'audio'; folder.mkdir(parents=True,exist_ok=True)
    for i, scene in enumerate(SCENES):
        path=folder/f'{i:02d}.mp3'
        if not path.exists() or path.stat().st_size<1000:
            for attempt in range(3):
                try:
                    await edge_tts.Communicate(scene['voice'],'es-PE-AlexNeural',rate='+3%').save(str(path))
                    break
                except Exception:
                    if attempt==2: raise
                    await asyncio.sleep(2)
        print(f'Locución {i+1}/{len(SCENES)}',flush=True)


def duration(path):
    p=subprocess.run([FFMPEG,'-i',str(path)],capture_output=True,text=True)
    h,m,s=re.search(r'Duration: (\d+):(\d+):(\d+\.\d+)',p.stderr).groups()
    return int(h)*3600+int(m)*60+float(s)


def timecode(t, separator=','):
    ms=round(t*1000); h,ms=divmod(ms,3600000); m,ms=divmod(ms,60000); s,ms=divmod(ms,1000)
    return f'{h:02d}:{m:02d}:{s:02d}{separator}{ms:03d}'


def subtitle_chunks(text):
    words=text.split(); lines=[]; line=''
    for word in words:
        if len(line+' '+word)>48 and line:
            lines.append(line); line=word
        else: line=(line+' '+word).strip()
    if line: lines.append(line)
    return ['\n'.join(lines[i:i+2]) for i in range(0,len(lines),2)]


def music(total):
    """Cama musical original: armonía cálida, pulso suave y resolución final."""
    sr=24000; count=round((total+1)*sr); t=np.arange(count,dtype=np.float64)/sr
    audio=np.zeros(count,dtype=np.float64)
    chords=[(146.83,185.00,220.00),(130.81,164.81,196.00),(110,138.59,164.81),(130.81,164.81,196.00)]
    bar=60/92*4
    for i in range(math.ceil(total/bar)):
        start=int(i*bar*sr); end=min(count,int((i+1)*bar*sr)); local=t[start:end]-i*bar
        envelope=np.minimum(local/0.55,1)*np.minimum((bar-local)/0.65,1)
        for freq in chords[i%4]:
            audio[start:end]+=0.05*envelope*(np.sin(2*np.pi*freq*local)+0.16*np.sin(2*np.pi*freq*2*local))
        # Pulso discreto, sin sirenas ni sonidos que parezcan alertas reales.
        pulse=np.mod(local,60/92)
        audio[start:end]+=0.022*np.exp(-pulse*16)*np.sin(2*np.pi*70*local)
    audio*=np.minimum(t/3,1)*np.minimum((total+1-t)/4,1)
    out=OUT/'audio/music-original.wav'
    with wave.open(str(out),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(sr)
        f.writeframes((np.clip(audio,-1,1)*32767).astype('<i2').tobytes())
    return out


def render():
    asyncio.run(narrate())
    clips=[]; chapters=[]; srt=[]; ass_events=[]; offset=0
    for i,scene in enumerate(SCENES):
        picture=compose(i,scene)
        voice=OUT/f'audio/{i:02d}.mp3'
        voice_duration=duration(voice)
        length=math.ceil((voice_duration+1.2)*FPS)/FPS
        clip=OUT/f'scene-{i:02d}.mp4'
        count=round(length*FPS)
        # Movimiento leve de cámara + entrada/salida, audio con margen de respiración.
        vf=(f"scale=2112:1188,zoompan=z='min(1.01,1+on*0.000012)':"
            f"x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d={count}:s=1920x1080:fps={FPS},"
            f"fade=t=in:st=0:d=0.22,fade=t=out:st={length-0.22:.3f}:d=0.22,format=yuv420p")
        run(['-loop','1','-framerate',FPS,'-i',picture,'-i',voice,'-vf',vf,
             '-af',f'adelay=400|400,apad=whole_dur={length}',
             '-t',length,'-c:v','libx264','-preset','fast','-crf','19','-r',FPS,
             '-c:a','aac','-b:a','160k','-ar','48000','-ac','2',clip])
        clips.append(clip)
        chapters.append({'start':round(offset,3),'duration':length,'title':scene['eyebrow']})
        chunks=subtitle_chunks(scene['voice']); total_chars=sum(map(len,chunks)); current=offset+0.4
        for chunk in chunks:
            dt=voice_duration*len(chunk)/total_chars
            srt.append(f'{len(srt)+1}\n{timecode(current)} --> {timecode(current+dt)}\n{chunk}\n')
            text = chunk.replace('\n', r'\N')
            ass_events.append(f'Dialogue: 0,{timecode(current,".")[:-1]},{timecode(current+dt,".")[:-1]},Default,,0,0,0,,{text}')
            current+=dt
        offset+=length
        print(f'Escena {i+1}/{len(SCENES)} lista · {length:.1f} s',flush=True)
    (OUT/'Nearby_Pitch.srt').write_text('\n'.join(srt),encoding='utf-8')
    ass_header = '''[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
WrapStyle: 2

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Poppins,30,&H00FFFFFF,&H00FFFFFF,&H8009172F,&H8009172F,0,0,0,0,100,100,0,0,3,8,0,2,120,120,72,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
'''
    (OUT/'Nearby_Pitch.ass').write_text(ass_header+'\n'.join(ass_events),encoding='utf-8')
    (OUT/'chapters.json').write_text(json.dumps(chapters,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'guion.txt').write_text('\n\n'.join(s['eyebrow']+'\n'+s['voice'] for s in SCENES),encoding='utf-8')
    playlist=OUT/'clips.txt'
    playlist.write_text('\n'.join("file '"+p.name+"'" for p in clips),encoding='utf-8')
    silent=OUT/'assembled.mp4'
    import os
    os.chdir(OUT)
    run(['-f','concat','-safe','0','-i','clips.txt','-c','copy',silent])
    finalize(offset)


def finalize(offset=None):
    import os
    os.chdir(OUT)
    silent=OUT/'assembled.mp4'
    if offset is None:
        offset=duration(silent)
    bed=music(offset)
    final=OUT/'Nearby_Pitch.mp4'
    # Subtítulos incrustados para que el pitch funcione también sin sonido.
    # cwd evita problemas de escape de letras de unidad Windows en libass.
    (OUT/'fonts').mkdir(exist_ok=True)
    for f in FONT_DIR.glob('*.ttf'):
        shutil.copy2(f, OUT/'fonts'/f.name)
    filters=("[0:v]ass=Nearby_Pitch.ass:fontsdir=fonts[v];"
             '[0:a]volume=1.0[voice];[1:a]volume=0.28[bed];'
             '[voice][bed]amix=inputs=2:duration=first,loudnorm=I=-16:TP=-1.5:LRA=11[a]')
    run(['-i',silent,'-i',bed,'-filter_complex',filters,'-map','[v]','-map','[a]',
         '-c:v','libx264','-preset','fast','-crf','19','-c:a','aac','-b:a','192k',
         '-ar','48000','-ac','2',
         '-metadata','title=Nearby · Siempre cerca para ayudar',
         '-metadata','comment=Demostración con datos de ejemplo. Pitch para impulsar un piloto.',
         '-movflags','+faststart',final])
    delivery=ROOT/'docs/presentation'
    delivery.mkdir(parents=True,exist_ok=True)
    for name in ['Nearby_Pitch.mp4','Nearby_Pitch.srt','guion.txt','chapters.json']:
        shutil.copy2(OUT/name,delivery/name)
    Image.open(OUT/'frames/scene-01.png').convert('RGB').save(delivery/'portada.jpg',quality=94)
    print(f'FINAL: {delivery / final.name}\nDuración: {offset:.2f} s',flush=True)


if __name__=='__main__':
    finalize() if '--finalize-only' in sys.argv else render()
