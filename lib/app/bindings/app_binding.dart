// lib/app/bindings/app_binding.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/whatsapp_controller.dart';
import '../controllers/media_cache_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<WhatsAppController>(() => WhatsAppController());
    Get.lazyPut<MediaCacheController>(() => MediaCacheController());
  }
}