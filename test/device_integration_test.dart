import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utp_comercio_frontend/api/api_client.dart';
import 'package:utp_comercio_frontend/api/mappers.dart';
import 'package:utp_comercio_frontend/services/device_actions.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/widgets/common_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'SMS requests use shared API and preserve server resend interval',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/otp/request');
          expect(jsonDecode(request.body), {'phone': '987654321'});
          return http.Response(
            '{"expiresInSeconds":300,"resendInSeconds":45,"devCode":"654321"}',
            202,
          );
        }),
      );
      final state = AppState(api: api)..phoneDraft = '987654321';
      expect(await state.requestOtp(), isTrue);
      expect(state.otpResendSeconds, 45);
      expect(state.otpDevCode, '654321');
      state.dispose();
    },
  );
  test('wrong OTP stays rejected by backend', () async {
    final api = ApiClient(
      client: MockClient(
        (request) async => http.Response.bytes(
          utf8.encode('{"detail":"Código incorrecto","code":"OTP_INVALID"}'),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final state = AppState(api: api)..phoneDraft = '987654321';
    expect(await state.verifyOtp('123456'), isNotNull);
    expect(state.connected, isFalse);
    state.dispose();
  });
  test('map preserves actual server coordinates', () {
    final pin = Api2App.pin({
      'id': 'pin',
      'lat': -12.04,
      'lng': -77.03,
      'title': 'Ayuda',
    });
    expect(pin.latitude, -12.04);
    expect(pin.longitude, -77.03);
  });
  test(
    'emergency call delegates to system without dialing during tests',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DeviceActions.channel, (call) async {
            calls.add(call);
            return true;
          });
      final actions = DeviceActions();
      expect(await actions.call('105', emergency: true), isTrue);
      expect(calls.single.arguments, {'number': '105', 'emergency': true});
      expect(
        await actions.call('Vecino sin número', emergency: false),
        isFalse,
      );
      expect(calls.length, 1);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DeviceActions.channel, null);
    },
  );
  testWidgets('bottom notices show remaining time and dismiss on swipe', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: state,
            builder: (_, _) => Stack(
              children: [
                const SizedBox.expand(),
                if (state.toastMessage != null)
                  NearbyToastWidget(
                    key: ValueKey(state.toastId),
                    message: state.toastMessage!,
                    onDismiss: state.dismissToast,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    state.toast('Aviso de prueba');
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
    await tester.pump(const Duration(milliseconds: 1400));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(.5, .02),
    );
    await tester.drag(find.text('Aviso de prueba'), const Offset(700, 0));
    await tester.pumpAndSettle();
    expect(state.toastMessage, isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
