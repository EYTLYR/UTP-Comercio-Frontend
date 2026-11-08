"""Dossier de presentación y recursos para el jurado. PDF con enlaces y QR."""
from pathlib import Path
from datetime import date
from xml.sax.saxutils import escape
import json

from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph
from reportlab.lib.utils import ImageReader
from reportlab.graphics.barcode.qr import QrCodeWidget
from reportlab.graphics.shapes import Drawing
from reportlab.graphics import renderPDF
from PIL import Image
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'output/pdf/Nearby_Presentacion_Recursos_Jurado.pdf'
BUILD = ROOT / 'build/jury-pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
BUILD.mkdir(parents=True, exist_ok=True)
URLS = {
    'frontend': 'https://github.com/EYTLYR/UTP-Comercio-Frontend',
    'backend': 'https://github.com/EYTLYR/UTP-Comercio-Backend',
    'db': 'https://github.com/EYTLYR/UTP-Comercio-Data-Base',
    'web': 'https://nearby.eytlyr.com',
    'api': 'https://nearby-api.eytlyr.com',
    'health': 'https://nearby-api.eytlyr.com/actuator/health',
    'apk': 'https://utpedupe-my.sharepoint.com/:f:/g/personal/u23224351_utp_edu_pe/IgD7MPZVUIJgR41MGa9RtmXGAXj7N4zANX7N_HijE_KnSso?e=IltleL',
}
for name, filename in [('Poppins','Poppins-Regular.ttf'),('Poppins-Bold','Poppins-Bold.ttf'),('Poppins-Medium','Poppins-Medium.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(ROOT/'assets/fonts'/filename)))
pdfmetrics.registerFontFamily('Poppins', normal='Poppins', bold='Poppins-Bold', italic='Poppins', boldItalic='Poppins-Bold')
W,H=A4
M=44
NAVY=colors.HexColor('#0B2D6B')
INK=colors.HexColor('#172B4D')
MUTED=colors.HexColor('#52627F')
TEAL=colors.HexColor('#00796B')
PALE=colors.HexColor('#F1F6FC')
LINE=colors.HexColor('#D8E2EF')
GOLD=colors.HexColor('#F5C44E')
c=canvas.Canvas(str(OUT),pagesize=A4,pageCompression=1)
c.setTitle('Nearby | Presentación del proyecto y recursos para el jurado')
c.setAuthor('Equipo Nearby')
c.setSubject('Aplicación web, APK, repositorios y endpoint de salud para evaluación del proyecto Nearby')
c.setCreator('Equipo Nearby - documento de presentación')


def para(text,x,top,width,size=11,color=INK,bold=False,leading=None):
    style=ParagraphStyle('p',fontName='Poppins-Bold' if bold else 'Poppins',fontSize=size,
        leading=leading or size*1.5,textColor=color,spaceAfter=0,splitLongWords=1)
    p=Paragraph(text,style)
    _,height=p.wrap(width,H)
    p.drawOn(c,x,H-top-height)
    return height


def label(text,top):
    return para(text,M,top,W-2*M,9.5,MUTED,True)


def rule(top):
    c.setStrokeColor(LINE);c.setLineWidth(.6)
    c.line(M,H-top,W-M,H-top)


def footer(n):
    rule(H-44)
    para('NEARBY  /  RECURSOS PARA EL JURADO',M,H-34,420,8,MUTED)
    para(f'{n} / 3',W-M-40,H-34,40,8,MUTED)


def image(path,x,top,width,height):
    c.drawImage(ImageReader(str(path)),x,H-top-height,width,height,mask='auto',preserveAspectRatio=True,anchor='c')


def link(text,url,x,top,width,size=11,color=NAVY,bold=False):
    markup=f'<link href="{escape(url, {chr(34): "&quot;"})}" color="{color.hexval()}"><u>{escape(text)}</u></link>'
    return para(markup,x,top,width,size,color,bold)


def qr(url,x,top,size=88):
    # Margen blanco incluido para permitir lectura en pantalla o papel.
    widget=QrCodeWidget(url,barLevel='M')
    bx,by,bw,bh=widget.getBounds()
    bw-=bx;bh-=by
    drawing=Drawing(size,size,transform=[size/bw,0,0,size/bh,-bx*size/bw,-by*size/bh])
    drawing.add(widget)
    c.setFillColor(colors.white)
    c.rect(x-5,H-top-size-5,size+10,size+10,stroke=0,fill=1)
    renderPDF.draw(drawing,c,x,H-top-size)
    c.linkURL(url,(x-5,H-top-size-5,x+size+5,H-top+5),relative=0,thickness=0)


def heading(title,number):
    label('NEARBY  /  PRESENTACIÓN DEL PROYECTO',35)
    para(title,M,77,W-2*M,27,NAVY,True,leading=35)


# Página 1: propósito, beneficio y diseño real.
c.setFillColor(PALE);c.rect(0,0,W,H,stroke=0,fill=1)
label('PRESENTACIÓN DEL PROYECTO',30)
image(ROOT/'docs/brand/logo_horizontal.png',M,64,237,77)
para('Tu barrio, conectado',M,167,W-2*M,30,NAVY,True,leading=39)
para('Nearby reúne servicios recomendados, favores entre vecinos y apoyo por proximidad. '
     'La comunidad que colabora cada día puede organizarse mejor cuando surge una emergencia.',
     M,224,W-2*M,12.3,MUTED,leading=19)
para('MÓVIL Y WEB',M,313,300,10,TEAL,True)
web=Image.open(ROOT/'docs/presentation/assets/web-home.png').convert('RGB')
web=web.crop((0,0,web.width,web.height-90))
web.save(BUILD/'web.png')
image(BUILD/'web.png',M,352,350,216)
image(ROOT/'docs/presentation/assets/mobile-home.png',401,322,148,320)
para('Confianza para elegir un oficio. Un muro para compartir recursos.\n'
     'Un recorrido SOS para solicitar apoyo y consultar la respuesta.',
     M,592,344,10.6,INK,leading=16)
para('Interfaces de la app con datos de demostración.',M,653,W-2*M,8.5,MUTED)
rule(680)
para('ABRE LA APLICACIÓN',M,697,360,10,TEAL,True)
link(URLS['web'],URLS['web'],M,718,370,16.5,NAVY,True)
para('Prueba la experiencia desde el navegador,\nen tu celular o en una computadora.',M,751,360,10.2,MUTED,leading=16)
qr(URLS['web'],W-M-86,698,86)
footer(1);c.showPage()

# Página 2: enlaces operativos y APK.
heading('Prueba la solución',2)
para('Accesos directos para revisar la aplicación, consultar el estado del servicio '
     'y abrir la carpeta compartida de Android. Todos los enlaces son clicables.',
     M,126,W-2*M,11,MUTED,leading=17)

para('01   Aplicación web',M,190,W-2*M,14,NAVY,True)
link(URLS['web'],URLS['web'],M,219,W-2*M,11.5)
para('Interfaz pública del proyecto, adaptada a móvil y escritorio.',M,244,W-2*M,10.5,MUTED)
rule(281)

para('02   Backend en producción',M,300,W-2*M,14,NAVY,True)
link(URLS['api'],URLS['api'],M,329,W-2*M,11.5)
para('URL base de la API. La consulta a la raíz sin sesión devolvió HTTP 401; '
     'usa el siguiente endpoint para comprobar el estado del servicio.',M,354,W-2*M,10.5,MUTED,leading=16)
rule(403)

para('03   Prueba de salud del backend',M,422,W-2*M,14,NAVY,True)
link(URLS['health'],URLS['health'],M,451,W-2*M,10.8)
para('GET /actuator/health',M,478,W-2*M,10.5,INK,True)
para('Comprobación del 8 de noviembre de 2026: HTTP 200 y estado UP. '
     'El endpoint permite consultar el estado actual al abrirlo.',M,501,W-2*M,10.5,MUTED,leading=16)
rule(551)

para('04   APK de Android',M,570,W-2*M,14,NAVY,True)
link('Abrir carpeta compartida de la APK',URLS['apk'],M,600,370,11.5,NAVY,True)
para('SharePoint aloja la carpeta compartida indicada por el equipo. '
     'Abre el enlace para localizar el archivo de instalación disponible.',M,627,365,10.5,MUTED,leading=16)
qr(URLS['apk'],W-M-87,617,87)
para('Acceso sujeto a los permisos del enlace compartido.',M,678,365,9.5,MUTED,leading=14)
para('ENLACE COMPLETO',M,710,W-2*M,8.5,MUTED,True)
link(URLS['apk'],URLS['apk'],M,729,W-2*M,8.1)
footer(2);c.showPage()

# Página 3: revisión de código, equipo y cierre.
heading('Código y equipo',3)
para('Los repositorios separan la interfaz, la API y la preparación de la base de datos '
     'para facilitar la revisión técnica del proyecto.',M,126,W-2*M,11,MUTED,leading=17)

repos=[
    ('Frontend','frontend','Interfaz Flutter, navegación y conexión con la API.'),
    ('Backend','backend','API Spring Boot y lógica de servicios, colaboración y emergencias.'),
    ('Base de datos','db','Esquema y preparación de PostgreSQL con PostGIS.'),
]
for i,(title,key,description) in enumerate(repos):
    top=190+i*99
    para(title,M,top,W-2*M,13.5,NAVY,True)
    link(URLS[key],URLS[key],M,top+27,W-2*M,10.4)
    para(description,M,top+51,W-2*M,10.2,MUTED)
    if i<2:rule(top+84)

rule(491)
para('Equipo Nearby',M,511,W-2*M,17,NAVY,True)
para('Orden alfabético por apellido',M,541,W-2*M,9.5,MUTED)
people=[
    ('Christian Daniel Campaña Díaz','U23224351'),
    ('Ronal James Llapapasca Montes','U22221880'),
    ('Heidy Lisbeth Lozano Vasquez','U23272014'),
    ('Nigson Shrimi Tarrillo Condor','U23224391'),
]
for i,(name,code) in enumerate(people):
    top=573+i*31
    para(name,M,top,397,10.5,INK)
    para(code,W-M-92,top,92,10.5,TEAL,True)

rule(710)
para('La ayuda empieza cerca.',M,731,W-2*M,18,NAVY,True)
para('El impacto empieza contigo.',M,760,W-2*M,13,TEAL,True)
footer(3)
c.save()

# Verificación de integridad de recursos, texto y enlaces PDF.
reader=PdfReader(OUT)
found=set()
for page in reader.pages:
    for annotation in page.get('/Annots',[]):
        action=annotation.get_object().get('/A',{})
        if action.get('/S')=='/URI':found.add(str(action.get('/URI')))
missing=set(URLS.values())-found
if missing:raise RuntimeError('Faltan enlaces en el PDF: '+repr(missing))
all_text='\n'.join(page.extract_text() or '' for page in reader.pages)
for name,code in people:
    if name not in all_text or code not in all_text:raise RuntimeError('Falta un integrante: '+name)
if len(reader.pages)!=3:raise RuntimeError('Cantidad de páginas inesperada')
report={'file':str(OUT),'pages':len(reader.pages),'unique_links':len(found),'all_supplied_links_present':True,'participants_verified':4}
(BUILD/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=True))
