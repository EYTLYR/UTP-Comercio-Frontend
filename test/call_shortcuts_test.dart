import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/widgets/common_widgets.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Poppins',
    )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
  });
  for (final width in [360.0, 390.0]) {
    for (final scale in [1.0, 1.4, 2.0]) {
      testWidgets('SOS shortcuts align at width $width and text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = AppState();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Poppins'),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: EmergencyCallShortcuts(state: state),
                  ),
                ),
              ),
            ),
          ),
        );
        final rects = ['105', '116', '106']
            .map(
              (number) =>
                  tester.getRect(find.byKey(ValueKey('sos-call-$number'))),
            )
            .toList();
        for (final rect in rects.skip(1)) {
          expect(rect.top, rects.first.top);
          expect(rect.height, closeTo(rects.first.height, .01));
          expect(rect.width, closeTo(rects.first.width, .01));
        }
        expect(rects[1].left - rects[0].right, closeTo(8, .01));
        final label = tester.widget<Text>(find.text('Bomberos'));
        expect(label.maxLines, 1);
        expect(label.softWrap, isFalse);
        if (scale <= 1.4) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text('Bomberos'),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      });
    }
  }
}
