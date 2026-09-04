import 'dart:math';import 'package:flutter/material.dart';import '../models/models.dart';
class Particle{Offset p,v;double life;final Color color;Particle(this.p,this.v,this.life,this.color);}
class GameController extends ChangeNotifier{
 final LevelDef level;final int skin;final Random rnd=Random();Offset player=Offset.zero,velocity=Offset.zero;GravityDir gravity=GravityDir.down;
 bool dead=false,won=false,paused=false,core=false,shield=false,slow=false;double elapsed=0,shake=.0,portalCd=0,burst=.0;
 final Set<String> switches={},broken={},used={};final List<Particle> particles=[];
 static const ps=.035;
 GameController(this.level,this.skin){restart();}
 Rect get pr=>Rect.fromCenter(center:player,width:ps,height:ps);
 void restart(){player=level.spawn;velocity=Offset.zero;gravity=GravityDir.down;dead=won=paused=core=shield=slow=false;elapsed=shake=portalCd=burst=0;switches.clear();broken.clear();used.clear();particles.clear();notifyListeners();}
 void pause(){if(!dead&&!won){paused=!paused;notifyListeners();}}
 void grav(GravityDir d){if(dead||won||paused)return;if(!level.four&&(d==GravityDir.left||d==GravityDir.right))return;if(d==gravity)return;gravity=d;velocity*=.35;burst=.15;fx(player,const Color(0xFF51F3FF),12);}
 Rect platform(int i){final p=level.platforms[i],w=sin(elapsed*p.speed*pi*2)*p.range;return p.rect.shift(p.horizontal?Offset(w,0):Offset(0,w));}
 List<Rect> solids(){final a=<Rect>[];for(final o in level.objects){if(o.kind==ObjKind.wall)a.add(o.rect);if(o.kind==ObjKind.door&&!switches.contains(o.link))a.add(o.rect);if(o.kind==ObjKind.breakable&&!broken.contains(o.id))a.add(o.rect);}for(int i=0;i<level.platforms.length;i++)a.add(platform(i));return a;}
 void update(double dt){if(paused||won)return;dt=dt.clamp(0,.035);if(slow)dt*=.6;if(dead){parts(dt);notifyListeners();return;}elapsed+=dt;shake=max(0,shake-dt*4);portalCd=max(0,portalCd-dt);burst=max(0,burst-dt);
 Offset g=gravity==GravityDir.down?const Offset(0,1):gravity==GravityDir.up?const Offset(0,-1):gravity==GravityDir.left?const Offset(-1,0):const Offset(1,0);
 velocity+=g*.75*(burst>0?1.8:1)*dt;if(velocity.distance>.58)velocity=velocity/velocity.distance*.58;move(Offset(velocity.dx*dt,0));move(Offset(0,velocity.dy*dt));interact();laserHits();parts(dt);notifyListeners();}
 void move(Offset d){player+=d;var q=pr;for(final w in solids()){if(!q.overlaps(w))continue;if(d.dx>0)player=Offset(w.left-ps/2,player.dy);if(d.dx<0)player=Offset(w.right+ps/2,player.dy);if(d.dy>0)player=Offset(player.dx,w.top-ps/2);if(d.dy<0)player=Offset(player.dx,w.bottom+ps/2);if(d.dx!=0)velocity=Offset(0,velocity.dy);if(d.dy!=0)velocity=Offset(velocity.dx,0);q=pr;}}
 void interact(){for(final o in level.objects){if(!pr.inflate(.004).overlaps(o.rect))continue;switch(o.kind){
 case ObjKind.spike:hit();return;case ObjKind.exit:won=true;fx(o.rect.center,const Color(0xFF63FFAE),30);return;
 case ObjKind.core:if(!used.contains('core')){used.add('core');core=true;fx(o.rect.center,const Color(0xFFFFA043),20);}break;
 case ObjKind.switcher:switches.add(o.id);break;case ObjKind.breakable:broken.add(o.id);break;
 case ObjKind.shield:if(used.add('shield${o.rect}'))shield=true;break;case ObjKind.slow:if(used.add('slow${o.rect}'))slow=true;break;case ObjKind.burst:if(used.add('burst${o.rect}'))burst=.7;break;
 case ObjKind.portal:if(portalCd<=0){for(final t in level.objects){if(t.kind==ObjKind.portal&&t.id==o.link){player=t.rect.center;portalCd=.5;fx(player,const Color(0xFF9C63FF),18);break;}}}break;default:break;}}}
 bool laserOn(Laser l)=>((elapsed+l.phase)%l.cycle)<=l.on;
 void laserHits(){for(final l in level.lasers){if(!laserOn(l))continue;Rect b;if((l.a.dx-l.b.dx).abs()<.01)b=Rect.fromLTRB(l.a.dx-.008,min(l.a.dy,l.b.dy),l.a.dx+.008,max(l.a.dy,l.b.dy));else b=Rect.fromLTRB(min(l.a.dx,l.b.dx),l.a.dy-.008,max(l.a.dx,l.b.dx),l.a.dy+.008);if(pr.overlaps(b)){hit();return;}}}
 void hit(){if(shield){shield=false;shake=.7;velocity*=-.4;fx(player,const Color(0xFF51F3FF),20);return;}dead=true;velocity=Offset.zero;shake=1;fx(player,const Color(0xFFFF466D),32);}
 void fx(Offset p,Color c,int n){for(int i=0;i<n;i++){final a=rnd.nextDouble()*pi*2,s=.05+rnd.nextDouble()*.2;particles.add(Particle(p,Offset(cos(a)*s,sin(a)*s),.35+rnd.nextDouble()*.5,c));}}
 void parts(double dt){for(final p in particles){p.p+=p.v*dt;p.life-=dt;}particles.removeWhere((p)=>p.life<=0);}
}
