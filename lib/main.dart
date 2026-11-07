import 'package:flutter/material.dart';

import 'config/app_environment.dart';
import 'services/startup_permissions.dart';
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
import 'screens/services_screens.dart';
import 'screens/splash_screen.dart';
import 'screens/wall_screen.dart';
import 'state/app_state.dart';
import 'theme/nearby_theme.dart';
import 'widgets/bottom_sheets.dart';
import 'widgets/common_widgets.dart';
import 'widgets/interactive_tour.dart';
import 'widgets/simulation_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnvironment.load();
  final permissions = StartupPermissions();
  await permissions.initialize();
  runApp(NearbyApp(permissions: permissions));
}

class NearbyApp extends StatefulWidget {
  final StartupPermissions? permissions;
  const NearbyApp({super.key, this.permissions});

  @override
  State<NearbyApp> createState() => _NearbyAppState();
}

class _NearbyAppState extends State<NearbyApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(permissions: widget.permissions);
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
          home: Stack(
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
      child: Theme(
        data: theme.materialTheme,
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
            backgroundColor: theme.bg,
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
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildAppContent(context),
                    ),
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

  Widget _buildAppContent(BuildContext context) {
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
              if (meta.nav && MediaQuery.viewInsetsOf(context).bottom == 0)
                NearbyBottomNav(state: state, theme: theme),
            ],
          ),

          if (state.sheet != null)
            NearbyBottomSheetModal(state: state, theme: theme),
          if (state.tourName != null)
            InteractiveTourOverlay(state: state, theme: theme),

          // Floating Toast Widget
          if (state.toastMessage != null && state.tourName == null)
            NearbyToastWidget(
              message: state.toastMessage!,
              icon: state.toastIcon,
            ),
        ],
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
