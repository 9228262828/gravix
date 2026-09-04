import 'package:flutter/material.dart';
import 'services/progress_store.dart';
import 'screens/splash_screen.dart';
import 'widgets/ui.dart';
class GravixApp extends StatelessWidget {
 final ProgressStore store; const GravixApp({super.key,required this.store});
 @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'GRAVIX',
 theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:voidC,colorScheme:ColorScheme.fromSeed(seedColor:cyan,brightness:Brightness.dark)),
 home:SplashScreen(store:store));
}
