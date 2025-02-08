// lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import '../screens/auth_wrapper.dart';
import '../screens/app_bar_screen.dart';
import '../screens/login_screen.dart';
import '../screens/whatsapp_chat_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    // Página que decide qual tela exibir com base na autenticação
    GetPage(
      name: Routes.auth,
      page: () => const AuthWrapper(),
    ),
    // Tela principal com Bottom Navigation
    GetPage(
      name: Routes.home,
      page: () => const AppBarScreen(),
    ),
    // Tela de login (caso queira acessá-la diretamente)
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
    ),
    // Tela de chat (caso queira acessar de forma independente)
    GetPage(
      name: Routes.chat,
      page: () => const WhatsAppChatScreen(),
    ),
  ];
}