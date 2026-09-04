import 'package:flutter/material.dart';
enum GravityDir{down,up,left,right}
enum ObjKind{wall,spike,exit,core,switcher,door,portal,breakable,shield,slow,burst}
class GObj{final ObjKind kind;final Rect rect;final String id,link;const GObj(this.kind,this.rect,{this.id='',this.link=''});}
class Laser{final Offset a,b;final double cycle,on,phase;const Laser(this.a,this.b,{this.cycle=2,this.on=1,this.phase=0});}
class PlatformDef{final Rect rect;final bool horizontal;final double range,speed;const PlatformDef(this.rect,this.horizontal,this.range,this.speed);}
class LevelDef{final int n;final String name,zone;final Color accent;final Offset spawn;final List<GObj> objects;final List<Laser> lasers;final List<PlatformDef> platforms;final double par;final bool four,boss;
 const LevelDef(this.n,this.name,this.zone,this.accent,this.spawn,this.objects,{this.lasers=const[],this.platforms=const[],this.par=15,this.four=false,this.boss=false});}
class LevelResult{final int stars;final double time;final bool core;const LevelResult(this.stars,this.time,this.core);
 Map<String,dynamic> toJson()=>{'stars':stars,'time':time,'core':core};
 factory LevelResult.fromJson(Map<String,dynamic>j)=>LevelResult(j['stars']??0,(j['time']??0).toDouble(),j['core']??false);}
