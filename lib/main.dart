import 'package:flutter/material.dart';
import 'app.dart';
import 'services/progress_store.dart';
Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); final s=ProgressStore(); await s.load(); runApp(GravixApp(store:s)); }
