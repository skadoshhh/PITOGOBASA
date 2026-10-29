import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_wear/screens/product_list_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yayzdgylcyarseupakhs.supabase.co',
    anonKey: 'sb_publishable_qtrOxXh3gOG1akUGSF2BgA_VCBDupjW',
  );

  runApp(const AandMStreetwearApp());
}

class AandMStreetwearApp extends StatelessWidget {
  const AandMStreetwearApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A&Mstreetwear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: const Color(0xFF00E676),
      ),
      home: ProductListScreen(),
    );
  }
}