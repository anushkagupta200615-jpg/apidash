import 'package:apidash/consts.dart';
import 'package:apidash/screens/common_widgets/ai/ai_model_selector_button.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_consts.dart';

// Test helper that wraps a widget in a MaterialApp with test theme
Widget buildTestApp(Widget child) {
  return MaterialApp(
    theme: kThemeDataLight,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('AIModelSelectorButton', () {
    // ── Label tests ─────────────────────────────────────────────────────────

    testWidgets('shows kLabelSelectModel when aiRequestModel is null',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AIModelSelectorButton(aiRequestModel: null),
        ),
      );
      expect(find.text(kLabelSelectModel), findsOneWidget);
    });

    testWidgets('shows kLabelSelectModel when model is null', (tester) async {
      const model = AIRequestModel(
        modelApiProvider: ModelAPIProvider.openai,
        model: null,
      );
      await tester.pumpWidget(
        buildTestApp(AIModelSelectorButton(aiRequestModel: model)),
      );
      expect(find.text(kLabelSelectModel), findsOneWidget);
    });

    testWidgets(
        'shows kLabelSelectModel when model is empty string (bug fix #1479)',
        (tester) async {
      const model = AIRequestModel(
        modelApiProvider: ModelAPIProvider.openai,
        model: '',
      );
      await tester.pumpWidget(
        buildTestApp(AIModelSelectorButton(aiRequestModel: model)),
      );
      // Empty string should fall back to kLabelSelectModel (not show blank)
      expect(find.text(kLabelSelectModel), findsOneWidget);
      expect(find.text(''), findsNothing);
    });

    testWidgets('shows model name when model is set', (tester) async {
      const model = AIRequestModel(
        modelApiProvider: ModelAPIProvider.openai,
        model: 'gpt-4o',
      );
      await tester.pumpWidget(
        buildTestApp(AIModelSelectorButton(aiRequestModel: model)),
      );
      expect(find.text('gpt-4o'), findsOneWidget);
      expect(find.text(kLabelSelectModel), findsNothing);
    });

    // ── Icon tests ───────────────────────────────────────────────────────────

    testWidgets('shows add icon when no model is selected', (tester) async {
      await tester.pumpWidget(
        buildTestApp(AIModelSelectorButton(aiRequestModel: null)),
      );
      expect(
          find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('shows robot icon when model is selected', (tester) async {
      const model = AIRequestModel(
        modelApiProvider: ModelAPIProvider.gemini,
        model: 'gemini-2.0-flash',
      );
      await tester.pumpWidget(
        buildTestApp(AIModelSelectorButton(aiRequestModel: model)),
      );
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
    });

    // ── Readonly tests ───────────────────────────────────────────────────────

    testWidgets('button is disabled when readonly is true', (tester) async {
      const model = AIRequestModel(
        modelApiProvider: ModelAPIProvider.openai,
        model: 'gpt-4o',
      );
      await tester.pumpWidget(
        buildTestApp(
          AIModelSelectorButton(aiRequestModel: model, readonly: true),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('button is enabled when readonly is false', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AIModelSelectorButton(aiRequestModel: null, readonly: false),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    // ── Callback tests ───────────────────────────────────────────────────────

    testWidgets('onDialogOpen is called when button is tapped',
        (tester) async {
      bool dialogOpened = false;
      await tester.pumpWidget(
        buildTestApp(
          AIModelSelectorButton(
            aiRequestModel: null,
            onDialogOpen: () => dialogOpened = true,
            // Short-circuit dialog by using a fake dialog approach
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      // onDialogOpen is called before the dialog opens
      expect(dialogOpened, isTrue);
    });
  });

  // ── Unit tests for label logic ─────────────────────────────────────────────

  group('AIModelSelectorButton label logic', () {
    test('isNotEmpty guard: null model → shows placeholder', () {
      const AIRequestModel? aiRequest = null;
      final hasModel = aiRequest?.model?.isNotEmpty == true;
      expect(hasModel, isFalse);
    });

    test('isNotEmpty guard: empty string model → shows placeholder', () {
      const aiRequest = AIRequestModel(model: '');
      final hasModel = aiRequest.model?.isNotEmpty == true;
      expect(hasModel, isFalse);
    });

    test('isNotEmpty guard: valid model → shows model name', () {
      const aiRequest = AIRequestModel(model: 'gpt-4o');
      final hasModel = aiRequest.model?.isNotEmpty == true;
      expect(hasModel, isTrue);
    });

    test('isNotEmpty guard: whitespace-only model → shows model name',
        () {
      // Note: whitespace is technically "not empty"; trimming is a
      // separate concern. This test documents the current behavior.
      const aiRequest = AIRequestModel(model: '   ');
      final hasModel = aiRequest.model?.isNotEmpty == true;
      expect(hasModel, isTrue); // whitespace is not empty per isNotEmpty
    });
  });
}
