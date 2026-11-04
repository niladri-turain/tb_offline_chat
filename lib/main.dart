import 'package:flutter/material.dart';

import 'data/chat_db.dart';
import 'data/identity.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Identity.load();
  await ChatDb.instance.open();
  runApp(const TbChatApp());
}

class TbChatApp extends StatelessWidget {
  const TbChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB Chat',
      debugShowCheckedModeBanner: false,
      theme: TB.theme(),
      home: const HomeShell(),
    );
  }
}
