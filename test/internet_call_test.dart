import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utp_comercio_frontend/api/api_client.dart';
import 'package:utp_comercio_frontend/services/internet_call.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('incoming call does not open microphone and can be rejected', () async {
    final requests = <String>[];
    final call = InternetCall(
      api: ApiClient(
        client: MockClient((request) async {
          requests.add(request.url.path);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'call-1',
                  'callerName': 'Ana',
                  'conversationId': 'conversation',
                  'offer': 'private-sdp',
                  'state': 'RINGING',
                },
              ]),
              200,
            );
          }
          return http.Response('', 200);
        }),
      ),
    );
    expect(await call.checkIncoming(), isTrue);
    expect(call.phase, 'incoming');
    expect(call.rendererReady, isFalse);
    await call.end();
    expect(call.phase, 'ended');
    expect(requests, ['/api/v1/calls', '/api/v1/calls/call-1/end']);
    expect(await call.checkIncoming(), isFalse);
    call.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(requests.where((p) => p.endsWith('/end')).length, 1);
  });
}
