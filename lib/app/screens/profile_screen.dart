// lib/app/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenha os controllers injetados via GetX (certifique-se de que eles foram registrados no AppBinding)
    final ProfileController profileController = Get.find<ProfileController>();
    final AuthController authController = Get.find<AuthController>();
    final TextEditingController nameController = TextEditingController();

    // Carrega os dados do perfil (pode ser chamado também no onInit do controller)
    profileController.loadUserName();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            // Atualiza o text field com o nome atual
            nameController.text = profileController.userName.value;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 350,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      bool success = await profileController
                          .updateUserName(nameController.text.trim());
                      if (success) {
                        Get.snackbar("Sucesso", "Perfil atualizado com sucesso!",
                            snackPosition: SnackPosition.BOTTOM);
                      } else {
                        Get.snackbar("Erro", "Erro ao atualizar perfil",
                            snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text(
                      'SALVAR',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await authController.logout();
                      // Volta para a tela de autenticação
                      Get.offAllNamed('/auth');
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text(
                      'SAIR',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}