import 'package:flutter/material.dart';

import '../widgets/nearby_logo.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  static const _blue = Color(0xFF263B65);
  static const _yellow = Color(0xFFF2C14E);
  static const _track = Color(0xFFE7E4DD);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 390,
            height: 844,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 291,
                  child: ExcludeSemantics(
                    child: NearbyLogo(
                      width: 150,
                      inkColor: _blue,
                      greenColor: _yellow,
                    ),
                  ),
                ),
                Positioned(
                  top: 450,
                  left: 24,
                  right: 24,
                  child: Text(
                    'Nearby',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                      height: 1.25,
                    ),
                  ),
                ),
                Positioned(
                  top: 515,
                  left: 24,
                  right: 24,
                  child: Text(
                    'Siempre cerca para ayudar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _blue,
                    ),
                  ),
                ),
                Positioned(
                  top: 671,
                  child: SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(
                      color: _yellow,
                      backgroundColor: _track,
                      strokeWidth: 3,
                      semanticsLabel: 'Cargando Nearby',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
