import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/nearby_logo.dart';

class SplashScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const SplashScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.bg,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      child: Column(
        children: [
          const Spacer(),
          // Wordmark with logo
          NearbyWordmark(
            width: 240,
            inkColor: theme.logoInk,
            gapColor: theme.bg,
          ),
          const SizedBox(height: 20),
          Text(
            'Tu barrio, más cerca. Servicios de confianza, ayuda entre vecinos y apoyo en emergencias.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              color: theme.muted,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // Feature tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _tag(Icons.verified, 'Visto Bueno Vecinal', theme),
              _tag(Icons.handshake, 'Cadena de favores', theme),
              _tag(Icons.emergency, 'SOS en un gesto', theme),
            ],
          ),
          const Spacer(),

          // Enter button
          ElevatedButton.icon(
            onPressed: () => state.go('login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.btnBg,
              foregroundColor: theme.btnInk,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: Icon(
              Icons.smartphone,
              color: theme.dark ? theme.btnInk : NearbyColors.brandTurquoise,
              size: 22,
            ),
            label: Text(
              'Ingresar con mi celular',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin contraseñas: te enviamos un código por SMS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: theme.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label, NearbyThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.line),
        borderRadius: BorderRadius.circular(999),
        boxShadow: theme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.primary, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: theme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
