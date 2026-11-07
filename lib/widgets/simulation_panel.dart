import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import 'nearby_logo.dart';

class SimulationPanel extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  final bool isDrawer;

  const SimulationPanel({
    super.key,
    required this.state,
    required this.theme,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDrawer ? null : 320,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: isDrawer ? null : BorderRadius.circular(24),
        boxShadow: isDrawer
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 28,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Brand header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: theme.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: NearbyLogo(
                      width: 32,
                      inkColor: NearbyColors.navy,
                      gapColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: NearbyColors.navy,
                        ),
                      ),
                      Text(
                        'Prototipo · Hackathon',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: NearbyColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDrawer)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Screen note card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NearbyColors.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: NearbyColors.accentInk,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ESTA PANTALLA',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: NearbyColors.accentInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getScreenNote(state.screen),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF5A4100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _sectionHeading('SIMULAR'),
            _toggleItem(
              Icons.cloud_off,
              'Sin conexión',
              state.offline,
              () => state.toggleOffline(),
            ),
            _toggleItem(
              Icons.crisis_alert,
              'Modo emergencia',
              state.emergency,
              () => state.toggleEmergency(),
              isRed: true,
            ),
            _toggleItem(
              Icons.dark_mode,
              'Tema oscuro',
              state.dark,
              () => state.toggleDark(),
            ),
            _toggleItem(
              Icons.format_size,
              'Texto grande',
              state.lg,
              () => state.toggleLg(),
            ),

            _toggleItem(
              Icons.contrast,
              'Alto contraste',
              state.hc,
              state.toggleHc,
            ),

            _sectionHeading('ACCESO Y REGISTRO'),
            _navItem(Icons.waving_hand, 'Bienvenida (marca)', () {
              state.emergency = false;
              state.go('splash', reset: true);
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'splash'),
            _navItem(Icons.smartphone, 'Ingresar con celular', () {
              state.emergency = false;
              state.phoneDraft = '';
              state.go('login');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'login'),
            _navItem(Icons.sms, 'Código SMS', () {
              state.emergency = false;
              if (state.phoneDraft.isEmpty) state.phoneDraft = '987654321';
              state.go('otp');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'otp'),
            _navItem(Icons.person_add, 'Registro y ubicación', () {
              state.emergency = false;
              state.regName = '';
              state.regLoc = null;
              state.go('registro');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'registro'),
            _navItem(Icons.contacts, 'Contactos de confianza', () {
              state.emergency = false;
              state.contactsMode = 'setup';
              state.go('contactos');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'contactos'),
            _navItem(Icons.verified_user, 'Permisos', () {
              state.emergency = false;
              state.perms = {
                'loc': false,
                'notif': false,
                'sms': false,
                'ai': false,
              };
              state.go('permisos');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'permisos'),
            _navItem(Icons.task_alt, 'Cuenta lista', () {
              state.emergency = false;
              state.go('listo', reset: true);
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'listo'),

            _sectionHeading('DÍA A DÍA'),
            _navItem(Icons.home, 'Inicio (SOS primero)', () {
              state.emergency = false;
              state.go('home', reset: true);
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'home' && !state.emergency),
            _navItem(Icons.touch_app, 'Tutorial interactivo', () {
              state.emergency = false;
              state.go('home', reset: true);
              state.startTour('main');
              if (isDrawer) Navigator.pop(context);
            }),
            _navItem(Icons.handyman, 'Servicios del barrio', () {
              state.emergency = false;
              state.go('servicios');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'servicios'),
            _navItem(Icons.verified, 'Detalle + Visto Bueno', () {
              state.emergency = false;
              state.selService = 'julio';
              state.go('svc');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'svc'),
            _navItem(Icons.chat, 'Chat con un vecino', () {
              state.emergency = false;
              state.openChat(
                'Julio Quispe',
                sysMsg: 'Consultaste por: Gasfitería',
              );
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'chat'),
            _navItem(Icons.call, 'Llamada en curso', () {
              state.emergency = false;
              state.startCall('Julio Quispe');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'llamada'),
            _navItem(Icons.volunteer_activism, 'Muro solidario', () {
              state.emergency = false;
              state.go('muro');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'muro'),
            _navItem(Icons.add_circle, 'Publicar en 3 toques', () {
              state.emergency = false;
              state.pub.reset();
              state.go('publicar');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'publicar' && !state.emergency),
            _navItem(Icons.map, 'Mapa', () {
              state.emergency = false;
              state.mapFilter = 'all';
              state.go('mapa');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'mapa' && !state.emergency),
            _navItem(Icons.directions_walk, 'Cómo llegar (ruta)', () {
              state.emergency = false;
              state.routeTo = {
                'title': 'Julio Quispe · Gasfitería',
                'icon': Icons.plumbing,
                'kind': 'svc',
              };
              state.go('ruta');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'ruta' && !state.emergency),
            _navItem(Icons.person, 'Perfil y accesibilidad', () {
              state.emergency = false;
              state.go('perfil');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'perfil'),
            _navItem(Icons.medical_information, 'Ficha de emergencia', () {
              state.emergency = false;
              state.go('ficha');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'ficha'),

            _sectionHeading('IA NEARBY · PROTOCOLO LÁZARO'),
            _navItem(Icons.hub, 'Red de rescate del barrio', () {
              state.go('red');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'red'),
            _navItem(Icons.auto_awesome, 'IA asigna rescates (tablero)', () {
              state.emergency = true;
              state.zoneEm = true;
              state.go('tablero');
              state.runAi();
              if (isDrawer) Navigator.pop(context);
            }),
            _navItem(Icons.mic, 'Micrófono inteligente', () {
              state.pub.reset();
              state.go('publicar');
              state.openSheet('voice');
              if (isDrawer) Navigator.pop(context);
            }),
            _navItem(Icons.sms, 'SOS comprimido sin internet', () {
              state.offline = true;
              state.sosType = 'salud';
              state.lastCode = 'NB#SOS!S1@LF245\$P:ALTA';
              state.go('sos-sent');
              if (isDrawer) Navigator.pop(context);
            }),
            _navItem(Icons.cell_tower, 'Brigadista recibe el código', () {
              state.decoded = false;
              state.lastCode = 'NB#SOS!H1@LP340\$P:ALTA';
              state.go('puente');
              if (isDrawer) Navigator.pop(context);
            }, isCurrent: state.screen == 'puente'),

            _sectionHeading('EMERGENCIA', isRed: true),
            _navItem(
              Icons.sos,
              'Botón SOS',
              () {
                state.go('sos');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'sos',
              isRed: true,
            ),
            _navItem(
              Icons.timer,
              'Cuenta regresiva',
              () {
                state.sosType = null;
                state.go('sos-countdown');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'sos-countdown',
              isRed: true,
            ),
            _navItem(
              Icons.notifications_active,
              'Alerta enviada',
              () {
                state.go('sos-sent');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'sos-sent',
              isRed: true,
            ),
            _navItem(
              Icons.campaign,
              'Recibir alerta de un vecino',
              () {
                state.go('alerta-recibida');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'alerta-recibida',
              isRed: true,
            ),
            _navItem(
              Icons.directions_run,
              'Ir a ayudar (ruta)',
              () {
                state.emergency = true;
                state.routeTo = {
                  'title': 'Rosa Flores · Jr. Los Pinos 210',
                  'icon': Icons.emergency,
                  'kind': 'help',
                };
                state.go('ruta');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'ruta' && state.emergency,
              isRed: true,
            ),
            _navItem(
              Icons.crisis_alert,
              'Inicio en emergencia',
              () {
                state.emergency = true;
                state.zoneEm = true;
                state.emSource = 'zona';
                state.go('home', reset: true);
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'home' && state.emergency,
              isRed: true,
            ),
            _navItem(Icons.touch_app, 'Guía del modo emergencia', () {
              state.emergency = true;
              state.zoneEm = true;
              state.emSource = 'zona';
              state.startTour('em');
              if (isDrawer) Navigator.pop(context);
            }, isRed: true),
            _navItem(
              Icons.dashboard,
              'Tablero humanitario',
              () {
                state.emergency = true;
                state.zoneEm = true;
                state.go('tablero');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'tablero',
              isRed: true,
            ),
            _navItem(
              Icons.elderly,
              'Reportar vecino vulnerable',
              () {
                state.emergency = true;
                state.zoneEm = true;
                state.pub.reset(step: 2, type: 'vulnerable');
                state.go('publicar');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'publicar' && state.emergency,
              isRed: true,
            ),
            _navItem(
              Icons.inventory_2,
              'Recursos críticos',
              () {
                state.emergency = true;
                state.zoneEm = true;
                state.go('recursos');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'recursos',
              isRed: true,
            ),
            _navItem(
              Icons.diversity_3,
              'Grupos de apoyo',
              () {
                state.emergency = true;
                state.zoneEm = true;
                state.go('apoyo');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'apoyo',
              isRed: true,
            ),
            _navItem(
              Icons.map,
              'Mapa de emergencia',
              () {
                state.emergency = true;
                state.zoneEm = true;
                state.mapFilter = 'all';
                state.go('mapa');
                if (isDrawer) Navigator.pop(context);
              },
              isCurrent: state.screen == 'mapa' && state.emergency,
              isRed: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(String text, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
          color: isRed ? NearbyColors.sos : NearbyColors.muted,
        ),
      ),
    );
  }

  Widget _toggleItem(
    IconData icon,
    String label,
    bool value,
    VoidCallback onChanged, {
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: NearbyColors.muted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                height: 22,
                child: FittedBox(
                  child: Switch(
                    value: value,
                    activeThumbColor: isRed
                        ? NearbyColors.sos
                        : NearbyColors.primary,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isCurrent = false,
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrent
                ? (isRed ? NearbyColors.sosSoft : NearbyColors.primarySoft)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isCurrent
                    ? (isRed ? NearbyColors.sosDark : NearbyColors.primaryDark)
                    : (isRed ? NearbyColors.sos : NearbyColors.primary),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13.5,
                    color: isCurrent
                        ? (isRed
                              ? NearbyColors.sosDark
                              : NearbyColors.primaryDark)
                        : (isRed ? NearbyColors.sos : NearbyColors.navy),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getScreenNote(String screen) {
    switch (screen) {
      case 'splash':
        return 'Pantalla de bienvenida con la identidad Nearby. Servicios de confianza, ayuda entre vecinos y apoyo en emergencias.';
      case 'login':
        return 'Ingreso sin contraseña con el número de celular (Firebase Auth). Valida formato peruano de 9 dígitos empezando con 9.';
      case 'otp':
        return 'Verificación por código SMS de 6 dígitos: avanza solo al escribir. En el prototipo el código es 123456.';
      case 'registro':
        return 'Registro en 1 pantalla: nombre y ubicación por GPS para asignar la zona (geohash). La dirección exacta nunca se muestra.';
      case 'contactos':
        return 'Contactos de confianza: reciben la ubicación cuando usas el SOS (por SMS si no hay datos). Máximo 3.';
      case 'permisos':
        return 'Permisos explicados en lenguaje simple, uno por uno y con su motivo.';
      case 'listo':
        return 'Cierre del registro. Desde aquí arranca el tutorial interactivo sobre la app real.';
      case 'home':
        return state.emergency
            ? 'La app evoluciona en emergencia: el SOS sigue primero, y la portada cambia a estado personal, tablero humanitario y recursos.'
            : 'El botón SOS es lo primero que se ve. Se activa manteniendo 2 s. Debajo: llamadas directas y acciones del día a día.';
      case 'servicios':
        return 'Módulo 1 · Servicios de proximidad (economía local). Directorio de oficios con búsqueda, distancia y Visto Bueno Vecinal.';
      case 'svc':
        return 'Visto Bueno Vecinal: solo vecinos verificados de la misma zona pueden recomendar, 1 por persona. Contacto directo.';
      case 'muro':
        return 'Módulo 2 · Cadena de favores (economía solidaria). Préstamo de herramientas, ayuda temporal, materiales, habilidades y movilidad.';
      case 'publicar':
        return state.emergency
            ? 'En emergencia, el botón central pasa a Reportar: vecinos vulnerables y recursos críticos, con la misma regla de 3 toques.'
            : 'Máximo 3 toques para publicar: tipo, categoría y publicar. El texto es opcional; se puede dictar por voz o foto.';
      case 'mapa':
        return 'Geolocalización de servicios, recursos y necesidades. El mapa de la zona se descarga para funcionar sin internet.';
      case 'ruta':
        return 'Ruta a pie calculada sobre el mapa descargado de la zona, así funciona sin internet.';
      case 'chat':
        return 'Chat entre vecinos para coordinar favores y servicios. Sin conexión el mensaje queda en cola con reloj.';
      case 'llamada':
        return 'Pantalla de llamada en curso con cronómetro. En emergencias se comparte la ubicación con la central.';
      case 'alerta-recibida':
        return 'Lo que ve un vecino que recibe un SOS: quién, qué pasa, distancia y cuántos van. «Voy a ayudar» abre la ruta.';
      case 'tablero':
        return 'Tablero humanitario: reportes geolocalizados con prioridad y estado. La IA cruza el historial y asigna misiones.';
      case 'recursos':
        return 'Economía solidaria en emergencia: balance de recursos críticos (hay / falta) para coordinar agua, víveres, energía...';
      case 'apoyo':
        return 'El directorio de oficios se convierte en grupos de apoyo (brigadas, electricistas, evaluación de viviendas, olla común).';
      case 'red':
        return 'Inventario de supervivencia (IA silenciosa). Sin formularios: aprende del día a día quién tiene una escalera o sabe primeros auxilios.';
      case 'puente':
        return 'SMS comprimido por IA. Sin internet, el reporte se convierte en un código de ~22 caracteres que cabe en 1 SMS y se descomprime en el teléfono.';
      case 'perfil':
        return 'Contactos de confianza, ficha médica editable, interruptor de modo emergencia, accesibilidad y tema oscuro.';
      case 'ficha':
        return 'Ficha de emergencia editable: tipo de sangre, alergias, condiciones médicas y convivencia para brigadistas.';
      default:
        return 'Prototipo interactivo Nearby.';
    }
  }
}
