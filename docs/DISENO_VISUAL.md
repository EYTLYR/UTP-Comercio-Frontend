# Sistema visual de Nearby

*Siempre cerca para ayudar.* Moderno, minimalista, cercano y confiable.

Todo sale de `lib/theme/nearby_theme.dart` (`NearbyColors`, `NearbyThemeData`, `NearbySpacing`, `NearbyRadius`).
`lib/core/theme/` (`AppColorPalette`, `AppTokens`) usa la misma paleta para los componentes de `widgets/common/`.

## Paleta oficial

| Color | Hex | Uso |
|---|---|---|
| Azul marino | `#0B2D6B` | Color principal: títulos, textos, botones principales, barra de emergencia |
| Turquesa | `#00BFA6` | Acento: botón «+», confirmaciones («Estoy bien»), avatar, corazón del isotipo |
| Celeste | `#B9E0F5` | Secundario: información (tinte `#E3F2FB` en fondos) |
| Azul muy claro | `#F1F6FC` | Fondo de todas las pantallas |
| Blanco | `#FFFFFF` | Tarjetas, campos y paneles |
| Gris claro | `#E9EEF4` | Bordes y separadores |

Derivados para cumplir contraste (WCAG):

- `primary` `#00A38E`: turquesa para íconos sobre blanco (≥ 3:1).
- `primaryDark` `#00796B`: turquesa para textos sobre blanco (≥ 4.5:1).
- `onPrimary`: sobre un relleno turquesa se escribe en **azul marino** (5.6:1), nunca en blanco (2.3:1).
- `muted` `#52627F`: texto secundario (6.2:1).
- `lineStrong` `#B4C3D6`: borde de campos.

Rojo (SOS) y ámbar (aviso) se mantienen **solo como colores de estado**: en una app de emergencias su significado no se cambia.
El modo oscuro usa azul marino profundo con turquesa `#00BFA6` como acento.

## Tipografía: Poppins

- Archivos en `assets/fonts/` (Regular 400, Medium 500, SemiBold 600 y Bold 700), con licencia OFL.
- Van dentro de la app, así que funcionan sin internet.
- No se incluyen los pesos 800/900: si una pantalla los pide, se usa Bold, y la jerarquía queda en cuatro pesos.
- Poppins es más ancha que la fuente anterior. `NearbyTextScaler.brandOptical` (0.93) compensa esa diferencia para que los textos ocupen el mismo espacio y no se corten. «Texto grande» sigue multiplicando ×1.4.

| Rol | Tamaño / peso |
|---|---|
| Título de pantalla | 19–24 / 700 |
| Título de sección | 16 / 700 |
| Título de tarjeta | 13.5–15 / 600–700 |
| Texto | 13.5–15 / 400 |
| Texto secundario (`muted`) | 11–13 / 400–500 |
| Botón | 15 / 600 |

## Componentes

- **Botones:**
  - Radio 14 y alto 52 (48 en botones dentro de tarjetas).
  - Principal: azul marino lleno. Secundario: contorno `lineStrong`. Terciario: texto.
  - Peligro: rojo SOS.
- **Campos:** radio 14, borde `lineStrong` y foco en el color principal. Etiqueta y error en Poppins.
- **Tarjetas:** blanco, borde `#E9EEF4`, radio 18 y `theme.cardShadow` (sombra de dos capas, muy suave).
- **Chips y pastillas:** radio completo (`StadiumBorder`).
- **Hojas inferiores y diálogos:** radio 24.
- **Navegación inferior:**
  - La pestaña activa lleva un fondo turquesa suave y el ícono en turquesa profundo.
  - El botón «+» es turquesa con el ícono azul marino.
- **Isotipo** (`NearbyLogo`):
  - Mano abierta (azul marino) que sostiene un corazón (turquesa), dibujada en vector.
  - Si existe el archivo oficial (SVG o PNG), basta con reemplazar el `CustomPainter` en `lib/widgets/nearby_logo.dart`. La API (`width`, `inkColor`, `gapColor`, `greenColor`) no cambia.

## Cómo se aplican las leyes de la Gestalt

| Ley | Dónde se ve |
|---|---|
| **Proximidad** | Etiqueta pegada a su campo. Secciones separadas 20–24 dp y elementos de un grupo a 8–12 dp. Título y acción de sección («Ver todo») en la misma fila. |
| **Semejanza** | Un solo radio y un solo alto por tipo de botón. Todas las tarjetas son iguales. El turquesa siempre significa «activo» o «confirmado», y el rojo siempre significa emergencia. |
| **Continuidad** | Margen lateral de 16 dp en todas las pantallas. Los textos van alineados a la izquierda y se leen de arriba hacia abajo. La acción principal está al final. |
| **Cierre** | Tarjetas y paneles con borde y sombra completos, que agrupan su contenido sin líneas sueltas. |
| **Figura y fondo** | Las tarjetas blancas resaltan sobre el fondo `#F1F6FC` gracias a la sombra suave. El texto secundario pierde peso, y el corazón del isotipo tiene un contorno del color del fondo. |
| **Simetría y orden** | Rejillas 2×2 en Inicio, una escala de espaciado de 4 en 4 y radios fijos (10/14/18/24). |
| **Destino común** | Los pasos de un mismo proceso (SOS, cuenta regresiva, enviado; cola sin conexión) comparten color de estado y estilo de componente. |

## Reglas para pantallas nuevas o cambios

1. Usa `theme.*` o `NearbyColors.*`, nunca un `Color(0x…)` suelto, y no uses `Colors.grey`.
2. No fijes `fontFamily`: la app ya usa Poppins.
3. Usa los botones de Material (`ElevatedButton`, `OutlinedButton`, `TextButton`), que ya traen el estilo. Solo cambia el color cuando el botón tenga otro significado (SOS).
4. Si escribes sobre turquesa, usa `theme.onPrimary`.
