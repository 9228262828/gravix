import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/controller.dart';
import '../game/painter.dart';
import '../models/models.dart';
import '../services/progress_store.dart';
import '../widgets/ui.dart';
import 'level_clear_screen.dart';

class GameScreen extends StatefulWidget {
 final ProgressStore store;
 final LevelDef level;

 const GameScreen({
  super.key,
  required this.store,
  required this.level,
 });

 @override
 State<GameScreen> createState() => _G();
}

class _G extends State<GameScreen>
    with SingleTickerProviderStateMixin {
 late GameController g;
 late Ticker t;

 Duration last = Duration.zero;

 bool done = false;

 @override
 void initState() {
  super.initState();

  g = GameController(
   widget.level,
   widget.store.skin,
  );

  t = createTicker(tick)..start();
 }

 void tick(Duration n) {
  if (last == Duration.zero) {
   last = n;
   return;
  }

  final dt =
      (n - last).inMicroseconds / 1000000.0;

  last = n;

  g.update(dt);

  if (g.won && !done) {
   done = true;

   Future.delayed(
    const Duration(milliseconds: 350),
    finish,
   );
  }

  if (mounted) {
   setState(() {});
  }
 }

 Future<void> finish() async {
  int stars = 1;

  if (g.elapsed <= widget.level.par) {
   stars++;
  }

  if (g.core) {
   stars++;
  }

  final result = LevelResult(
   stars,
   g.elapsed,
   g.core,
  );

  await widget.store.save(
   widget.level.n,
   result,
  );

  if (!mounted) return;

  Navigator.pushReplacement(
   context,
   MaterialPageRoute(
    builder: (_) => LevelClearScreen(
     store: widget.store,
     level: widget.level,
     result: result,
    ),
   ),
  );
 }

 @override
 void dispose() {
  g.stopMove();

  t.dispose();
  g.dispose();

  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  final dx =
  widget.store.shake && g.shake > 0
      ? sin(g.elapsed * 90) *
      g.shake *
      5
      : 0.0;

  return Scaffold(
   body: SafeArea(
    child: Column(
     children: [
      // ==============================
      // TOP BAR
      // ==============================

      Padding(
       padding:
       const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
       ),
       child: Row(
        children: [
         IconButton(
          onPressed: () {
           g.stopMove();

           Navigator.pop(
            context,
           );
          },
          icon: const Icon(
           Icons.close,
          ),
         ),

         Expanded(
          child: Text(
           '${widget.level.n.toString().padLeft(2, '0')}'
               ' // '
               '${widget.level.name}',
           style: const TextStyle(
            fontWeight:
            FontWeight.w900,
           ),
          ),
         ),

         Text(
          '${g.elapsed.toStringAsFixed(1)}s',
          style: const TextStyle(
           color: cyan,
           fontWeight:
           FontWeight.w900,
          ),
         ),

         IconButton(
          onPressed: () {
           g.stopMove();
           g.pause();
          },
          icon: Icon(
           g.paused
               ? Icons
               .play_arrow_rounded
               : Icons
               .pause_rounded,
          ),
         ),
        ],
       ),
      ),

      // ==============================
      // GAME AREA
      // ==============================

      Expanded(
       child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
         10,
         4,
         10,
         8,
        ),
        child: Transform.translate(
         offset: Offset(
          dx,
          0,
         ),
         child: ClipRRect(
          borderRadius:
          BorderRadius.circular(
           18,
          ),
          child: Stack(
           children: [
            Positioned.fill(
             child: CustomPaint(
              painter:
              GamePainter(g),
             ),
            ),

            if (g.paused)
             overlay(
              'PAUSED',
              'RESUME',
                  () {
               g.stopMove();
               g.pause();
              },
              cyan,
              Icons
                  .play_arrow_rounded,
             ),

            if (g.dead)
             overlay(
              'SYSTEM FAILURE',
              'RETRY',
                  () {
               g.stopMove();

               g.restart();

               done = false;
              },
              red,
              Icons
                  .restart_alt_rounded,
             ),
           ],
          ),
         ),
        ),
       ),
      ),

      // ==============================
      // STATUS
      // ==============================

      Padding(
       padding:
       const EdgeInsets.symmetric(
        horizontal: 14,
       ),
       child: Row(
        children: [
         Icon(
          g.core
              ? Icons
              .diamond_rounded
              : Icons
              .diamond_outlined,
          size: 15,
          color: g.core
              ? orange
              : muted,
         ),

         const SizedBox(width: 5),

         Text(
          g.core
              ? 'CORE SECURED'
              : 'CORE OPTIONAL',
          style: TextStyle(
           color: g.core
               ? orange
               : muted,
           fontSize: 9,
           fontWeight:
           FontWeight.w900,
          ),
         ),

         if (g.shield) ...[
          const SizedBox(
           width: 14,
          ),
          const Icon(
           Icons.shield_rounded,
           size: 14,
           color: cyan,
          ),
          const SizedBox(
           width: 4,
          ),
          const Text(
           'SHIELD',
           style: TextStyle(
            color: cyan,
            fontSize: 9,
            fontWeight:
            FontWeight.w900,
           ),
          ),
         ],

         if (g.slow) ...[
          const SizedBox(
           width: 14,
          ),
          const Icon(
           Icons
               .hourglass_bottom_rounded,
           size: 14,
           color: purple,
          ),
          const SizedBox(
           width: 4,
          ),
          const Text(
           'SLOW',
           style: TextStyle(
            color: purple,
            fontSize: 9,
            fontWeight:
            FontWeight.w900,
           ),
          ),
         ],
        ],
       ),
      ),

      const SizedBox(height: 8),

      // ==============================
      // RUN CONTROLS
      // ==============================

      movementControls(),

      const SizedBox(height: 9),

      // ==============================
      // GRAVITY CONTROLS
      // ==============================

      gravityControls(),

      const SizedBox(height: 12),
     ],
    ),
   ),
  );
 }

 // =========================================
 // MOVEMENT CONTROLS
 // =========================================

 Widget movementControls() {
  return Padding(
   padding:
   const EdgeInsets.symmetric(
    horizontal: 14,
   ),
   child: Row(
    children: [
     Expanded(
      child: movementButton(
       icon:
       Icons.arrow_back_rounded,
       label: 'RUN LEFT',
       onStart: g.moveLeft,
      ),
     ),

     const SizedBox(width: 10),

     Container(
      width: 72,
      height: 62,
      decoration: BoxDecoration(
       color:
       panel.withOpacity(.75),
       borderRadius:
       BorderRadius.circular(
        18,
       ),
       border: Border.all(
        color:
        orange.withOpacity(.25),
       ),
      ),
      child: const Column(
       mainAxisAlignment:
       MainAxisAlignment.center,
       children: [
        Icon(
         Icons
             .directions_run_rounded,
         color: orange,
         size: 23,
        ),
        SizedBox(height: 3),
        Text(
         'MOVE',
         style: TextStyle(
          color: muted,
          fontSize: 7,
          fontWeight:
          FontWeight.w900,
          letterSpacing: 1,
         ),
        ),
       ],
      ),
     ),

     const SizedBox(width: 10),

     Expanded(
      child: movementButton(
       icon:
       Icons.arrow_forward_rounded,
       label: 'RUN RIGHT',
       onStart: g.moveRight,
      ),
     ),
    ],
   ),
  );
 }

 Widget movementButton({
  required IconData icon,
  required String label,
  required VoidCallback onStart,
 }) {
  return Listener(
   behavior:
   HitTestBehavior.opaque,

   // يبدأ الجري بمجرد الضغط
   onPointerDown: (_) {
    onStart();
   },

   // يقف عند رفع الإصبع
   onPointerUp: (_) {
    g.stopMove();
   },

   onPointerCancel: (_) {
    g.stopMove();
   },

   child: Container(
    height: 62,
    decoration: BoxDecoration(
     color: panel,
     borderRadius:
     BorderRadius.circular(
      18,
     ),
     border: Border.all(
      color:
      cyan.withOpacity(.42),
      width: 1.3,
     ),
     boxShadow: [
      BoxShadow(
       color:
       cyan.withOpacity(.04),
       blurRadius: 12,
      ),
     ],
    ),
    child: Row(
     mainAxisAlignment:
     MainAxisAlignment.center,
     children: [
      Icon(
       icon,
       color: cyan,
       size: 27,
      ),

      const SizedBox(width: 7),

      Text(
       label,
       style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight:
        FontWeight.w900,
        letterSpacing: .5,
       ),
      ),
     ],
    ),
   ),
  );
 }

 // =========================================
 // GRAVITY CONTROLS
 // =========================================

 Widget gravityControls() {
  Widget gravityButton(
      GravityDir direction,
      IconData icon,
      ) {
   final selected =
       g.gravity == direction;

   return Expanded(
    child: SizedBox(
     height: 54,
     child: OutlinedButton(
      onPressed: () {
       g.grav(direction);
      },
      style:
      OutlinedButton.styleFrom(
       backgroundColor: selected
           ? widget.level.accent
           .withOpacity(.12)
           : panel.withOpacity(.35),
       side: BorderSide(
        color: selected
            ? widget.level.accent
            : muted.withOpacity(
         .25,
        ),
        width: selected
            ? 1.6
            : 1,
       ),
       shape:
       RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
         16,
        ),
       ),
      ),
      child: Icon(
       icon,
       size: 27,
       color: selected
           ? widget.level.accent
           : Colors.white,
      ),
     ),
    ),
   );
  }

  return Padding(
   padding:
   const EdgeInsets.symmetric(
    horizontal: 14,
   ),
   child: Row(
    children: [
     if (widget.level.four) ...[
      gravityButton(
       GravityDir.left,
       Icons
           .keyboard_double_arrow_left_rounded,
      ),
      const SizedBox(width: 7),
     ],

     gravityButton(
      GravityDir.up,
      Icons
          .keyboard_double_arrow_up_rounded,
     ),

     const SizedBox(width: 7),

     gravityButton(
      GravityDir.down,
      Icons
          .keyboard_double_arrow_down_rounded,
     ),

     if (widget.level.four) ...[
      const SizedBox(width: 7),
      gravityButton(
       GravityDir.right,
       Icons
           .keyboard_double_arrow_right_rounded,
      ),
     ],
    ],
   ),
  );
 }

 // =========================================
 // PAUSE / DEATH OVERLAY
 // =========================================

 Widget overlay(
     String title,
     String button,
     VoidCallback action,
     Color color,
     IconData icon,
     ) {
  return Positioned.fill(
   child: Container(
    color:
    voidC.withOpacity(.86),
    child: Center(
     child: Padding(
      padding:
      const EdgeInsets.all(
       30,
      ),
      child: Column(
       mainAxisSize:
       MainAxisSize.min,
       children: [
        NeonTitle(
         title,
         size: 28,
        ),

        const SizedBox(
         height: 18,
        ),

        GButton(
         button,
         icon,
         action,
         color: color,
        ),
       ],
      ),
     ),
    ),
   ),
  );
 }
}