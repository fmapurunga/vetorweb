// app/controllers/whatsapp_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;

class WhatsAppController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  /// Armazena as mensagens mais recentes.
  RxList<DocumentSnapshot> messages = RxList<DocumentSnapshot>();

  // Cliente ativo reativo
  var client = Client(
    id: "",
    nome: "",
    foto: "",
    ultimaMensagem: "",
    ultimaMensagemData: DateTime.now(),
  ).obs;

  // Variáveis reativas para tamanhos (se necessário)
  var tamanhoDaTelaChat = 400.0.obs;
  var tamanhoDaTelaLista = 300.0.obs;

  // Constantes (token e phoneNumberId) podem permanecer como atributos finais
  final String token =
      "EAAQ7haJGEJYBOxrPlCSpEeXkq93LXwRIsZB6iGqCYItq8fXAqrl8cjkG8XSpWPNUY9IS7pkhvs4BiUfZAGSPG5G9RsAMVkBKmLGuVajaqjVVElEUeiS21AB9EROJnmCS9nAChgORxOqxZARpDwfMdb2IZAzhV4nKCUnD60XfH3cddbw6kgqtufNKrmZCCNYZBlpAZDZD";
  final String phoneNumberId = "577900678729878";

  Uint8List? imageData;
  ScrollController scrollMsgs = ScrollController();

  /// Obtém a stream das conversas ordenadas pela última mensagem
  Stream<QuerySnapshot> getConversations() {
    return _firestore
        .collection("chats")
        .orderBy("lastMessageTime", descending: true)
        .snapshots();
  }

  /// Obtém a stream das mensagens do cliente ativo
  Stream<QuerySnapshot> getMessages() {
    if (client.value.id.isNotEmpty) {
      return _firestore
          .collection("chats")
          .doc(client.value.id)
          .collection("messages")
          .orderBy("timestamp", descending: false)
          .snapshots();
    }
    return const Stream.empty();
  }

  /// Envia mensagem para o cliente
  Future<void> sendMessage(
    String clienteId,
    String message,
    String nome,
    String foto,
    String type,
    String mediaUrl,
  ) async {
    // Salva a mensagem na coleção global "messages"
    DocumentReference messageRef = _firestore.collection("messages").doc();
    await messageRef.set({
      "clienteId": clienteId,
      "text": (mediaUrl != "") ? "" : message,
      "sender": "empresa",
      "timestamp": FieldValue.serverTimestamp(),
      "status": "pending",
      "type": type,
      "mediaUrl": mediaUrl,
    });

    String lastMsg = message;
    if (type == "image") {
      lastMsg = "foto";
    } else if (type == "video") {
      lastMsg = "video";
    } else if (type == "audio") {
      lastMsg = "audio";
    } else if (type == "sticker") {
      lastMsg = "sticker";
    } else if (type == "location") {
      lastMsg = "localização";
    }

    try {
      await _firestore
          .collection("chats")
          .doc(clienteId)
          .collection("messages")
          .doc(messageRef.id)
          .set({
        "sender": "empresa",
        "text": (mediaUrl != "") ? "" : message,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "pending",
        "type": type,
        "mediaUrl": mediaUrl,
      });
      // Atualiza a última mensagem na coleção "chats"
      await _firestore.collection("chats").doc(clienteId).set({
        "lastMessage": lastMsg,
        "lastMessageTime": FieldValue.serverTimestamp(),
        "foto": foto,
        "nome": nome
      }, SetOptions(merge: true));
    } catch (e) {
      Get.snackbar("Erro", "Erro ao enviar mensagem: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Faz upload de arquivo (imagem, vídeo, áudio, doc, etc.)
  Future<void> uploadFile(XFile file, String fileType, String mensagem) async {
    String path = "";
    if (fileType == "image") {
      path = "images";
    } else if (fileType == "video") {
      path = "videos";
    } else if (fileType == "audio") {
      path = "audio";
    } else if (fileType == "sticker") {
      path = "sticker";
    } else if (fileType == "doc") {
      path = "docs";
    }
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}';
      String? extension = file.mimeType?.split("/").last;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('$path/${client.value.id}/$fileName.$extension');
      String fileUrl = "";

      if (kIsWeb) {
        Uint8List fileBytes = await file.readAsBytes();
        UploadTask uploadTask = ref.putData(
          fileBytes,
          SettableMetadata(contentType: file.mimeType),
        );
        TaskSnapshot snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
      } else {
        File fileToUpload = File(file.path);
        UploadTask uploadTask = ref.putFile(
          fileToUpload,
          SettableMetadata(contentType: file.mimeType),
        );
        TaskSnapshot snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
      }

      // Envia mensagem com o link do arquivo
      await sendMessage(
        client.value.id,
        mensagem,
        client.value.nome,
        client.value.foto,
        fileType,
        fileUrl,
      );
    } catch (e) {
      Get.snackbar("Erro", "Erro ao enviar arquivo: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> pickImageVideo() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String fileType =
          pickedFile.path.endsWith(".mp4") ? "video" : "image";
      await uploadFile(XFile(pickedFile.path), fileType, fileType);
    }
  }

  Future<void> pickDoc() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      XFile? selectedFile;
      String fileType = "doc";

      if (kIsWeb) {
        Uint8List? fileBytes = result.files.first.bytes;
        selectedFile = XFile.fromData(
          fileBytes!,
          mimeType:
              lookupMimeType('', headerBytes: fileBytes) ?? 'application/octet-stream',
        );
        String extension = selectedFile.mimeType!.split("/").last;
        if (extension == "mp4") {
          fileType = "video";
        } else if (extension == "jpg" ||
            extension == "png" ||
            extension == "jpeg") {
          fileType = "image";
        }
        await uploadFile(selectedFile, fileType, fileType);
      } else {
        selectedFile = XFile(result.files.single.path!);
        await uploadFile(selectedFile, fileType, fileType);
      }
    }
  }

  Future<void> loadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        imageData = response.bodyBytes;
      } else {
        Get.snackbar("Erro", "Erro ao baixar imagem: ${response.statusCode}",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Erro", "Erro ao baixar imagem: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void scrollToBottom() {
    if (scrollMsgs.hasClients) {
      scrollMsgs.animateTo(
        scrollMsgs.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Dentro do WhatsAppController
  List<String> getVideoUrls() {
    List<String> videoUrls = [];
    for (var doc in messages) {
      // Supondo que o campo 'type' seja "video" e 'mediaUrl' contenha o URL
      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'video' && data['mediaUrl'] != null) {
        videoUrls.add(data['mediaUrl']);
      }
    }
    // Opcional: ordenar por timestamp, se o campo estiver disponível
    videoUrls.sort((a, b) {
      // Implemente a lógica de ordenação se necessário.
      return 0;
    });
    return videoUrls;
  }

  @override
  void onInit() {
    super.onInit();
    // Supondo que seu stream de mensagens venha de uma coleção "chats"
    FirebaseFirestore.instance
        .collection("chats")
        .snapshots()
        .listen((snapshot) {
          messages.value = snapshot.docs;
        });
  }
}