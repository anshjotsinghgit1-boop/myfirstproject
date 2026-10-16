// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_defense/game_engine.dart';
import 'package:orbit_defense/main.dart';

void main() {
  testWidgets('shows the game HUD and accepts steering input', (tester) async {
    await tester.pumpWidget(const StarfallApp());
    await tester.pump(const Duration(milliseconds: 32));

    expect(find.text('STARFALL'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('00000'), findsOneWidget);

    await tester.drag(find.byType(GameScreen), const Offset(40, -20));
    await tester.pump(const Duration(milliseconds: 32));
    expect(tester.takeException(), isNull);
  });

  test('game state resets when redeployed', () {
    final game = GameEngine(seed: 1)..resize(const Size(360, 640));
    game.update(0.05);
    game.update(0.05);
    game.movePlayer(const Offset(90, 400));
    game.restart();

    expect(game.score, 0);
    expect(game.lives, 3);
    expect(game.isGameOver, isFalse);
    expect(game.enemies, isEmpty);
    expect(game.bolts, isEmpty);
    expect(game.playerPosition, const Offset(180, 586));
  });
}
