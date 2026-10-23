import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/screens/camera/scan_result.dart';
import 'package:safepill_frontend/screens/camera/scan_mode.dart';
import 'package:safepill_frontend/services/ocr_registration_api.dart';
import 'package:safepill_frontend/services/vision_api.dart';
import 'medication_preview_flow_test.dart' show PreviewApi;

class RegistrationApi extends OcrRegistrationApi {
  int calls = 0;
  @override
  Future<List<OcrRegisteredItem>> registerSelections(
    List<OcrRegistrationSelection> selections,
  ) async {
    calls++;
    return [];
  }
}

void main() {
  testWidgets('recognized candidate also waits for preview confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = PreviewApi();
    final registration = RegistrationApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultScreen(
          mode: ScanMode.pill,
          imageBytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF7sAAAAASUVORK5CYII=',
          ),
          pillCandidates: [
            PillIdentifyCandidate(
              pillName: '촬영 제품',
              itemId: 1,
              itemType: 'MEDICINE',
              confidence: 0.9,
            ),
          ],
          prescriptionItems: const [],
          medicationApi: api,
          ocrRegistrationApi: registration,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('촬영 제품'));
    await tester.pumpAndSettle();
    expect(find.text('등록 전 성분 확인'), findsOneWidget);
    expect(registration.calls, 0);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(registration.calls, 0);
    await tester.tap(find.text('촬영 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인 후 등록'));
    await tester.pumpAndSettle();
    expect(registration.calls, 1);
  });
}
