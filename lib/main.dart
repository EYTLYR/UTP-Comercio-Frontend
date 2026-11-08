import 'package:flutter/material.dart';

import 'config/app_environment.dart';
import 'services/startup_permissions.dart';
import 'widgets/side_nav.dart';
import 'widgets/permission_intro.dart';
import 'screens/ai_screens.dart';
import 'screens/auth_screens.dart';
import 'screens/board_screens.dart';
import 'screens/communication_screens.dart';
import 'screens/emergency_screens.dart';
import 'screens/home_screen.dart';
import 'screens/map_screens.dart';
import 'screens/profile_screens.dart';
import 'screens/publish_screen.dart';
import 'screens/roles_screens.dart';
import 'screens/municipality_screens.dart';
import 'screens/services_screens.dart';
import 'screens/splash_screen.dart';
import 'screens/startup_screen.dart';
import 'screens/wall_screen.dart';
import 'state/app_state.dart';
import 'theme/nearby_theme.dart';
import 'core/motion/app_motion.dart';
import 'widgets/bottom_sheets.dart';
import 'widgets/common_widgets.dart';
import 'widgets/common/offline_sync_pill.dart';
import 'widgets/navigation_chrome.dart';
import 'widgets/interactive_tour.dart';
import 'widgets/simulation_panel.dart';
import 'screens/sms_map_screen.dart';
import 'services/offline_tiles.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NearbyApp(permissions: StartupPermissions(), connectToApi: true));
}

class NearbyApp extends StatefulWidget {
  final StartupPermissions? permissions;

  /// true en la app real: se conecta a la Nearby API (ver lib/api/api_config.dart).
  /// Las pruebas de widgets usan false y trabajan con los datos de ejemplo.
  final bool connectToApi;
  const NearbyApp({super.key, this.permissions, this.connectToApi = false});

  @override
  State<NearbyApp> createState() => _NearbyAppState();
}

class _NearbyAppState extends State<NearbyApp> {
  late final AppState _state;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _state = AppState(permissions: widget.permissions);
    // Sesión guardada -> inicio con datos del backend; si no, bienvenida.
    if (widget.connectToApi) {
      _state.screen = 'splash';
      _starting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bootstrap();
      });
    }
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait<void>([
        _initialize(),
        Future<void>.delayed(const Duration(milliseconds: 1400)),
      ]);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _initialize() async {
    await AppEnvironment.load();
    await OfflineTiles.instance.init();
    if (!mounted) return;
    await widget.permissions?.initialize();
    if (mounted) await _state.bootstrap();
  }

  @override
  void dispose() {
    widget.permissions?.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _state,
        if (widget.permissions != null) widget.permissions!,
      ]),
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
          theme: theme.materialTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: NearbyTextScaler(
                MediaQuery.textScalerOf(context),
                theme.scaleFactor,
              ),
              highContrast: _state.hc || MediaQuery.highContrastOf(context),
            ),
            child: child!,
          ),
          home: _starting
              ? const StartupScreen()
              : Stack(
                  children: [
                    NearbyMasterShell(state: _state, theme: theme),
                    if (widget.permissions?.visible == true)
                      PermissionIntro(permissions: widget.permissions!),
                  ],
                ),
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

  // Diseño nuevo: página blanca en todas las pantallas (modo claro), también en emergencia.
  Color get _pageBackground =>
      !theme.dark && !theme.hc ? Colors.white : theme.bg;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler is NearbyTextScaler
            ? media.textScaler
            : NearbyTextScaler(media.textScaler, theme.scaleFactor),
        highContrast: state.hc || media.highContrast,
      ),
      child: AnimatedTheme(
        data: theme.materialTheme,
        duration: AppMotion.normal,
        curve: AppMotion.easeOut,
        child: PopScope(
          canPop:
              state.screen == 'home' &&
              state.sheet == null &&
              state.tourName == null,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (state.sheet != null) {
              state.closeSheet();
            } else if (state.tourName != null) {
              state.endTour();
            } else if (state.screen != 'home') {
              state.back();
            }
          },
          child: Scaffold(
            backgroundColor: _pageBackground,
            endDrawer: AppEnvironment.showDevelopmentTools
                ? Drawer(
                    width: 320,
                    backgroundColor: theme.surface,
                    child: SimulationPanel(
                      state: state,
                      theme: theme,
                      isDrawer: true,
                    ),
                  )
                : null,
            body: SafeArea(
              child: Stack(
                children: [
                  // Celular: pantalla completa. Escritorio (≥ 900 px): navegación lateral y contenido
                  // centrado hasta 1100 px. El acceso y el registro van en una columna centrada.
                  LayoutBuilder(
                    builder: (context, box) {
                      final wide = box.maxWidth >= kDesktopBreakpoint;
                      final meta = _getScreenMeta(state.screen);
                      if (!wide) return _buildAppContent(context, wide: false);
                      // Pantallas a pantalla completa (SOS en rojo, llamada): todo el ancho.
                      if (meta.full != null) {
                        return _buildAppContent(context, wide: true);
                      }
                      // Solo el acceso y el registro van en una columna centrada.
                      if (_accessScreens.contains(state.screen)) {
                        return ColoredBox(
                          color: _pageBackground,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: _buildAppContent(context, wide: true),
                            ),
                          ),
                        );
                      }
                      return Row(
                        children: [
                          NearbySideNav(state: state, theme: theme),
                          Expanded(
                            child: _buildAppContent(context, wide: true),
                          ),
                        ],
                      );
                    },
                  ),
                  if (AppEnvironment.showDevelopmentTools)
                    const _DevelopmentToolsButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bienvenida, ingreso y registro: en escritorio van en una columna centrada, sin navegación lateral.
  static const _accessScreens = {
    'splash',
    'login',
    'otp',
    'registro',
    'contactos',
    'permisos',
    'listo',
  };

  Widget _buildAppContent(BuildContext context, {required bool wide}) {
    final meta = _getScreenMeta(state.screen);
    // En escritorio la barra inferior la reemplaza la navegación lateral.
    final showBottomNav =
        meta.nav && !wide && MediaQuery.viewInsetsOf(context).bottom == 0;
    // El mapa usa todo el ancho; el resto se centra hasta 1100 px.
    final fullBleed = const {'mapa', 'mapa-sms', 'ruta'}.contains(state.screen);
    Widget screen(String name) {
      final child = _buildAnimatedScreen(name);
      if (!wide || fullBleed) return child;
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kDesktopContentMaxWidth),
          child: child,
        ),
      );
    }

    final emUI = state.emergency && meta.bar != null && !meta.noEm;

    Color screenBg = _pageBackground;
    if (meta.full == 'red') {
      screenBg = state.isSilentMode ? Colors.black : NearbyColors.sos;
    }
    if (meta.full == 'navyfull') screenBg = NearbyColors.navy;

    return AnimatedContainer(
      key: state.tourViewportKey,
      duration: AppMotion.normal,
      curve: AppMotion.easeOut,
      color: screenBg,
      child: Stack(
        children: [
          if (const {
            'home',
            'servicios',
            'svc',
            'muro',
            'mapa',
            'tablero',
            'recursos',
            'apoyo',
            'perfil',
            'red',
          }.contains(state.screen))
            NavigationChrome(
              childHandlesFade: state.screen == 'mapa',
              background: screenBg,
              topBackground: screenBg,
              top: _topChrome(meta, emUI, wide),
              bottom: showBottomNav
                  ? NearbyBottomNav(state: state, theme: theme)
                  : null,
              child: screen(state.screen),
            )
          else
            Column(
              children: [
                _topChrome(meta, emUI, wide),
                Expanded(child: ClipRect(child: screen(state.screen))),
                if (showBottomNav) NearbyBottomNav(state: state, theme: theme),
              ],
            ),

          if (state.sheet != null)
            NearbyBottomSheetModal(state: state, theme: theme),
          if (state.tourName != null)
            InteractiveTourOverlay(state: state, theme: theme),

          // Floating Toast Widget
          if (state.toastMessage != null && state.tourName == null)
            NearbyToastWidget(
              key: ValueKey(state.toastId),
              onDismiss: state.dismissToast,
              message: state.toastMessage!,
              icon: state.toastIcon,
            ),
        ],
      ),
    );
  }

  // Cabecera blanca del diseño nuevo, también en emergencia (el aviso rojo va debajo). En escritorio
  // se alinea con el contenido (1100 px) y en el mapa tiene fondo sólido para leerse sobre las calles.
  Widget _topChrome(ScreenMeta meta, bool emUI, bool wide) => AnimatedContainer(
    key: const ValueKey('top-chrome'),
    duration: AppMotion.normal,
    curve: AppMotion.easeOut,
    margin: EdgeInsets.only(bottom: emUI ? 6 : 0),
    decoration: BoxDecoration(
      color: state.screen == 'mapa' ? theme.surface : null,
      border: state.screen == 'mapa'
          ? Border(bottom: BorderSide(color: theme.line))
          : null,
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: wide ? kDesktopContentMaxWidth : double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (meta.bar == 'main')
              NearbyTopBar(state: state, theme: theme)
            else if (meta.bar == 'back')
              NearbyTopBarBack(
                theme: theme,
                state: state,
                title: _getScreenTitle(state.screen, state),
              ),
            if (emUI) NearbyEmergencyBanner(state: state),
            if (state.prevention && meta.bar == 'main')
              NearbyPreventionBanner(state: state),
            if (meta.bar != null && state.offline)
              NearbyOfflineBanner(state: state),
            // Floating sync pill indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: OfflineSyncPill(state: state),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildAnimatedScreen(String screen) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: const Cubic(0.23, 1.0, 0.32, 1.0),
      switchOutCurve: Curves.easeInQuad,
      // Keep only the active screen in layout and hit testing. Retaining the
      // outgoing form can overflow when the next route has different chrome.
      layoutBuilder: (currentChild, previousChildren) =>
          currentChild ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(screen),
        child: _buildScreenContent(screen),
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
      case 'mapa-sms':
        return SmsMapScreen(state: state, theme: theme);
      case 'perfil':
        return PerfilScreen(state: state, theme: theme);
      case 'municipalidad':
        return MunicipalidadScreen(state: state, theme: theme);
      case 'muni-registro':
        return MunicipalityRegisterScreen(state: state, theme: theme);
      case 'mensajes':
        return MensajesScreen(state: state, theme: theme);
      case 'prevencion':
        return PrevencionScreen(state: state, theme: theme);

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
        return state.chatWith ?? 'Chat';
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
      case 'mapa-sms':
        return 'Ubicación del SMS';
      case 'perfil':
        return 'Mi perfil';
      case 'municipalidad':
        return state.isPlatformAdmin
            ? 'Administración Nearby'
            : 'Panel de Municipalidad';
      case 'muni-registro':
        return 'Registrar Municipalidad';
      case 'mensajes':
        return 'Mensajes';
      case 'prevencion':
        return 'Prevención El Niño';
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
  'mapa-sms': ScreenMeta(bar: 'back'),
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
  'municipalidad': ScreenMeta(bar: 'back'),
  'muni-registro': ScreenMeta(bar: 'back'),
  'mensajes': ScreenMeta(bar: 'back', nav: true),
  'prevencion': ScreenMeta(bar: 'back', nav: true),
};

class _DevelopmentToolsButton extends StatefulWidget {
  const _DevelopmentToolsButton();
  @override
  State<_DevelopmentToolsButton> createState() =>
      _DevelopmentToolsButtonState();
}

class _DevelopmentToolsButtonState extends State<_DevelopmentToolsButton> {
  Offset? _position;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final position =
          _position ?? Offset(box.maxWidth - 64, box.maxHeight - 150);
      return Stack(
        children: [
          Positioned(
            left: position.dx.clamp(
              8.0,
              (box.maxWidth - 56).clamp(8.0, double.infinity),
            ),
            top: position.dy.clamp(
              8.0,
              (box.maxHeight - 56).clamp(8.0, double.infinity),
            ),
            child: GestureDetector(
              onPanUpdate: (event) =>
                  setState(() => _position = position + event.delta),
              child: FloatingActionButton.small(
                heroTag: 'development-tools',
                tooltip: 'Simulador',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                child: const Icon(Icons.tune),
              ),
            ),
          ),
        ],
      );
    },
  );
}
