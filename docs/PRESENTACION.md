# Video de presentación de Nearby

Entrega: `docs/presentation/Nearby_Pitch.mp4` (2 min 28 s, Full HD, H.264/AAC, 24 fps). Incluye narración sintética en español peruano, música original sintetizada, subtítulos integrados y cierre con CTA para impulsar un piloto. El MP4 y sus auxiliares se conservan en `docs/presentation/` aunque se ejecute `flutter clean`.

Los recursos editables están en `tool/presentation/`. El texto de cada escena, la narración y el CTA se cambian en `scenes.json`. No se incluyen cifras de impacto, usuarios reales ni alianzas que el proyecto no haya demostrado.

## Contenido

Problema → solución → servicios del barrio → muro de favores → SOS → confirmación de alerta → coordinación humanitaria → versión web → accesibilidad → diferencial → propuesta de piloto.

Las imágenes son capturas de los widgets actuales de Flutter, en tamaños móvil y escritorio, renderizadas con datos de ejemplo. Se presentan en marcos ilustrativos y con movimiento editorial; no es una grabación de una sesión en producción. No se enviaron SMS, alertas ni llamadas reales. La demostración lleva esa indicación en pantalla.

El CTA propone un piloto con vecinos, brigadistas y una municipalidad. Es una invitación para el jurado, no una alianza o despliegue ya confirmado.

## Regenerar

Desde la raíz del frontend:

```powershell
flutter test tool/presentation/capture_test.dart --dart-define=APP_ENV=production
python -m pip install --target build/presentation/deps edge-tts pillow numpy imageio-ffmpeg
python tool/presentation/render.py
```

La generación de voz necesita acceso a internet y envía únicamente el guion al servicio de síntesis. Las locuciones ya descargadas se reutilizan. Para cambiar una locución, borra únicamente su MP3 correspondiente en `build/presentation/audio/` antes de regenerar.

Archivos auxiliares de la entrega en `docs/presentation/`:

- `Nearby_Pitch.srt`: subtítulos por separado.
- `guion.txt`: guion de la narración.
- `chapters.json`: tiempos y nombres de las escenas.
- `portada.jpg`: portada para compartir el video.

Las composiciones (`frames/`), capturas (`captures/`) y demás archivos de trabajo se generan en `build/presentation/`.

La composición respeta los assets de marca y la tipografía Poppins incluidos en el proyecto. La música se sintetiza en el propio generador; no utiliza canciones comerciales.
