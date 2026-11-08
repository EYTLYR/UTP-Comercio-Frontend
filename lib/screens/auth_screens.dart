import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_environment.dart';
import '../services/device_actions.dart';

import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/neighborhood_painter.dart';
import '../widgets/nearby_logo.dart';

Widget _buildPdots(int currentStep, NearbyThemeData theme) {
  final style = _SetupStyle(theme);
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
    child: Row(
      children: [1, 2, 3].map((step) {
        final isOn = step <= currentStep;
        return Expanded(
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isOn ? style.accent : style.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _SetupStyle {
  const _SetupStyle(this.theme);

  final NearbyThemeData theme;
  bool get _light => !theme.dark && !theme.hc;
  Color get ink => _light ? const Color(0xFF263B65) : theme.ink;
  Color get muted => _light ? const Color(0xFF53627B) : theme.muted;
  Color get line => _light ? const Color(0xFFE7E4DD) : theme.line;
  Color get accent => _light ? const Color(0xFFF2C14E) : theme.btnBg;
  Color get onAccent => _light ? ink : theme.btnInk;
  Color get soft => _light ? const Color(0xFFEAF0FA) : theme.infoSoft;
  Color get panel => _light ? ink : theme.surface2;
  Color get onPanel => _light ? Colors.white : ink;

  ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: onAccent,
    disabledBackgroundColor: line,
    disabledForegroundColor: muted,
    minimumSize: const Size.fromHeight(48),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
    foregroundColor: ink,
    side: BorderSide(color: ink, width: 1.5),
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  TextStyle get title =>
      TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w700);
}

/// Keep the footer low on tall screens and allow the entire form to scroll
/// when the keyboard or large text leaves less vertical space.
class _AccessForm extends StatelessWidget {
  final List<Widget> children;
  final double horizontalPadding;

  const _AccessForm({required this.children, this.horizontalPadding = 20});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => SingleChildScrollView(
      key: const ValueKey('access-form-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (bounds.maxHeight - 34).clamp(0, double.infinity),
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  );
}

// --- 1. Login Screen ---
class LoginScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const LoginScreen({super.key, required this.state, required this.theme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _phoneController;
  String _err = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.state.phoneDraft);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    widget.state.phoneDraft = digits;
    setState(() {
      if (digits.isNotEmpty && !digits.startsWith('9')) {
        _err = 'Los celulares en Perú empiezan con 9';
      } else {
        _err = '';
      }
    });
  }

  bool get _isValid => RegExp(r'^9\d{8}$').hasMatch(widget.state.phoneDraft);

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final style = _SetupStyle(theme);

    return _AccessForm(
      horizontalPadding: 24,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: style.panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa con tu celular',
                style: style.title.copyWith(color: style.onPanel),
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviaremos un código por SMS. No necesitas correo ni contraseña.',
                style: TextStyle(color: style.onPanel, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: CustomPaint(
                  size: const Size(double.infinity, 96),
                  painter: NeighborhoodPainter(
                    sun: style._light ? style.accent : style.onPanel,
                    houses: style.soft,
                    roofs: style.onPanel,
                    windows: style.panel,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: style.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Número de celular',
                style: TextStyle(
                  color: style.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                onChanged: _onChanged,
                style: TextStyle(
                  color: style.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: '987 654 321',
                  counterText: '',
                  filled: true,
                  fillColor: theme.surface,
                  prefixIcon: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: style.soft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'Bandera del Perú',
                          image: true,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(2),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFD91023),
                                  Color(0xFFD91023),
                                  Colors.white,
                                  Colors.white,
                                  Color(0xFFD91023),
                                  Color(0xFFD91023),
                                ],
                                stops: [0, 1 / 3, 1 / 3, 2 / 3, 2 / 3, 1],
                              ),
                            ),
                            child: SizedBox(width: 18, height: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+51',
                          style: TextStyle(
                            color: style.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minHeight: 44),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _err.isEmpty ? style.line : NearbyColors.sos,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _err.isEmpty ? style.accent : NearbyColors.sos,
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (_err.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _err,
                  style: const TextStyle(
                    color: NearbyColors.sos,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isValid && !state.busy && !_busy
                    ? () async {
                        setState(() => _busy = true);
                        try {
                          if (await state.requestOtp() && mounted) {
                            state.go('otp');
                          }
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      }
                    : null,
                style: style.primaryButton,
                icon: const Icon(Icons.arrow_forward, size: 18),
                iconAlignment: IconAlignment.end,
                label: const Text('Enviar código'),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: style.line),
              const SizedBox(height: 12),
              Text(
                'Al continuar aceptas los términos y la política de privacidad de Nearby.',
                style: TextStyle(color: style.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 2. OTP Screen ---
class OtpScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const OtpScreen({super.key, required this.state, required this.theme});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsLeft = 30;
  Timer? _timer;
  String _err = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.state.otpResendSeconds;
    _startTimer();
    DeviceActions.channel.setMethodCallHandler((call) async {
      if (call.method == 'sms' && mounted) {
        final code = RegExp(r'(?<![0-9])[0-9]{6}(?![0-9])')
            .firstMatch(call.arguments as String? ?? '')
            ?.group(0);
        if (code != null) _fillCode(code);
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    DeviceActions.channel.setMethodCallHandler(null);
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool _verifying = false;
  Future<void> _checkCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6 || _verifying || _isSuccess) return;
    _verifying = true;
    try {
      final error = await widget.state.verifyOtp(code);
      if (!mounted) return;
      if (error != null) {
        setState(() => _err = error);
        return;
      }
      setState(() {
        _isSuccess = true;
        _err = '';
      });
      final next = widget.state.afterLogin;
      widget.state.afterLogin = null;
      widget.state.go(
        next ?? (widget.state.regPending ? 'registro' : 'home'),
        reset: true,
      );
    } finally {
      _verifying = false;
    }
  }

  void _fillCode(String code) {
    for (var i = 0; i < 6; i++) {
      _controllers[i].text = code[i];
    }
    _checkCode();
  }

  void _fillDemo() {
    final code = widget.state.otpDevCode;
    if (code != null && code.length == 6) _fillCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final useReferencePalette = !theme.dark && !theme.hc;
    final ink = useReferencePalette ? const Color(0xFF263B65) : theme.ink;
    final muted = useReferencePalette ? const Color(0xFF53627B) : theme.muted;
    final line = useReferencePalette ? const Color(0xFFE7E4DD) : theme.line;
    final accent = useReferencePalette
        ? const Color(0xFFF2C14E)
        : theme.primary;
    final smsSurface = useReferencePalette
        ? const Color(0xFFEAF0FA)
        : theme.infoSoft;
    final phone = state.phoneDraft.isNotEmpty
        ? state.phoneDraft
        : state.userPhone;
    final displayPhone = phone.replaceFirstMapped(
      RegExp(r'^(\d{3})(\d{3})(\d{3})$'),
      (match) => '${match[1]} ${match[2]} ${match[3]}',
    );

    return _AccessForm(
      horizontalPadding: 24,
      children: [
        Text(
          'Escribe el código',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
          decoration: BoxDecoration(
            color: smsSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sms_outlined,
                  color: useReferencePalette ? ink : theme.btnInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS enviado a',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+51 $displayPhone',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () => state.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: ink,
                        minimumSize: const Size(0, 36),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Cambiar número'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6 OTP boxes
        Row(
          children: List.generate(6, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 5 ? 6 : 0),
                child: SizedBox(
                  height: 60,
                  child: ListenableBuilder(
                    listenable: _focusNodes[i],
                    builder: (context, _) => TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      autofocus: i == 0,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      cursorColor: ink,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _isSuccess ? theme.primary : ink,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: _focusNodes[i].hasFocus ? null : '–',
                        hintStyle: TextStyle(color: line, fontSize: 16),
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: _isSuccess
                            ? theme.primarySoft
                            : theme.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _err.isNotEmpty ? NearbyColors.sos : line,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accent, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.length == 6) {
                          _fillCode(val);
                          return;
                        }
                        if (val.length > 1) {
                          _controllers[i].text = val.substring(val.length - 1);
                        }
                        if (val.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        _checkCode();
                      },
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_err.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error, color: NearbyColors.sos, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _err,
                  style: const TextStyle(
                    color: NearbyColors.sos,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Muestra el código si el servidor lo devolvió (modo demo o respaldo por fallo de SMS)
        if (state.otpDevCode != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.infoSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.vpn_key_outlined, color: theme.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Código de acceso: ${state.otpDevCode}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: NearbyColors.info,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _fillDemo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.info,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Usar código',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            backgroundColor: accent,
            disabledForegroundColor: muted,
            disabledBackgroundColor: line,
            minimumSize: const Size.fromHeight(44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _secondsLeft == 0 && !state.busy
              ? () async {
                  if (_verifying) return;
                  _verifying = true;
                  try {
                    final sent = await state.requestOtp();
                    if (!mounted || !sent) return;
                    setState(() => _secondsLeft = state.otpResendSeconds);
                    _timer?.cancel();
                    _startTimer();
                  } finally {
                    _verifying = false;
                  }
                }
              : null,
          child: Text(
            _secondsLeft > 0
                ? 'Reenviar código en 0:${_secondsLeft.toString().padLeft(2, "0")}'
                : 'Reenviar SMS',
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: ink, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Puedes autorizar la lectura de este único SMS para completar el código, o escribirlo manualmente.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- 3. Registro Screen ---
class RegistroScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const RegistroScreen({super.key, required this.state, required this.theme});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.regName);
    // Tomar automáticamente la ubicación y zona real del celular
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.locateForRegistration().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      widget.state.regName.trim().length > 1 && widget.state.regLoc == 'ok';

  Future<void> _launchGoogleMaps(
    double lat,
    double lng, {
    String? label,
  }) async {
    final query = Uri.encodeComponent(
      label != null && label.isNotEmpty ? '$label, Lima' : '$lat,$lng',
    );
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _openLocationPickerModal(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    double tempLat = state.regLat ?? -11.9790;
    double tempLng = state.regLng ?? -77.0030;
    final addrController = TextEditingController(text: state.regAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.map,
                          color: Color(0xFF1A73E8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecciona tu ubicación',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                              ),
                            ),
                            Text(
                              'Conéctate a tu vecindario con Google Maps',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campo de dirección
                  TextField(
                    controller: addrController,
                    decoration: InputDecoration(
                      labelText: 'Dirección o referencia',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Atajos de zonas
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(
                          Icons.my_location,
                          size: 16,
                          color: Color(0xFF1E8E3E),
                        ),
                        label: const Text(
                          'Detectar ubicación real',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () async {
                          final pos = await state.location.current();
                          setModalState(() {
                            tempLat = pos.lat;
                            tempLng = pos.lng;
                            if (pos.city != null && pos.city!.isNotEmpty) {
                              addrController.text = pos.region != null
                                  ? '${pos.city}, ${pos.region}'
                                  : pos.city!;
                            } else {
                              addrController.text =
                                  'Ubicación actual (${pos.lat.toStringAsFixed(4)}, ${pos.lng.toStringAsFixed(4)})';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tarjeta Google Maps
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.explore,
                          color: Color(0xFF1A73E8),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coordenadas del mapa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: theme.ink,
                                ),
                              ),
                              Text(
                                'Lat: ${tempLat.toStringAsFixed(4)}, Lng: ${tempLng.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _launchGoogleMaps(
                            tempLat,
                            tempLng,
                            label: addrController.text,
                          ),
                          icon: const Icon(Icons.open_in_new, size: 15),
                          label: const Text(
                            'Google Maps',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A73E8),
                            side: const BorderSide(color: Color(0xFF1A73E8)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () {
                      state.regLat = tempLat;
                      state.regLng = tempLng;
                      state.regAddress = addrController.text.trim().isNotEmpty
                          ? addrController.text.trim()
                          : 'Ubicación (${tempLat.toStringAsFixed(4)}, ${tempLng.toStringAsFixed(4)})';
                      state.regLoc = 'ok';
                      state.refresh();
                      Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NearbyColors.brandTurquoise,
                      foregroundColor: NearbyColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirmar ubicación',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final style = _SetupStyle(theme);

    return Column(
      children: [
        _buildPdots(1, theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text('Cuéntanos de ti', style: style.title),
              const SizedBox(height: 8),
              Text(
                'Así tus vecinos sabrán quién eres.',
                style: TextStyle(color: style.muted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: style.panel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: style.accent,
                      foregroundColor: style.onAccent,
                      child: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu nombre',
                            style: TextStyle(
                              color: style.onPanel,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameController,
                            onChanged: (val) {
                              state.regName = val;
                              setState(() {});
                            },
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: style.ink,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ej. María Quispe',
                              filled: true,
                              fillColor: theme.surface,
                              constraints: const BoxConstraints(minHeight: 44),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: style.line),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: style.accent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¿Dónde vives?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: style.ink,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 12),

              if (state.regLoc == 'loading')
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(color: style.line),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: theme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buscando tu ubicación…',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                              ),
                            ),
                            Text(
                              'Usamos el GPS solo para ubicar tu zona',
                              style: TextStyle(
                                color: theme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.regLoc == 'ok') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(color: style.line),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: theme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.where_to_vote,
                          color: Color(0xFF1A73E8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.regAddress,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tu zona: ${state.zoneName}',
                              style: TextStyle(
                                color: theme.muted,
                                fontSize: 12,
                              ),
                            ),
                            if (state.regLat != null && state.regLng != null)
                              Text(
                                'GPS: ${state.regLat!.toStringAsFixed(4)}, ${state.regLng!.toStringAsFixed(4)}',
                                style: TextStyle(
                                  color: theme.muted.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openLocationPickerModal(context),
                        child: Text(
                          'Cambiar',
                          style: TextStyle(
                            color: theme.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      final lat = state.regLat ?? -11.9790;
                      final lng = state.regLng ?? -77.0030;
                      _launchGoogleMaps(lat, lng, label: state.regAddress);
                    },
                    icon: const Icon(
                      Icons.open_in_new,
                      size: 15,
                      color: Color(0xFF1A73E8),
                    ),
                    label: const Text(
                      'Ver ubicación en Google Maps',
                      style: TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ] else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _locationOption(
                          style: style,
                          icon: Icons.location_on_outlined,
                          title: 'Google Maps o dirección',
                          description: 'Elige o escribe',
                          highlighted: true,
                          onPressed: () => _openLocationPickerModal(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _locationOption(
                          style: style,
                          icon: Icons.my_location,
                          title: 'GPS actual',
                          description: 'Detectar ubicación',
                          onPressed: () async {
                            await state.locateForRegistration();
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(
                    color: style.line,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: style.ink, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tus vecinos solo ven tu nombre y tu zona, nunca tu dirección exacta.',
                        style: TextStyle(color: theme.muted, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Footer button
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(top: BorderSide(color: style.line)),
          ),
          child: ElevatedButton(
            onPressed: _canContinue && !state.busy
                ? () async {
                    state.userName = state.regName.trim();
                    if (!await state.completeRegistration()) return;
                    if (!state.useApi) state.contacts = [];
                    state.contactsMode = 'setup';
                    state.perms = {
                      'loc': false,
                      'notif': false,
                      'sms': false,
                      'ai': false,
                    };
                    state.go('contactos');
                  }
                : null,
            style: style.primaryButton,
            child: const Text('Continuar'),
          ),
        ),
      ],
    );
  }

  Widget _locationOption({
    required _SetupStyle style,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
    bool highlighted = false,
  }) => OutlinedButton(
    onPressed: onPressed,
    style: style.secondaryButton.copyWith(
      backgroundColor: WidgetStatePropertyAll(
        highlighted ? style.soft : style.theme.surface,
      ),
      side: WidgetStatePropertyAll(BorderSide(color: style.line)),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: highlighted ? style.accent : style.soft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: highlighted ? style.onAccent : style.ink,
              ),
            ),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
        const SizedBox(height: 12),
        Text(title),
        const Spacer(),
        const SizedBox(height: 8),
        Text(description, style: TextStyle(color: style.muted, fontSize: 11)),
      ],
    ),
  );
}

// --- 4. Contactos Screen ---
class ContactosScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ContactosScreen({super.key, required this.state, required this.theme});

  @override
  State<ContactosScreen> createState() => _ContactosScreenState();
}

class _ContactosScreenState extends State<ContactosScreen> {
  String _search = '';

  Future<void> _addContactDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo contacto de confianza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                decoration: InputDecoration(
                  labelText: 'Celular (9 dígitos)',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final e = widget.state.addContact(
                  nameCtrl.text,
                  phoneCtrl.text,
                );
                if (e != null) {
                  setLocal(() => error = e);
                  return;
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final style = _SetupStyle(theme);
    final isSetup = state.contactsMode == 'setup';

    final filtered = state.contactBook
        .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    final selected = state.contacts
        .map(
          (id) => state.contactBook
              .where((contact) => contact.id == id)
              .firstOrNull,
        )
        .nonNulls
        .toList();
    final sosInk = theme.dark ? NearbyColors.darkSosDark : NearbyColors.sosDark;

    return Column(
      children: [
        if (isSetup) _buildPdots(2, theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            children: [
              Text('¿A quién avisamos si usas el SOS?', style: style.title),
              const SizedBox(height: 8),
              Text(
                'Elige hasta 3 personas. Recibirán tu ubicación por SMS, incluso sin internet.',
                style: TextStyle(color: style.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.sosSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: sosInk, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tu círculo de confianza',
                            style: TextStyle(
                              color: sosInk,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(3, (index) {
                        final contact = index < selected.length
                            ? selected[index]
                            : null;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                if (contact == null)
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.surface,
                                    foregroundColor: sosInk,
                                    child: Text(
                                      '${index + 1}',
                                      semanticsLabel:
                                          'Lugar disponible ${index + 1}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )
                                else
                                  ExcludeSemantics(
                                    child: SizedBox.square(
                                      dimension: 36,
                                      child: Stack(
                                        children: [
                                          CustomPaint(
                                            size: const Size.square(36),
                                            painter: _TrustPortrait(
                                              longHair: index.isEven,
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: CircleAvatar(
                                              radius: 7,
                                              backgroundColor: style.accent,
                                              foregroundColor: style.onAccent,
                                              child: const Icon(
                                                Icons.check,
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (contact != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    contact.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: style.ink,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tu agenda',
                style: TextStyle(
                  color: style.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),

              // Search bar
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: style.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: theme.muted, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _search = val),
                        decoration: const InputDecoration(
                          hintText: 'Buscar en tus contactos',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: filtered.map((c) {
                  final isSelected = state.contacts.contains(c.id);
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        state.contacts.remove(c.id);
                      } else if (state.contacts.length >= 3) {
                        state.toast(
                          'Máximo 3 contactos. Quita uno para elegir otro.',
                          icon: 'info',
                        );
                        return;
                      } else {
                        state.contacts.add(c.id);
                      }
                      setState(() {});
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: style.line)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: style.ink,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  c.phone,
                                  style: TextStyle(
                                    color: theme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? style.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? style.accent : style.line,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: style.onAccent,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (state.connected) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _addContactDialog(context),
                    style: TextButton.styleFrom(
                      foregroundColor: style.ink,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Agregar contacto con su celular'),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Footer buttons
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(top: BorderSide(color: style.line)),
          ),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await state.saveContacts();
                  if (isSetup) {
                    state.go('permisos');
                  } else {
                    state.back();
                    state.toast(
                      'Contactos de confianza guardados',
                      icon: 'check_circle',
                    );
                  }
                },
                style: style.primaryButton,
                icon: const Icon(Icons.arrow_forward, size: 18),
                iconAlignment: IconAlignment.end,
                label: Text(
                  '${isSetup ? "Continuar" : "Guardar"} · ${state.contacts.length} de 3',
                  textAlign: TextAlign.center,
                ),
              ),
              if (isSetup) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => state.go('permisos'),
                  child: Text(
                    'Lo hago después',
                    style: TextStyle(
                      color: theme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Decorative variants, independent of the contact's identity.
class _TrustPortrait extends CustomPainter {
  const _TrustPortrait({required this.longHair});

  final bool longHair;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 36, size.height / 36);
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 36, 36)));
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(18, 18), 18, paint);

    const hair = Color(0xFF263B65);
    final skin = longHair ? const Color(0xFFE9AC80) : const Color(0xFFB97654);
    paint.color = hair;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(18, 15),
        width: 18,
        height: longHair ? 23 : 18,
      ),
      paint,
    );
    if (longHair) canvas.drawCircle(const Offset(24, 8), 4, paint);
    paint.color = longHair ? const Color(0xFF627EA9) : hair;
    canvas.drawRRect(
      RRect.fromLTRBR(6, 24, 30, 40, const Radius.circular(9)),
      paint,
    );
    paint.color = skin;
    canvas.drawRRect(
      RRect.fromLTRBR(15, 20, 21, 27, const Radius.circular(2)),
      paint,
    );
    canvas.drawOval(const Rect.fromLTWH(11, 8, 14, 16), paint);
    paint.color = hair;
    canvas.drawArc(
      const Rect.fromLTWH(10, 6, 16, 12),
      3.14,
      3.14,
      false,
      paint,
    );
    canvas.drawCircle(const Offset(15.5, 16), 0.7, paint);
    canvas.drawCircle(const Offset(20.5, 16), 0.7, paint);
  }

  @override
  bool shouldRepaint(_TrustPortrait oldDelegate) =>
      oldDelegate.longHair != longHair;
}

// --- 5. Permisos Screen ---
class PermisosScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const PermisosScreen({super.key, required this.state, required this.theme});

  @override
  State<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends State<PermisosScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final style = _SetupStyle(theme);

    return Column(
      children: [
        _buildPdots(3, theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            children: [
              Text('Para cuidarte mejor', style: style.title),
              const SizedBox(height: 8),
              Text(
                'Nearby necesita estos permisos. Puedes cambiarlos cuando quieras.',
                style: TextStyle(color: style.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: style.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: style.panel,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 18,
                            color: style._light ? style.accent : style.onPanel,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ubicación y avisos de emergencia',
                              style: TextStyle(
                                color: style.onPanel,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _permRow(
                      style,
                      'loc',
                      Icons.location_on_outlined,
                      'Ubicación',
                      'Comparte tu ubicación en un SOS y descubre lo que hay cerca.',
                    ),
                    Divider(
                      height: 1,
                      color: style.line,
                      indent: 12,
                      endIndent: 12,
                    ),
                    _permRow(
                      style,
                      'notif',
                      Icons.notifications_none,
                      'Notificaciones',
                      'Recibe avisos cuando un vecino cercano pide ayuda.',
                    ),
                    Divider(
                      height: 1,
                      color: style.line,
                      indent: 12,
                      endIndent: 12,
                    ),
                    _permRow(
                      style,
                      'sms',
                      Icons.sms_outlined,
                      'Enviar SMS',
                      'Envía el SOS a tus contactos aunque no tengas internet.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: style.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _permRow(
                  style,
                  'ai',
                  Icons.auto_awesome,
                  'Red de rescate con IA',
                  'Opcional. Usa tus ofertas para sugerir ayuda. Puedes verlo y borrarlo en Perfil.',
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(top: BorderSide(color: style.line)),
          ),
          child: ElevatedButton.icon(
            onPressed: () => state.go('listo', reset: true),
            style: style.primaryButton,
            icon: const Icon(Icons.arrow_forward, size: 18),
            iconAlignment: IconAlignment.end,
            label: const Text('Continuar'),
          ),
        ),
      ],
    );
  }

  Widget _permRow(
    _SetupStyle style,
    String key,
    IconData icon,
    String title,
    String description,
  ) {
    final state = widget.state;
    final isAllowed = state.perms[key] ?? false;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              color: key == 'sms'
                  ? (style.theme.dark
                        ? NearbyColors.darkSosDark
                        : NearbyColors.sosDark)
                  : style.ink,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: style.ink,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: style.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isAllowed)
            Container(
              constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: style.soft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Listo',
                style: TextStyle(
                  color: style.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: () {
                state.perms[key] = true;
                if (key == 'ai') state.setAiConsent(true);
                setState(() {});
              },
              style: style.secondaryButton,
              child: const Text('Permitir'),
            ),
        ],
      ),
    );
  }
}

// --- 6. Listo Screen ---
class ListoScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ListoScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    return LayoutBuilder(
      builder: (context, bounds) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (bounds.maxHeight - 40).clamp(0.0, double.infinity),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: NearbyLogo(
                        width: 36,
                        inkColor: ui.ink,
                        greenColor: ui.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby',
                            style: TextStyle(
                              color: ui.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Siempre cerca para ayudar',
                            style: TextStyle(color: ui.muted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: ui.line),
                const SizedBox(height: 24),
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ui.blueSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomPaint(
                      size: const Size(double.infinity, 240),
                      painter: _ReadyDoorPainter(ui),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tu cuenta está lista',
                  style: TextStyle(
                    color: ui.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Bienvenida\nal barrio, ${state.firstName}!',
                  style: TextStyle(
                    color: ui.ink,
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(height: 1, color: ui.line),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ui.ivory,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: ui.ink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verificación vecinal',
                            style: TextStyle(
                              color: ui.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Un delegado de tu zona confirmará que eres vecina o vecino para darte la insignia de verificado.',
                            style: TextStyle(
                              color: ui.muted,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => state.go('home', reset: true),
                  style: ui.action(),
                  icon: const Icon(Icons.home_outlined, size: 19),
                  label: const Text('Ir al inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyDoorPainter extends CustomPainter {
  const _ReadyDoorPainter(this.ui);
  final NearbyCommunityStyle ui;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 300).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(
      (size.width - 300 * scale) / 2,
      (size.height - 220 * scale) / 2,
    );
    canvas.scale(scale);
    final paint = Paint()..color = ui.accent;
    canvas.drawCircle(const Offset(223, 64), 43, paint);
    paint.color = const Color(0xFFBFD0EC);
    canvas.drawRRect(
      RRect.fromLTRBR(79, 45, 209, 186, const Radius.circular(43)),
      paint,
    );
    paint.color = ui.panel;
    canvas.drawRRect(
      RRect.fromLTRBR(91, 59, 196, 186, const Radius.circular(34)),
      paint,
    );
    paint.color = const Color(0xFF516F9D);
    canvas.drawRRect(
      RRect.fromLTRBR(103, 70, 184, 185, const Radius.circular(26)),
      paint,
    );
    paint.color = const Color(0xFF7290BE);
    canvas.drawPath(
      Path()
        ..moveTo(103, 78)
        ..lineTo(144, 90)
        ..lineTo(144, 174)
        ..lineTo(103, 185)
        ..close(),
      paint,
    );
    paint.color = ui.accent;
    canvas.drawCircle(const Offset(137, 131), 2.5, paint);
    paint.color = const Color(0xFF182340);
    canvas.drawOval(const Rect.fromLTWH(148, 120, 27, 34), paint);
    paint.color = const Color(0xFFE2A47D);
    canvas.drawOval(const Rect.fromLTWH(153, 125, 17, 25), paint);
    paint.strokeWidth = 5;
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(174, 158), const Offset(184, 143), paint);
    paint.color = ui.accent;
    canvas.drawRRect(
      RRect.fromLTRBR(146, 148, 175, 183, const Radius.circular(9)),
      paint,
    );
    paint.color = ui.ink;
    canvas.drawLine(
      const Offset(80, 187),
      const Offset(209, 187),
      paint..strokeWidth = 3,
    );
    paint.color = ui.theme.surface;
    canvas.drawCircle(const Offset(222, 146), 23, paint);
    paint.color = ui.ink;
    canvas.drawLine(const Offset(212, 146), const Offset(219, 153), paint);
    canvas.drawLine(const Offset(219, 153), const Offset(232, 139), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ReadyDoorPainter oldDelegate) =>
      oldDelegate.ui.theme != ui.theme;
}
