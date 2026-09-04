import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/ui.dart';

Rect R(double x, double y, double w, double h) => Rect.fromLTWH(x, y, w, h);

GObj O(ObjKind k, double x, double y, double w, double h,
    {String id = '', String link = ''}) =>
    GObj(k, R(x, y, w, h), id: id, link: link);

Laser L(double x1, double y1, double x2, double y2,
    {double cycle = 2, double on = 1, double phase = 0}) =>
    Laser(Offset(x1, y1), Offset(x2, y2), cycle: cycle, on: on, phase: phase);

PlatformDef P(double x, double y, double w, double h, bool hor, double range,
    double speed) => PlatformDef(R(x, y, w, h), hor, range, speed);

List<GObj> frame() =>
    [
      O(ObjKind.wall, 0, 0, 1, .025),
      O(ObjKind.wall, 0, .975, 1, .025),
      O(ObjKind.wall, 0, 0, .025, 1),
      O(ObjKind.wall, .975, 0, .025, 1)
    ];

LevelDef make(int n, String name, String zone, Color c,
    {bool four = false, bool boss = false}) {
  final variant = n % 10;

  final objs = <GObj>[
    ...frame(),
    O(ObjKind.wall, .05, .88, .90, .035),
    O(
      ObjKind.exit,
      .84,
      variant.isEven ? .15 : .77,
      .09,
      .10,
    ),
  ];
  final lasers = <Laser>[];
  final platforms = <PlatformDef>[];
  if (n > 1) objs.add(
      O(ObjKind.spike, .28 + (variant % 3) * .08, .855, .12, .025));
  if (n % 3 == 0) objs.add(O(ObjKind.core, .47, .17, .06, .06));
  if (n % 4 == 0) lasers.add(
      L(.52, .23, .52, .80, cycle: 1.6 + (n % 3) * .25, on: .72));
  if (n % 5 == 0) {
    objs.add(O(ObjKind.switcher, .13, .14, .08, .05, id: 's'));
    objs.add(O(ObjKind.door, .72, .56, .035, .32, link: 's'));
  }
  if (n % 6 == 0) platforms.add(P(
      .36,
      .62,
      .18,
      .035,
      n % 2 == 0,
      .18,
      .30 + (n % 4) * .05));
  if (n % 7 == 0) {
    objs.add(O(ObjKind.portal, .18, .77, .08, .08, id: 'a', link: 'b'));
    objs.add(O(ObjKind.portal, .72, .18, .08, .08, id: 'b', link: 'a'));
  }
  if (n % 8 == 0) objs.add(O(ObjKind.shield, .18, .77, .07, .07));
  if (n % 9 == 0) objs.add(O(ObjKind.breakable, .42, .48, .20, .035, id: 'br'));
  if (n >= 21 && n % 4 == 1) objs.add(O(ObjKind.burst, .18, .76, .07, .07));
  if (n >= 31 && n % 3 == 1) objs.add(O(ObjKind.slow, .62, .76, .07, .07));
  if (boss) {
    lasers.add(L(.28, .20, .28, .80, cycle: 1.4, on: .65));
    lasers.add(L(.72, .20, .72, .80, cycle: 1.4, on: .65, phase: .7));
    objs.add(O(ObjKind.core, .47, .47, .06, .06));
  }
  return LevelDef(
      n, name, zone, c, const Offset(.10, .82), objs, lasers: lasers,
      platforms: platforms,
      par: 10 + n * .55,
      four: four,
      boss: boss);
}

final names = [
  'FIRST FLIP',
  'CEILING WALK',
  'CORE SAMPLE',
  'THE GAP',
  'RED LINE',
  'MOVING DAY',
  'GLASS TEETH',
  'LOCK & FLIP',
  'CRUMBLE',
  'LAB OVERRIDE',
  'HEAT ENTRY',
  'PULSE SHAFT',
  'LIFT BURN',
  'DOUBLE PULSE',
  'SAFETY OFF',
  'COOLANT RUN',
  'SHIELD TEST',
  'REACTOR BRIDGE',
  'MELT CHANNEL',
  'REACTOR HEART',
  'SIDEWAYS',
  'WALL RUN',
  'PORTAL PAIR',
  'CROSS FIRE',
  'GRAVITY LOCK',
  'ORBIT ROOM',
  'BURST',
  'PORTAL MAZE',
  'ZERO TEETH',
  'VOID ENGINE',
  'ALARM',
  'FALLING GRID',
  'HOT PORTAL',
  'PANIC LIFT',
  'TRIPLE BEAM',
  'LAST SHIELD',
  'BROKEN CORE',
  'NO FLOOR',
  'FINAL CORRIDOR',
  'MELTDOWN CORE'
];
final List<LevelDef> levels = List.generate(40, (i) {
  final n = i + 1;
  final z = n <= 10 ? 'THE LAB' : n <= 20 ? 'REACTOR' : n <= 30
      ? 'ZERO SECTOR'
      : 'MELTDOWN';
  final c = n <= 10 ? cyan : n <= 20 ? orange : n <= 30 ? purple : red;
  return make(n, names[i], z, c, four: n >= 21, boss: n % 10 == 0);
});
