import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'game_engine.dart';

void main() {
  runApp(const StarfallApp());
}

class StarfallApp extends StatelessWidget {
  const StarfallApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF071219);
    return MaterialApp(
      title: 'Starfall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5AE6D0),
          brightness: Brightness.dark,
          surface: background,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GameEngine _game = GameEngine();
  late final Ticker _ticker;
  Duration? _lastFrame;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame)..start();
  }

  void _onFrame(Duration elapsed) {
    final previous = _lastFrame;
    _lastFrame = elapsed;
    if (previous == null || !mounted) return;
    final delta =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    setState(() => _game.update(delta));
  }

  void _restart() {
    setState(_game.restart);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 15, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GameHeader(),
              const SizedBox(height: 20),
              _Scoreboard(score: _game.score, lives: _game.lives),
              const SizedBox(height: 14),
              Expanded(child: _gameField()),
              const SizedBox(height: 13),
              const _GameFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _game.resize(Size(constraints.maxWidth, constraints.maxHeight));
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF263C46)),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _game.movePlayer(details.localPosition),
              onPanStart: (details) => _game.movePlayer(details.localPosition),
              onPanUpdate: (details) => _game.movePlayer(details.localPosition),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _SpacePainter(_game)),
                  Positioned(
                    top: 15,
                    left: 16,
                    child: _FieldReadout(score: _game.score),
                  ),
                  if (_game.isGameOver)
                    _GameOver(score: _game.score, onRestart: _restart),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF31515A)),
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF10242B),
          ),
          child: const Icon(
            Icons.change_history,
            color: Color(0xFF5AE6D0),
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STARFALL',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'DEEP SPACE DEFENSE',
                style: TextStyle(
                  color: Color(0xFF8EA5AC),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const _OnlineIndicator(),
      ],
    );
  }
}

class _OnlineIndicator extends StatelessWidget {
  const _OnlineIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF5AE6D0),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        const Text(
          'ONLINE',
          style: TextStyle(
            color: Color(0xFF9BB1B5),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.score, required this.lives});

  final int score;
  final int lives;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF21343C)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('SCORE'),
                const SizedBox(height: 3),
                Text(
                  score.toString().padLeft(5, '0'),
                  style: const TextStyle(
                    color: Color(0xFFF1F5EA),
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF263C46)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('HULL INTEGRITY'),
                  const SizedBox(height: 7),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: EdgeInsets.only(right: index == 2 ? 0 : 9),
                        child: Icon(
                          Icons.favorite,
                          size: 17,
                          color: index < lives
                              ? const Color(0xFFFF786F)
                              : const Color(0xFF34444A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8EA5AC),
        fontSize: 9,
        fontFamily: 'monospace',
      ),
    );
  }
}

class _FieldReadout extends StatelessWidget {
  const _FieldReadout({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sensors, color: Color(0xFF5AE6D0), size: 14),
        const SizedBox(width: 6),
        Text(
          'SECTOR 01  /  WAVE ${(score ~/ 500 + 1).toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Color(0xFF9BB1B5),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _GameFooter extends StatelessWidget {
  const _GameFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.radar, size: 15, color: Color(0xFF5AE6D0)),
        SizedBox(width: 8),
        Text(
          'SECTOR 01',
          style: TextStyle(
            color: Color(0xFFD4E1DE),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        Spacer(),
        Text(
          'THREAT LEVEL: ACTIVE',
          style: TextStyle(
            color: Color(0xFF8EA5AC),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _GameOver extends StatelessWidget {
  const _GameOver({required this.score, required this.onRestart});

  final int score;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6071219),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF786F),
                size: 38,
              ),
              const SizedBox(height: 12),
              const Text(
                'SHIP LOST',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'FINAL SCORE',
                style: TextStyle(
                  color: Color(0xFF8EA5AC),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                score.toString().padLeft(5, '0'),
                style: const TextStyle(
                  color: Color(0xFF5AE6D0),
                  fontSize: 28,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay),
                label: const Text('REDEPLOY'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5AE6D0),
                  foregroundColor: const Color(0xFF071219),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpacePainter extends CustomPainter {
  _SpacePainter(this.game);

  final GameEngine game;
  static final List<_Star> _stars = _createStars();

  static List<_Star> _createStars() {
    final random = math.Random(37);
    return List.generate(
      86,
      (_) => _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 1.15 + 0.35,
        speed: random.nextDouble() * 22 + 8,
        alpha: random.nextDouble() * 0.55 + 0.25,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1A23), Color(0xFF071219), Color(0xFF0B1D25)],
          stops: [0, 0.58, 1],
        ).createShader(bounds),
    );

    for (final star in _stars) {
      final y =
          (star.y * size.height + game.elapsedSeconds * star.speed) %
          size.height;
      final twinkle =
          0.72 + 0.28 * math.sin(game.elapsedSeconds * 2 + star.x * 18);
      canvas.drawCircle(
        Offset(star.x * size.width, y),
        star.radius,
        Paint()
          ..color = const Color(0xFFD9F6E8)
              .withValues(alpha: star.alpha * twinkle),
      );
    }

    for (final bolt in game.bolts) {
      final rect = Rect.fromCenter(center: bolt.position, width: 3, height: 17);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..color = const Color(0xFF5AE6D0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = const Color(0xFFE4FFF5),
      );
    }

    for (final enemy in game.enemies) {
      _drawEnemy(canvas, enemy);
    }
    for (final particle in game.particles) {
      canvas.drawCircle(
        particle.position,
        particle.radius,
        Paint()..color = particle.color.withValues(alpha: particle.opacity),
      );
    }
    _drawPlayer(canvas, game.playerPosition, game.elapsedSeconds);
  }

  void _drawPlayer(Canvas canvas, Offset center, double elapsed) {
    final flame = 8 + 4 * math.sin(elapsed * 24);
    final exhaust = Path()
      ..moveTo(center.dx - 5, center.dy + 13)
      ..lineTo(center.dx, center.dy + 13 + flame)
      ..lineTo(center.dx + 5, center.dy + 13)
      ..close();
    canvas.drawPath(exhaust, Paint()..color = const Color(0xFFFFA363));

    final ship = Path()
      ..moveTo(center.dx, center.dy - 20)
      ..lineTo(center.dx + 8, center.dy + 11)
      ..lineTo(center.dx + 3, center.dy + 8)
      ..lineTo(center.dx, center.dy + 12)
      ..lineTo(center.dx - 3, center.dy + 8)
      ..lineTo(center.dx - 8, center.dy + 11)
      ..close();
    canvas.drawPath(ship, Paint()..color = const Color(0xFF5AE6D0));
    canvas.drawPath(
      ship,
      Paint()
        ..color = const Color(0xFFC7FFF0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 4),
        width: 4,
        height: 8,
      ),
      Paint()..color = const Color(0xFFE5FFFA),
    );
  }

  void _drawEnemy(Canvas canvas, GameEnemy enemy) {
    final center = enemy.position;
    final radius = enemy.radius;
    final color = enemy.variant == 0
        ? const Color(0xFFFF786F)
        : const Color(0xFFFFB45E);
    final ship = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.64, center.dy - radius * 0.18)
      ..lineTo(center.dx - radius * 1.08, center.dy - radius * 0.36)
      ..lineTo(center.dx - radius * 0.42, center.dy - radius * 0.44)
      ..lineTo(center.dx, center.dy - radius * 0.82)
      ..lineTo(center.dx + radius * 0.42, center.dy - radius * 0.44)
      ..lineTo(center.dx + radius * 1.08, center.dy - radius * 0.36)
      ..lineTo(center.dx + radius * 0.64, center.dy - radius * 0.18)
      ..close();
    canvas.drawPath(
      ship,
      Paint()
        ..color = color.withValues(alpha: 0.17)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(ship, Paint()..color = color);
    canvas.drawPath(
      ship,
      Paint()
        ..color = const Color(0xFFFFE1BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.24),
      2.2,
      Paint()..color = const Color(0xFF351E26),
    );
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) => true;
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double alpha;
}
