import 'package:flutter/material.dart';

import 'screens/ai_screens.dart';
import 'screens/auth_screens.dart';
import 'screens/board_screens.dart';
import 'screens/communication_screens.dart';
import 'screens/emergency_screens.dart';
import 'screens/home_screen.dart';
import 'screens/map_screens.dart';
import 'screens/profile_screens.dart';
import 'screens/publish_screen.dart';
import 'screens/services_screens.dart';
import 'screens/splash_screen.dart';
import 'screens/wall_screen.dart';
import 'state/app_state.dart';
import 'theme/nearby_theme.dart';
import 'widgets/bottom_sheets.dart';
import 'widgets/common_widgets.dart';
import 'widgets/interactive_tour.dart';
import 'widgets/simulation_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NearbyApp());
}

class NearbyApp extends StatefulWidget {
  const NearbyApp({super.key});

  @override
  State<NearbyApp> createState() => _NearbyAppState();
}

class _NearbyAppState extends State<NearbyApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final theme = NearbyThemeData.build(
          dark: _state.dark,
          lg: _state.lg,
          hc: _state.hc,
          emergency: _state.emergency,
        );

        return MaterialApp(
          title: 'Nearby',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Nunito',
            scaffoldBackgroundColor: theme.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primary,
              brightness: _state.dark ? Brightness.dark : Brightness.light,
            ),
          ),
          home: NearbyMasterShell(state: _state, theme: theme),
        );
      },
    );
  }
}

/* ========================================================================= */
/*                           MASTER RESPONSIVE SHELL                         */
/* ========================================================================= */

class NearbyMasterShell extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const NearbyMasterShell({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 820;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: NearbyColors.stage,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Simulation Left Panel
                SimulationPanel(state: state, theme: theme),
                const SizedBox(width: 36),
                // Phone Device Mock
                _buildPhoneContainer(context, isDesktop: true),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile / Narrow Viewport
    return Scaffold(
      backgroundColor: theme.bg,
      endDrawer: Drawer(
        width: 320,
        backgroundColor: theme.surface,
        child: SimulationPanel(state: state, theme: theme, isDrawer: true),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildPhoneInner(context),
            // Floating pill to open simulation panel on mobile
            Positioned(
              right: 14,
              top: 10,
              child: Builder(
                builder: (ctx) => InkWell(
                  onTap: () => Scaffold.of(ctx).openEndDrawer(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: NearbyColors.navy.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Simulador',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneContainer(BuildContext context, {required bool isDesktop}) {
    final mediaH = MediaQuery.of(context).size.height;
    final targetH = (mediaH - 48).clamp(0.0, 844.0);
    final targetW = targetH * (390 / 844);

    return SizedBox(
      width: targetW,
      height: targetH,
      child: FittedBox(
        child: Container(
          width: 390,
          height: 844,
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(56),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 38,
                offset: Offset(0, 16),
              ),
            ],
            border: Border.all(color: const Color(0xFF2B2B2B), width: 11),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(46),
            child: _buildPhoneInner(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInner(BuildContext context) {
    final meta = _getScreenMeta(state.screen);
    final emUI = state.emergency && meta.bar != null && !meta.noEm;

    Color screenBg = theme.bg;
    if (meta.full == 'red') screenBg = NearbyColors.sos;
    if (meta.full == 'navyfull') screenBg = NearbyColors.navy;

    return Container(
      color: screenBg,
      child: Stack(
        children: [
          Column(
            children: [
              // Phone Status Bar
              if (MediaQuery.sizeOf(context).width > 820)
                _buildStatusBar(light: meta.full != null),

              // Screen Top Bar (if applicable)
              if (meta.bar == 'main')
                NearbyTopBar(state: state, theme: theme)
              else if (meta.bar == 'back')
                NearbyTopBarBack(
                  theme: theme,
                  state: state,
                  title: _getScreenTitle(state.screen, state),
                ),

              // Emergency Banner
              if (emUI) NearbyEmergencyBanner(state: state),

              // Offline Banner
              if (meta.bar != null && state.offline)
                NearbyOfflineBanner(state: state),

              // Main Screen View
              Expanded(
                child: ClipRect(child: _buildScreenContent(state.screen)),
              ),

              // Bottom Navigation (if applicable)
              if (meta.nav) NearbyBottomNav(state: state, theme: theme),
            ],
          ),

          // Interactive Coachmarks Overlay
          if (state.tourName != null)
            InteractiveTourOverlay(state: state, theme: theme),

          // Modal Bottom Sheet Overlay
          if (state.sheet != null)
            NearbyBottomSheetModal(state: state, theme: theme),

          // Floating Toast Widget
          if (state.toastMessage != null)
            NearbyToastWidget(
              message: state.toastMessage!,
              icon: state.toastIcon,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar({required bool light}) {
    return IconTheme(
      data: IconThemeData(color: light ? Colors.white : theme.ink),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: light ? Colors.white : theme.ink),
        child: Container(
          height: 46,
          padding: const EdgeInsets.fromLTRB(34, 4, 26, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time
              const Text(
                '9:41',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              // Dynamic Island
              Container(
                width: 118,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Cellular, Wifi, Battery icons
              Row(
                children: [
                  const Icon(Icons.signal_cellular_alt, size: 15),
                  const SizedBox(width: 4),
                  Icon(state.offline ? Icons.wifi_off : Icons.wifi, size: 15),
                  const SizedBox(width: 4),
                  const Icon(Icons.battery_5_bar, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenContent(String screen) {
    switch (screen) {
      // Acceso & Registro
      case 'splash':
        return SplashScreen(state: state, theme: theme);
      case 'login':
        return LoginScreen(state: state, theme: theme);
      case 'otp':
        return OtpScreen(state: state, theme: theme);
      case 'registro':
        return RegistroScreen(state: state, theme: theme);
      case 'contactos':
        return ContactosScreen(state: state, theme: theme);
      case 'permisos':
        return PermisosScreen(state: state, theme: theme);
      case 'listo':
        return ListoScreen(state: state, theme: theme);

      // Día a día
      case 'home':
        return HomeScreen(state: state, theme: theme);
      case 'servicios':
        return ServicesScreen(state: state, theme: theme);
      case 'svc':
        return ServiceDetailScreen(state: state, theme: theme);
      case 'muro':
        return WallScreen(state: state, theme: theme);
      case 'publicar':
        return PublishScreen(state: state, theme: theme);
      case 'mapa':
        return MapScreen(state: state, theme: theme);
      case 'ruta':
        return RouteScreen(state: state, theme: theme);
      case 'chat':
        return ChatScreen(state: state, theme: theme);
      case 'llamada':
        return CallScreen(state: state, theme: theme);
      case 'ficha':
        return FichaScreen(state: state, theme: theme);

      // Emergencia
      case 'sos':
        return SosScreen(state: state, theme: theme);
      case 'sos-countdown':
        return SosCountdownScreen(state: state, theme: theme);
      case 'sos-sent':
        return SosSentScreen(state: state, theme: theme);
      case 'alerta-recibida':
        return AlertaRecibidaScreen(state: state, theme: theme);
      case 'tablero':
        return TableroScreen(state: state, theme: theme);
      case 'recursos':
        return RecursosScreen(state: state, theme: theme);
      case 'apoyo':
        return ApoyoScreen(state: state, theme: theme);

      // IA & Brigadista
      case 'red':
        return RedScreen(state: state, theme: theme);
      case 'puente':
        return PuenteScreen(state: state, theme: theme);
      case 'perfil':
        return PerfilScreen(state: state, theme: theme);

      default:
        return HomeScreen(state: state, theme: theme);
    }
  }

  ScreenMeta _getScreenMeta(String screen) {
    return _screensMeta[screen] ?? const ScreenMeta();
  }

  String _getScreenTitle(String screen, AppState state) {
    switch (screen) {
      case 'login':
        return 'Ingresar';
      case 'otp':
        return 'Confirmar teléfono';
      case 'registro':
        return 'Crear tu cuenta';
      case 'contactos':
        return 'Contactos de confianza';
      case 'permisos':
        return 'Permisos';
      case 'svc':
        return 'Oficio de vecino';
      case 'publicar':
        return 'Publicar favor';
      case 'ruta':
        return 'Ruta a pie';
      case 'chat':
        return state.chatWith ?? 'Carlos Mendoza';
      case 'ficha':
        return 'Ficha de emergencia';
      case 'sos-sent':
        return 'Alerta enviada';
      case 'tablero':
        return 'Tablero humanitario';
      case 'red':
        return 'Red de rescate';
      case 'puente':
        return 'Modo brigadista';
      case 'perfil':
        return 'Mi perfil';
      default:
        return '';
    }
  }
}

class ScreenMeta {
  final String? bar;
  final bool nav;
  final bool noEm;
  final String? full;

  const ScreenMeta({this.bar, this.nav = false, this.noEm = false, this.full});
}

const Map<String, ScreenMeta> _screensMeta = {
  'splash': ScreenMeta(),
  'login': ScreenMeta(bar: 'back', noEm: true),
  'otp': ScreenMeta(bar: 'back', noEm: true),
  'registro': ScreenMeta(bar: 'back', noEm: true),
  'contactos': ScreenMeta(bar: 'back'),
  'permisos': ScreenMeta(bar: 'back', noEm: true),
  'listo': ScreenMeta(),
  'home': ScreenMeta(bar: 'main', nav: true),
  'servicios': ScreenMeta(bar: 'main', nav: true),
  'svc': ScreenMeta(bar: 'back'),
  'muro': ScreenMeta(bar: 'main', nav: true),
  'publicar': ScreenMeta(bar: 'back', nav: true),
  'mapa': ScreenMeta(bar: 'main', nav: true),
  'ruta': ScreenMeta(bar: 'back'),
  'chat': ScreenMeta(bar: 'back'),
  'llamada': ScreenMeta(full: 'navyfull'),
  'ficha': ScreenMeta(bar: 'back'),
  'sos': ScreenMeta(full: 'red'),
  'sos-countdown': ScreenMeta(full: 'red'),
  'sos-sent': ScreenMeta(full: 'red'),
  'alerta-recibida': ScreenMeta(full: 'red'),
  'tablero': ScreenMeta(bar: 'back', nav: true),
  'recursos': ScreenMeta(bar: 'main', nav: true),
  'apoyo': ScreenMeta(bar: 'main', nav: true),
  'red': ScreenMeta(bar: 'back'),
  'puente': ScreenMeta(bar: 'back', noEm: true),
  'perfil': ScreenMeta(bar: 'back'),
};
