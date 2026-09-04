import 'dart:math';

import 'package:flutter/material.dart';

import '../models/models.dart';

class Particle {
 Offset p;
 Offset v;
 double life;
 final Color color;

 Particle(
     this.p,
     this.v,
     this.life,
     this.color,
     );
}

class GameController extends ChangeNotifier {
 final LevelDef level;
 final int skin;
 final Random rnd = Random();

 Offset player = Offset.zero;
 Offset velocity = Offset.zero;

 GravityDir gravity = GravityDir.down;

 bool dead = false;
 bool won = false;
 bool paused = false;
 bool core = false;
 bool shield = false;
 bool slow = false;

 double elapsed = 0;
 double shake = 0;
 double portalCd = 0;
 double burst = 0;

 // Horizontal movement input:
 // -1 = left
 //  0 = idle
 //  1 = right
 double moveInput = 0;

 final Set<String> switches = {};
 final Set<String> broken = {};
 final Set<String> used = {};

 final List<Particle> particles = [];

 static const double ps = .035;

 static const double gravityAcceleration = .75;
 static const double maxGravitySpeed = .58;

 static const double moveAcceleration = 1.35;
 static const double moveMaxSpeed = .30;
 static const double moveFriction = 1.8;

 GameController(
     this.level,
     this.skin,
     ) {
  restart();
 }

 Rect get pr => Rect.fromCenter(
  center: player,
  width: ps,
  height: ps,
 );

 void restart() {
  player = level.spawn;
  velocity = Offset.zero;

  gravity = GravityDir.down;

  dead = false;
  won = false;
  paused = false;

  core = false;
  shield = false;
  slow = false;

  elapsed = 0;
  shake = 0;
  portalCd = 0;
  burst = 0;

  moveInput = 0;

  switches.clear();
  broken.clear();
  used.clear();
  particles.clear();

  notifyListeners();
 }

 void pause() {
  if (dead || won) return;

  paused = !paused;

  if (paused) {
   moveInput = 0;
  }

  notifyListeners();
 }

 // ============================
 // PLAYER MOVEMENT
 // ============================

 void moveLeft() {
  if (dead || won || paused) return;

  moveInput = -1;
 }

 void moveRight() {
  if (dead || won || paused) return;

  moveInput = 1;
 }

 void stopMove() {
  moveInput = 0;
 }

 // ============================
 // GRAVITY
 // ============================

 void grav(GravityDir d) {
  if (dead || won || paused) return;

  if (!level.four &&
      (d == GravityDir.left ||
          d == GravityDir.right)) {
   return;
  }

  if (d == gravity) return;

  gravity = d;

  velocity *= .35;

  burst = .15;

  fx(
   player,
   const Color(0xFF51F3FF),
   12,
  );

  notifyListeners();
 }

 // ============================
 // MOVING PLATFORM
 // ============================

 Rect platform(int i) {
  final p = level.platforms[i];

  final wave =
      sin(elapsed * p.speed * pi * 2) *
          p.range;

  return p.rect.shift(
   p.horizontal
       ? Offset(wave, 0)
       : Offset(0, wave),
  );
 }

 // ============================
 // SOLID OBJECTS
 // ============================

 List<Rect> solids() {
  final result = <Rect>[];

  for (final o in level.objects) {
   if (o.kind == ObjKind.wall) {
    result.add(o.rect);
   }

   if (o.kind == ObjKind.door &&
       !switches.contains(o.link)) {
    result.add(o.rect);
   }

   if (o.kind == ObjKind.breakable &&
       !broken.contains(o.id)) {
    result.add(o.rect);
   }
  }

  for (int i = 0;
  i < level.platforms.length;
  i++) {
   result.add(
    platform(i),
   );
  }

  return result;
 }

 // ============================
 // GAME LOOP
 // ============================

 void update(double dt) {
  if (paused || won) return;

  dt = dt.clamp(
   0.0,
   .035,
  );

  if (slow) {
   dt *= .6;
  }

  if (dead) {
   parts(dt);
   notifyListeners();
   return;
  }

  elapsed += dt;

  shake = max(
   0,
   shake - dt * 4,
  );

  portalCd = max(
   0,
   portalCd - dt,
  );

  burst = max(
   0,
   burst - dt,
  );

  // ============================
  // GRAVITY VECTOR
  // ============================

  Offset gravityVector;

  switch (gravity) {
   case GravityDir.down:
    gravityVector =
    const Offset(0, 1);
    break;

   case GravityDir.up:
    gravityVector =
    const Offset(0, -1);
    break;

   case GravityDir.left:
    gravityVector =
    const Offset(-1, 0);
    break;

   case GravityDir.right:
    gravityVector =
    const Offset(1, 0);
    break;
  }

  velocity += gravityVector *
      gravityAcceleration *
      (burst > 0 ? 1.8 : 1) *
      dt;

  // ============================
  // RUN LEFT / RIGHT
  // ============================

  if (gravity == GravityDir.down ||
      gravity == GravityDir.up) {
   double horizontalSpeed =
       velocity.dx;

   if (moveInput != 0) {
    horizontalSpeed +=
        moveInput *
            moveAcceleration *
            dt;

    horizontalSpeed =
        horizontalSpeed.clamp(
         -moveMaxSpeed,
         moveMaxSpeed,
        );
   } else {
    // Smooth friction
    final amount =
        moveFriction * dt;

    if (horizontalSpeed.abs() <=
        amount) {
     horizontalSpeed = 0;
    } else if (horizontalSpeed > 0) {
     horizontalSpeed -= amount;
    } else {
     horizontalSpeed += amount;
    }
   }

   velocity = Offset(
    horizontalSpeed,
    velocity.dy,
   );
  }

  // ============================
  // WHEN GRAVITY IS SIDEWAYS
  // ============================

  if (gravity == GravityDir.left ||
      gravity == GravityDir.right) {
   double verticalSpeed =
       velocity.dy;

   if (moveInput != 0) {
    verticalSpeed +=
        moveInput *
            moveAcceleration *
            dt;

    verticalSpeed =
        verticalSpeed.clamp(
         -moveMaxSpeed,
         moveMaxSpeed,
        );
   } else {
    final amount =
        moveFriction * dt;

    if (verticalSpeed.abs() <=
        amount) {
     verticalSpeed = 0;
    } else if (verticalSpeed > 0) {
     verticalSpeed -= amount;
    } else {
     verticalSpeed += amount;
    }
   }

   velocity = Offset(
    velocity.dx,
    verticalSpeed,
   );
  }

  // ============================
  // LIMIT TOTAL SPEED
  // ============================

  const double maxTotalSpeed = .65;

  if (velocity.distance >
      maxTotalSpeed) {
   velocity =
       velocity /
           velocity.distance *
           maxTotalSpeed;
  }

  // ============================
  // PHYSICS + COLLISION
  // ============================

  move(
   Offset(
    velocity.dx * dt,
    0,
   ),
  );

  move(
   Offset(
    0,
    velocity.dy * dt,
   ),
  );

  interact();
  laserHits();
  parts(dt);

  notifyListeners();
 }

 // ============================
 // COLLISION MOVEMENT
 // ============================

 void move(Offset d) {
  player += d;

  var q = pr;

  for (final wall in solids()) {
   if (!q.overlaps(wall)) {
    continue;
   }

   if (d.dx > 0) {
    player = Offset(
     wall.left - ps / 2,
     player.dy,
    );
   }

   if (d.dx < 0) {
    player = Offset(
     wall.right + ps / 2,
     player.dy,
    );
   }

   if (d.dy > 0) {
    player = Offset(
     player.dx,
     wall.top - ps / 2,
    );
   }

   if (d.dy < 0) {
    player = Offset(
     player.dx,
     wall.bottom + ps / 2,
    );
   }

   if (d.dx != 0) {
    velocity = Offset(
     0,
     velocity.dy,
    );
   }

   if (d.dy != 0) {
    velocity = Offset(
     velocity.dx,
     0,
    );
   }

   q = pr;
  }
 }

 // ============================
 // GAME OBJECT INTERACTION
 // ============================

 void interact() {
  for (final o in level.objects) {
   if (!pr
       .inflate(.004)
       .overlaps(o.rect)) {
    continue;
   }

   switch (o.kind) {
    case ObjKind.spike:
     hit();
     return;

    case ObjKind.exit:
     won = true;
     moveInput = 0;

     fx(
      o.rect.center,
      const Color(0xFF63FFAE),
      30,
     );

     return;

    case ObjKind.core:
     if (!used.contains('core')) {
      used.add('core');

      core = true;

      fx(
       o.rect.center,
       const Color(0xFFFFA043),
       20,
      );
     }

     break;

    case ObjKind.switcher:
     if (switches.add(o.id)) {
      fx(
       o.rect.center,
       const Color(0xFF63FFAE),
       14,
      );
     }

     break;

    case ObjKind.breakable:
     if (broken.add(o.id)) {
      fx(
       o.rect.center,
       const Color(0xFFFFA043),
       14,
      );
     }

     break;

    case ObjKind.shield:
     if (used.add(
      'shield${o.rect}',
     )) {
      shield = true;

      fx(
       o.rect.center,
       const Color(0xFF51F3FF),
       18,
      );
     }

     break;

    case ObjKind.slow:
     if (used.add(
      'slow${o.rect}',
     )) {
      slow = true;

      fx(
       o.rect.center,
       const Color(0xFF9C63FF),
       18,
      );
     }

     break;

    case ObjKind.burst:
     if (used.add(
      'burst${o.rect}',
     )) {
      burst = .7;

      fx(
       o.rect.center,
       const Color(0xFFFFA043),
       20,
      );
     }

     break;

    case ObjKind.portal:
     if (portalCd <= 0) {
      for (final t
      in level.objects) {
       if (t.kind ==
           ObjKind.portal &&
           t.id == o.link) {
        player =
            t.rect.center;

        velocity *= .45;

        portalCd = .5;

        fx(
         player,
         const Color(
          0xFF9C63FF,
         ),
         18,
        );

        break;
       }
      }
     }

     break;

    default:
     break;
   }
  }
 }

 // ============================
 // LASERS
 // ============================

 bool laserOn(Laser l) {
  return ((elapsed + l.phase) %
      l.cycle) <=
      l.on;
 }

 void laserHits() {
  for (final l in level.lasers) {
   if (!laserOn(l)) continue;

   Rect beam;

   if ((l.a.dx - l.b.dx).abs() <
       .01) {
    beam = Rect.fromLTRB(
     l.a.dx - .008,
     min(
      l.a.dy,
      l.b.dy,
     ),
     l.a.dx + .008,
     max(
      l.a.dy,
      l.b.dy,
     ),
    );
   } else {
    beam = Rect.fromLTRB(
     min(
      l.a.dx,
      l.b.dx,
     ),
     l.a.dy - .008,
     max(
      l.a.dx,
      l.b.dx,
     ),
     l.a.dy + .008,
    );
   }

   if (pr.overlaps(beam)) {
    hit();
    return;
   }
  }
 }

 // ============================
 // DAMAGE
 // ============================

 void hit() {
  if (dead) return;

  if (shield) {
   shield = false;

   shake = .7;

   velocity *= -.4;

   fx(
    player,
    const Color(0xFF51F3FF),
    20,
   );

   return;
  }

  dead = true;

  moveInput = 0;

  velocity = Offset.zero;

  shake = 1;

  fx(
   player,
   const Color(0xFFFF466D),
   32,
  );
 }

 // ============================
 // PARTICLES
 // ============================

 void fx(
     Offset p,
     Color c,
     int n,
     ) {
  for (int i = 0;
  i < n;
  i++) {
   final angle =
       rnd.nextDouble() *
           pi *
           2;

   final speed =
       .05 +
           rnd.nextDouble() *
               .2;

   particles.add(
    Particle(
     p,
     Offset(
      cos(angle) * speed,
      sin(angle) * speed,
     ),
     .35 +
         rnd.nextDouble() *
             .5,
     c,
    ),
   );
  }
 }

 void parts(double dt) {
  for (final p in particles) {
   p.p += p.v * dt;

   p.v *= .985;

   p.life -= dt;
  }

  particles.removeWhere(
       (p) => p.life <= 0,
  );
 }
}