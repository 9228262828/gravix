import 'dart:convert'; import 'package:flutter/foundation.dart'; import 'package:shared_preferences/shared_preferences.dart'; import '../models/models.dart';
class ProgressStore extends ChangeNotifier{
 final Map<int,LevelResult> results={}; int skin=0;bool shake=true,sound=true;
 int get stars=>results.values.fold(0,(a,b)=>a+b.stars);
 int get unlocked{int u=1;for(int i=1;i<=40;i++){if((results[i]?.stars??0)>0)u=(i+1).clamp(1,40);}return u;}
 Future<void> load()async{final p=await SharedPreferences.getInstance();try{final m=jsonDecode(p.getString('gx_progress')??'{}') as Map<String,dynamic>;for(final e in m.entries)results[int.parse(e.key)]=LevelResult.fromJson(Map<String,dynamic>.from(e.value));}catch(_){}
 skin=p.getInt('gx_skin')??0;shake=p.getBool('gx_shake')??true;sound=p.getBool('gx_sound')??true;notifyListeners();}
 Future<void> save(int n,LevelResult r)async{final o=results[n];results[n]=LevelResult(o==null?r.stars:(o.stars>r.stars?o.stars:r.stars),o==null||o.time==0||r.time<o.time?r.time:o.time,(o?.core??false)||r.core);await _persist();}
 Future<void> setSkin(int v)async{skin=v;final p=await SharedPreferences.getInstance();await p.setInt('gx_skin',v);notifyListeners();}
 Future<void> setShake(bool v)async{shake=v;final p=await SharedPreferences.getInstance();await p.setBool('gx_shake',v);notifyListeners();}
 Future<void> setSound(bool v)async{sound=v;final p=await SharedPreferences.getInstance();await p.setBool('gx_sound',v);notifyListeners();}
 Future<void> reset()async{results.clear();skin=0;final p=await SharedPreferences.getInstance();await p.remove('gx_progress');await p.remove('gx_skin');notifyListeners();}
 Future<void> _persist()async{final p=await SharedPreferences.getInstance();await p.setString('gx_progress',jsonEncode(results.map((k,v)=>MapEntry('$k',v.toJson()))));notifyListeners();}
}
