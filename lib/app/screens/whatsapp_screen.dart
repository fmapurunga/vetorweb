// lib/app/screens/whatsapp_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../screens/whatsapp_chat_screen.dart';
import '../controllers/whatsapp_controller.dart';
import 'package:get/get.dart';

class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen({super.key}); // Uso do super.key

  @override
  WhatsAppScreenState createState() => WhatsAppScreenState();
}

class WhatsAppScreenState extends State<WhatsAppScreen> {
  // Aqui, em vez de instanciar diretamente, o ideal é utilizar o Get.find
  final WhatsAppController whatsAppController = Get.find<WhatsAppController>();
  
  Client? selectedClient; // Armazena a conversa ativa

  @override
  Widget build(BuildContext context) {
    bool isDesktop = kIsWeb;
    // Ajusta o tamanho da tela do chat com base na largura da tela
    whatsAppController.tamanhoDaTelaChat.value =
        MediaQuery.of(context).size.width - whatsAppController.tamanhoDaTelaLista.value;
    
    return isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context);
  }

  PreferredSizeWidget _appBar() {
    final TextEditingController search = TextEditingController();
    return AppBar(
      toolbarHeight: 90,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                flex: 15,
                child: Icon(Icons.menu, color: Colors.grey),
              ),
              const Expanded(
                flex: 70,
                child: Center(child: Text("Conversas", style: TextStyle(color: Colors.grey))),
              ),
              Expanded(
                flex: 15,
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.grey),
                  onPressed: () {
                    _showNewConversationDialog();
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Expanded(flex: 10, child: SizedBox()),
              Expanded(
                flex: 80,
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Pesquisar...',
                  ),
                ),
              ),
              const Expanded(flex: 10, child: SizedBox())
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: whatsAppController.tamanhoDaTelaLista.value,
          child: _buildMobileLayout(context),
        ),
        const VerticalDivider(width: 2, color: Colors.grey),
        Expanded(
          child: Obx(() {
            if (whatsAppController.client.value.id.isEmpty) {
              return const Center(child: Text("Nenhuma conversa selecionada"));
            } else {
              return const WhatsAppChatScreen();
            }
          }),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _buildConversationsList(context),
    );
  }

  Widget _buildConversationsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: whatsAppController.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhuma conversa disponível'));
        }
        var conversations = snapshot.data!.docs;
        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            var conversation = conversations[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              title: Text(conversation['nome'] ?? 'Sem nome', overflow: TextOverflow.clip),
              subtitle: Text('${conversation['lastMessage'] ?? 'Sem mensagens'}',
                  overflow: TextOverflow.ellipsis, maxLines: 1),
              onTap: () {
                Client newClient = Client(
                  id: conversation.id,
                  nome: conversation['nome'],
                  foto: conversation['foto'],
                  ultimaMensagem: conversation['lastMessage'],
                  ultimaMensagemData: DateTime.now(),
                );
                whatsAppController.client.value = newClient;
                if (!kIsWeb) {
                  Get.to(() => const WhatsAppChatScreen());
                }
              },
            );
          },
        );
      },
    );
  }

  void _showNewConversationDialog() {
    // Exemplo simples de diálogo para nova conversa
    // Implemente a lógica conforme sua necessidade
    Get.dialog(AlertDialog(
      title: const Text("Iniciar Nova Conversa"),
      content: const Text("Implementar diálogo para nova conversa."),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () {
            // Lógica para iniciar nova conversa
            Get.back();
          },
          child: const Text("Iniciar"),
        ),
      ],
    ));
  }
}