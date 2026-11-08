import 'package:flutter/material.dart';

import '../theme/nearby_theme.dart';

/// Logo oficial de Nearby a partir de los archivos de marca (`assets/brand/`).
///
/// Cada logo está separado en dos capas con fondo transparente: la *tinta* (mano y texto, azul
/// marino) y el *corazón* (turquesa). Se tiñen al pintarse, así el mismo logo oficial se ve en
/// el tema claro, en el oscuro y en la barra azul marino del modo emergencia (tinta en blanco).
class _BrandLayers extends StatelessWidget {
  final String name;
  final double width;
  final double aspect;
  final Color ink;
  final Color heart;
  final String label;

  const _BrandLayers({
    required this.name,
    required this.width,
    required this.aspect,
    required this.ink,
    required this.heart,
    required this.label,
  });

  Widget _layer(String part, Color color) => Image.asset(
    'assets/brand/${name}_$part.png',
    width: width,
    height: width * aspect,
    fit: BoxFit.contain,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
    // Si la imagen no carga (por ejemplo en una prueba sin assets), deja el espacio vacío.
    errorBuilder: (_, _, _) => SizedBox(width: width, height: width * aspect),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: SizedBox(
      width: width,
      height: width * aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [_layer('tinta', ink), _layer('corazon', heart)],
      ),
    ),
  );
}

/// Isotipo oficial: mano abierta que sostiene un corazón.
class NearbyLogo extends StatelessWidget {
  /// Alto / ancho del isotipo oficial recortado.
  static const double aspect = 1.2;

  final double width;

  /// Color de la mano (azul marino por defecto; blanco sobre fondos oscuros).
  final Color? inkColor;

  /// Ya no se usa: el espacio entre la mano y el corazón es transparente. Se conserva para
  /// no cambiar las llamadas existentes.
  final Color? gapColor;

  /// Color del corazón (turquesa por defecto).
  final Color? greenColor;

  const NearbyLogo({
    super.key,
    this.width = 40,
    this.inkColor,
    this.gapColor,
    this.greenColor,
  });

  @override
  Widget build(BuildContext context) => _BrandLayers(
    name: 'isotipo',
    // Se dibuja con el alto de antes (ancho × 0.84) para no mover lo que lo rodea.
    width: width * 0.84 / aspect,
    aspect: aspect,
    ink: inkColor ?? NearbyColors.brandNavy,
    heart: greenColor ?? NearbyColors.brandTurquoise,
    label: 'Nearby',
  );
}

/// Logotipo oficial vertical: isotipo, «Nearby» y el lema «Siempre cerca para ayudar».
class NearbyWordmark extends StatelessWidget {
  /// Alto / ancho del logotipo vertical recortado.
  static const double aspect = 1.142;

  final double width;
  final Color? inkColor;

  /// Ya no se usa (ver [NearbyLogo.gapColor]).
  final Color? gapColor;

  const NearbyWordmark({
    super.key,
    this.width = 220,
    this.inkColor,
    this.gapColor,
  });

  @override
  Widget build(BuildContext context) => _BrandLayers(
    name: 'logo_vertical',
    width: width,
    aspect: aspect,
    ink: inkColor ?? NearbyColors.brandNavy,
    heart: NearbyColors.brandTurquoise,
    label: 'Nearby, siempre cerca para ayudar',
  );
}
