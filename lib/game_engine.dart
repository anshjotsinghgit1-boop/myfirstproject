import 'dart:math';
import 'dart:ui';

class GameEngine {
  GameEngine({int? seed}) : _random = Random(seed);

  final Random _random;
  final List<GameEnemy> enemies = [];
  final List<GameBolt> bolts = [];
  final List<GameParticle> particles = [];

  Size _viewport = Size.zero;
  Offset playerPosition = Offset.zero;
  double elapsedSeconds = 0;
  double _spawnTimer = 0.45;
  double _fireTimer = 0;
  int score = 0;
  int lives = 3;
  bool isGameOver = false;

  void resize(Size size) {
    if (size.isEmpty || size == _viewport) return;
    final hadViewport = !_viewport.isEmpty;
    final oldSize = _viewport;
    _viewport = size;
    if (!hadViewport || playerPosition == Offset.zero) {
      playerPosition = Offset(size.width / 2, size.height - 54);
    } else {
      movePlayer(
        Offset(
          playerPosition.dx * size.width / oldSize.width,
          playerPosition.dy * size.height / oldSize.height,
        ),
      );
    }
  }

  void movePlayer(Offset position) {
    if (_viewport.isEmpty || isGameOver) return;
    final horizontalInset = min(24.0, _viewport.width / 2);
    final topLimit = min(_viewport.height * 0.52, _viewport.height - 35);
    playerPosition = Offset(
      position.dx.clamp(horizontalInset, _viewport.width - horizontalInset),
      position.dy.clamp(topLimit, _viewport.height - 30),
    );
  }

  void update(double deltaSeconds) {
    if (_viewport.isEmpty || isGameOver) return;
    final delta = deltaSeconds.clamp(0.0, 0.05).toDouble();
    elapsedSeconds += delta;
    _spawnTimer -= delta;
    _fireTimer -= delta;

    final spawnInterval = max(0.42, 0.96 - score / 7000);
    if (_spawnTimer <= 0) {
      _spawnEnemy();
      _spawnTimer = spawnInterval;
    }
    if (_fireTimer <= 0) {
      bolts.add(GameBolt(Offset(playerPosition.dx, playerPosition.dy - 20)));
      _fireTimer = 0.27;
    }

    _moveBolts(delta);
    _moveEnemies(delta);
    _moveParticles(delta);
  }

  void restart() {
    enemies.clear();
    bolts.clear();
    particles.clear();
    score = 0;
    lives = 3;
    elapsedSeconds = 0;
    _spawnTimer = 0.45;
    _fireTimer = 0;
    isGameOver = false;
    if (!_viewport.isEmpty) {
      playerPosition = Offset(_viewport.width / 2, _viewport.height - 54);
    }
  }

  void _spawnEnemy() {
    final edge = min(30.0, _viewport.width / 2);
    enemies.add(
      GameEnemy(
        position: Offset(
          edge + _random.nextDouble() * (_viewport.width - edge * 2),
          -24,
        ),
        radius: 14 + _random.nextDouble() * 8,
        speed: 80 + _random.nextDouble() * 44 + score / 90,
        variant: _random.nextInt(2),
        drift: (_random.nextDouble() - 0.5) * 36,
      ),
    );
  }

  void _moveBolts(double delta) {
    for (var boltIndex = bolts.length - 1; boltIndex >= 0; boltIndex--) {
      final bolt = bolts[boltIndex];
      bolt.position = Offset(bolt.position.dx, bolt.position.dy - 430 * delta);
      if (bolt.position.dy < -20) {
        bolts.removeAt(boltIndex);
        continue;
      }

      for (var enemyIndex = enemies.length - 1; enemyIndex >= 0; enemyIndex--) {
        final enemy = enemies[enemyIndex];
        if ((enemy.position - bolt.position).distance < enemy.radius + 4) {
          bolts.removeAt(boltIndex);
          enemies.removeAt(enemyIndex);
          score += 100;
          _burst(enemy.position, const Color(0xFFFFA363));
          break;
        }
      }
    }
  }

  void _moveEnemies(double delta) {
    for (var index = enemies.length - 1; index >= 0; index--) {
      final enemy = enemies[index];
      enemy.position = Offset(
        (enemy.position.dx + enemy.drift * delta)
            .clamp(enemy.radius, _viewport.width - enemy.radius),
        enemy.position.dy + enemy.speed * delta,
      );

      if ((enemy.position - playerPosition).distance < enemy.radius + 13 ||
          enemy.position.dy > _viewport.height + enemy.radius) {
        enemies.removeAt(index);
        _loseLife(enemy.position);
        if (isGameOver) return;
      }
    }
  }

  void _moveParticles(double delta) {
    for (var index = particles.length - 1; index >= 0; index--) {
      final particle = particles[index];
      particle.position += particle.velocity * delta;
      particle.remaining -= delta;
      if (particle.remaining <= 0) particles.removeAt(index);
    }
  }

  void _loseLife(Offset at) {
    lives--;
    _burst(at, const Color(0xFFFF786F));
    if (lives <= 0) isGameOver = true;
  }

  void _burst(Offset position, Color color) {
    for (var index = 0; index < 9; index++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 35 + _random.nextDouble() * 100;
      particles.add(
        GameParticle(
          position: position,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: color,
        ),
      );
    }
  }
}

class GameEnemy {
  GameEnemy({
    required this.position,
    required this.radius,
    required this.speed,
    required this.variant,
    required this.drift,
  });

  Offset position;
  final double radius;
  final double speed;
  final int variant;
  final double drift;
}

class GameBolt {
  GameBolt(this.position);

  Offset position;
}

class GameParticle {
  GameParticle({required this.position, required this.velocity, required this.color});

  Offset position;
  final Offset velocity;
  final Color color;
  double remaining = 0.36;
  static const double lifespan = 0.36;

  double get opacity => (remaining / lifespan).clamp(0.0, 1.0).toDouble();
  double get radius => 1.5 + opacity * 1.6;
}