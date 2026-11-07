import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

class TourStepDef {
  final String title;
  final String desc;
  final String? btn;
  final bool isAction;
  final IconData? icon;
  final bool isCenter;

  const TourStepDef({
    required this.title,
    required this.desc,
    this.btn,
    this.isAction = false,
    this.icon,
    this.isCenter = false,
  });
}

final List<TourStepDef> kMainTourSteps = [
  const TourStepDef(
    isCenter: true,
    icon: Icons.touch_app,
    title: 'Aprende tocando la app',
    desc: 'Te guiamos paso a paso sobre las pantallas reales de Nearby. Toca donde brille. Nada de lo que hagas aquí se envía ni se publica.',
    btn: 'Empezar',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Practica el botón SOS',
    desc: 'Mantén el dedo sobre el botón 2 segundos, hasta que el anillo blanco se complete. Si solo lo tocas, no pasa nada: así se evitan alertas por error.',
  ),
  const TourStepDef(
    title: 'Llamadas de emergencia',
    desc: 'Con un toque llamas a la Policía (105), Bomberos (116) o SAMU (106). La app comparte tu ubicación con la central.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Busca un oficio de confianza',
    desc: 'Toca «Servicios» en la barra inferior para ver gasfiteros, electricistas, clases y más de tu barrio.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Filtra por lo que necesitas',
    desc: 'Toca el chip de «Gasfitería».',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Abre un perfil',
    desc: 'Toca a Julio Quispe para ver quién lo recomienda.',
  ),
  const TourStepDef(
    title: 'Visto Bueno Vecinal',
    desc: 'Este número son vecinos de tu zona que ya lo contrataron y lo recomiendan. Así sabes en quién confiar.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Recomienda tú también',
    desc: 'Cuando un vecino te atienda bien, toca «Dar visto bueno». Pruébalo ahora.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Vuelve atrás',
    desc: 'La flecha de arriba siempre te regresa a la pantalla anterior.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Pide o ofrece ayuda',
    desc:
        'El botón + central sirve para publicar en el muro de favores. Tócalo.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Toque 1 de 3: el tipo',
    desc: 'Toca «Necesito ayuda».',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Toque 2 de 3: la categoría',
    desc: 'Elige qué necesitas, por ejemplo «Préstamo de herramientas». Escribir es opcional.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Toque 3 de 3: publicar',
    desc: 'La ubicación se pone sola. Toca el botón para terminar.',
  ),
  const TourStepDef(
    isAction: true,
    title: '¡Publicaste en 3 toques!',
    desc: 'En la vida real, tus vecinos cercanos lo verían al instante. Toca «Volver al inicio».',
  ),
  const TourStepDef(
    title: 'Tu perfil',
    desc: 'Aquí eliges tus contactos de confianza, tu ficha médica, letra grande o tema oscuro. También puedes repetir este tutorial.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isCenter: true,
    icon: Icons.crisis_alert,
    title: 'Si hay una emergencia',
    desc: 'Nearby cambia sola a modo emergencia: verás el tablero del barrio, recursos y grupos de apoyo. Cuando todo pase, sales tocando el aviso rojo de arriba.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isCenter: true,
    icon: Icons.celebration,
    title: '¡Ya sabes usar Nearby!',
    desc: 'Practicaste el SOS, encontraste un servicio y publicaste un favor, todo tú solo. Puedes repetir el tutorial desde tu perfil.',
    btn: 'Terminar',
  ),
];

final List<TourStepDef> kEmTourSteps = [
  const TourStepDef(
    title: 'Estás en modo emergencia',
    desc: 'Nearby se reorganizó para coordinar ayuda en tu barrio. El botón SOS sigue siendo lo primero.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    title: 'Cuéntanos cómo estás',
    desc: 'Un toque en «Estoy bien» avisa a tus contactos y al tablero del barrio. Si necesitas ayuda, usa el SOS.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    title: 'Reporta en 3 toques',
    desc: 'El botón rojo central sirve para reportar vecinos vulnerables o pedir y ofrecer recursos como agua o víveres.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isAction: true,
    title: '¿Cómo salgo de este modo?',
    desc: 'Toca el aviso rojo superior con la campana de emergencia.',
  ),
  const TourStepDef(
    title: 'Desactivar cuando pase',
    desc: 'Desde aquí vuelves al modo normal. Si tu zona sigue en emergencia, igual recibirás alertas críticas.',
    btn: 'Entendido',
  ),
];

class InteractiveTourOverlay extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const InteractiveTourOverlay({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (state.tourName == null) return const SizedBox.shrink();

    final steps = state.tourName == 'main' ? kMainTourSteps : kEmTourSteps;
    if (state.tourIndex >= steps.length) return const SizedBox.shrink();

    final s = steps[state.tourIndex];
    final progress = (state.tourIndex + 1) / steps.length;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: s.isAction
              ? null
              : Colors.black.withValues(alpha: s.isCenter ? 0.74 : 0.65),
          padding: const EdgeInsets.all(18),
          child: SafeArea(
            child: Align(
              alignment: s.isCenter
                  ? Alignment.center
                  : (state.tourName == 'main' &&
                            [3, 9, 12, 13].contains(state.tourIndex)
                        ? Alignment.topCenter
                        : Alignment.bottomCenter),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 36,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.isCenter && s.icon != null) ...[
                      Container(
                        width: 58,
                        height: 58,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: NearbyColors.primarySoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          s.icon,
                          color: NearbyColors.primary,
                          size: 32,
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Icon(
                          s.isAction ? Icons.touch_app : Icons.school,
                          color: s.isAction
                              ? NearbyColors.sosDark
                              : NearbyColors.primaryDark,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.isAction
                              ? 'TU TURNO'
                              : 'PASO ${state.tourIndex + 1} DE ${steps.length}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: s.isAction
                                ? NearbyColors.sosDark
                                : NearbyColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: NearbyColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.desc,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14.5,
                        color: Color(0xFF46546A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (s.isAction)
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: NearbyColors.primaryDark,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Toca la pantalla para avanzar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: NearbyColors.primaryDark,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              if (state.tourIndex >= steps.length - 1) {
                                state.endTour(true);
                              } else {
                                state.nextTourStep();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: NearbyColors.navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            label: Text(
                              s.btn ?? 'Siguiente',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => state.endTour(false),
                          child: const Text(
                            'Salir',
                            style: TextStyle(
                              color: NearbyColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE4EAEE),
                        valueColor: const AlwaysStoppedAnimation(
                          NearbyColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
