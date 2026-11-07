import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/models/models.dart';
import 'package:utp_comercio_frontend/services/offline_tiles.dart';

void main() {
  test('5 km alrededor de la casa: zoom 12 a 16, unas cientos de teselas', () {
    final tiles = TileMath.tilesAround(
      -11.9790,
      -77.0030,
      radiusKm: 5,
      minZoom: OfflineTiles.minZoom,
      maxZoom: OfflineTiles.maxZoom,
    );
    expect(tiles.map((t) => t.z).toSet(), {12, 13, 14, 15, 16});
    expect(tiles.length, inInclusiveRange(250, 600));
    // La tesela de la casa a zoom 16 está incluida.
    final x = TileMath.lngToX(-77.0030, 16), y = TileMath.latToY(-11.9790, 16);
    expect(tiles.contains((z: 16, x: x, y: y)), isTrue);
  });

  test('el código SOS lleva el GPS y se recupera', () {
    final code = compressSOS(
      cat: 'herido',
      loc: 'Jr. Los Pinos 340',
      lat: -11.97901,
      lng: -77.00302,
    );
    expect(code, r'NB#SOS!H1@LP340$P:ALTA#G:-11.97901,-77.00302');
    expect(code.length, lessThanOrEqualTo(160));
    final d = decompressSOS(code)!;
    expect(d['where'], 'Jr. Los Pinos 340');
    expect(d['lat'], -11.97901);
    expect(d['lng'], -77.00302);
    expect(extractSosCode(code), r'NB#SOS!H1@LP340$P:ALTA');
  });

  test('acepta el SMS completo que manda el backend', () {
    const sms =
        'NEARBY SOS: María necesita ayuda. Ubicación: '
        r'https://maps.google.com/?q=-11.97900,-77.00300 · Código NB#SOS!H1@LF245$P:ALTA';
    final d = decompressSOS(sms)!;
    expect(d['type'], 'Persona herida');
    expect(d['lat'], -11.979);
    expect(d['lng'], -77.003);
  });

  test('sin GPS no inventa coordenadas', () {
    expect(decompressSOS(r'NB#SOS!H1@LP340$P:ALTA')!.containsKey('lat'), isFalse);
    expect(smsCoordinates('Llamar al 987654321'), isNull);
  });
}
