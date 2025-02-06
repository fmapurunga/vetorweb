import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_vetor/models/client.dart';
import 'package:whatsapp_vetor/screens/whatsapp_chat_screen.dart';
import '../controllers/whatsapp_controller.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';


class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen({super.key});

  @override
  _WhatsAppScreenState createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  final WhatsAppController whatsAppController = WhatsAppController();
  Client? selectedClient; // 🔹 Armazena a conversa ativa

  @override
  Widget build(BuildContext context) {
    bool isDesktop = kIsWeb;
    whatsAppController.tamanhoDaTelaChat = MediaQuery.of(context).size.width - whatsAppController.tamanhoDaTelaLista;
    return Scaffold(
      body: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context, true),
    );
  }

  PreferredSizeWidget _appBar() {
    TextEditingController search = TextEditingController();
    return AppBar(
      toolbarHeight: 90,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 5,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(flex: 15, child: Icon(Icons.menu, color: Colors.grey,),),
              const Expanded(flex: 70, child: Center(child: Text("Conversas", style: TextStyle(color: Colors.grey),))),
              Expanded(flex: 15, child: IconButton(icon: const Icon(Icons.add, color: Colors.grey,), onPressed: (){
                _showNewConversationDialog(context, whatsAppController);
              }))
            ],
          ),
          const SizedBox(height: 5,),
          Row(
            children: [
              Expanded(flex: 10, child: Container(),),
              Expanded(flex: 80, 
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Pesquisar...',
                  ),
                  maxLines: 1,
                  //onSubmitted: ,
                ),
              ),
              Expanded(flex: 10, child: Container(),)
            ]
          ),
          const SizedBox(height: 2,),
        ]
      ),
    );
  }
  

  /// 🔹 Layout Desktop (Lista de conversas à esquerda e chat à direita)
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // 🔹 Coluna da Lista de Conversas com Largura Fixa (300px)
        SizedBox(
          width: whatsAppController.tamanhoDaTelaLista, // Largura fixa para a coluna da lista de conversas
          child: _buildMobileLayout(context, false),
        ),
        SizedBox(
          width: 2,
          child: Container(color: Colors.grey,),
        ),
        // 🔹 Coluna da Conversa (Chat) Ocupa o Resto do Espaço
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return selectedClient == null
                  ? const Center(child: Text("Nenhuma conversa selecionada"))
                  : WhatsAppChatScreen(whatsAppController: whatsAppController);
            },
          ),
        ),
      ],
    );
  }

  /// 🔹 Layout Mobile (Lista de conversas)
  Widget _buildMobileLayout(BuildContext context, bool isMobile) {
    return Scaffold(
      appBar: _appBar(),
      body: _buildConversationsList(isMobile: isMobile, context: context),
    );
  }

  /// 🔹 Lista de Conversas (Puxa do Firestore)
  Widget _buildConversationsList({bool isMobile = false, BuildContext? context}) {
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
                radius: 25,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              title: Text(conversation['nome'] ?? 'Sem nome', overflow: TextOverflow.clip,),
              subtitle: Text('${conversation['lastMessage'] ?? 'Sem mensagens'}', overflow: TextOverflow.ellipsis, maxLines: 1,),
              onTap: () {
                Client newClient = Client(
                  id: conversation.id,
                  nome: conversation['nome'],
                  foto: conversation['foto'],
                  ultimaMensagem: conversation['lastMessage'],
                  ultimaMensagemData: DateTime.now(),
                );

                whatsAppController.cliente = newClient;
                whatsAppController.getMessages();

                if (isMobile) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WhatsAppChatScreen(whatsAppController: whatsAppController),
                    ),
                  );
                } else {
                  // 🔹 Atualiza a tela no Desktop sem abrir uma nova
                  setState(() {
                    selectedClient = newClient;
                  });
                }
              },
            );
          },
        );
      },
    );
  }
}
void _showNewConversationDialog(BuildContext context, WhatsAppController wc) {
  final phoneController = MaskedTextController(mask: '(00)0.0000-0000');
  final messageController = TextEditingController();
  final nameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Iniciar Nova Conversa"),
        content: SizedBox(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Digite o nome",
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20,),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Digite o número do telefone",
                  hintText: "(86)99999-9999",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20,),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: "Digite a mensagem",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                keyboardType: TextInputType.phone,
              ),
            ]
          )
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              String telefone = phoneController.text;
              String ddd = telefone.substring(1,3);
              String numeroRadical = telefone.substring(6,10)+telefone.substring(11,15);
              String numero = '55$ddd$numeroRadical';
              wc.sendMessage(numero, messageController.text, nameController.text, "", "text", "");
              Navigator.pop(context);
            },
            child: const Text("Iniciar"),
          ),
        ],
      );
    },
  );
}