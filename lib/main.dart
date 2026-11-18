import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_start.dart';
import 'core/di/locator.dart';
import 'data/auth.dart';
import 'data/chat_db.dart';
import 'data/identity.dart';
import 'data/prefs.dart';
import 'providers/auth_provider.dart';
import 'theme.dart';
import 'widgets/app_toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  await Auth.load();
  await Identity.load();
  await Prefs.load();
  await ChatDb.instance.open();
  runApp(TbChatApp(start: await appStart()));
}

class TbChatApp extends StatelessWidget {
  const TbChatApp({super.key, required this.start});

  final Widget start;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: locator<AuthProvider>(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'TB Chat',
        debugShowCheckedModeBanner: false,
        theme: TB.theme(),
        home: start,
      ),
    );
  }
}
