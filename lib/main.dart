import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_vetor/app/routes/app_routes.dart';
import 'app/bindings/app_binding.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBfpC9XViZCx18UrfnEWL7YedyzEYc_ZmI",
      authDomain: "vetorwhatsapp280518.firebaseapp.com",
      projectId: "vetorwhatsapp280518",
      storageBucket: "vetorwhatsapp280518.firebasestorage.app",
      messagingSenderId: "744984685370",
      appId: "1:744984685370:web:6a6cb6d989e3de39f6be03",
      measurementId: "G-TJ1T2PPF79",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vetor WhatsApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      // O binding inicial injeta as dependências necessárias (ex.: AuthController)
      initialBinding: AppBinding(),
      // Define a rota inicial e as páginas disponíveis
      initialRoute: Routes.auth,
      getPages: AppPages.pages,
    );
  }
}