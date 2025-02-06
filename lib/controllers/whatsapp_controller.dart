
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:whatsapp_vetor/models/client.dart';
import 'package:http/http.dart' as http;

class WhatsAppController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot> messages = const Stream.empty();
  Client cliente = Client(id: "", nome: "", foto: "", ultimaMensagem: "", ultimaMensagemData: DateTime.now());
  double tamanhoDaTelaChat = 400;
  double tamanhoDaTelaLista = 300;
  String token = "EAAQ7haJGEJYBOxrPlCSpEeXkq93LXwRIsZB6iGqCYItq8fXAqrl8cjkG8XSpWPNUY9IS7pkhvs4BiUfZAGSPG5G9RsAMVkBKmLGuVajaqjVVElEUeiS21AB9EROJnmCS9nAChgORxOqxZARpDwfMdb2IZAzhV4nKCUnD60XfH3cddbw6kgqtufNKrmZCCNYZBlpAZDZD";
  String phoneNumberId = "577900678729878";
  Uint8List? imageData;
  ScrollController scrollMsgs = ScrollController();
  

  

  /// 🔹 Obter Lista de Conversas (Clientes com Mensagens)
  Stream<QuerySnapshot> getConversations() {
    return _firestore.collection("chats").orderBy("lastMessageTime", descending: true).snapshots();
  }

  /// 🔹 Obter Stream de Mensagens em Tempo Real (de um Cliente)
  getMessages() {
    messages = _firestore
        .collection("chats")
        .doc(cliente.id)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  /// 🔹 Enviar Mensagem para um Cliente
  Future<void> sendMessage(String clienteId, String message, String nome, String foto, String type, String mediaUrl) async {
    // 🔹 Salvar mensagem na coleção GLOBAL "messages"
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
      await _firestore.collection("chats").doc(clienteId).collection("messages").doc(messageRef.id).set({
        "sender": "empresa",  // Mensagem enviada pela empresa
        "text": (mediaUrl != "") ? "" : message,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "pending", // O Make irá monitorar essa mensagem para envio
        "type": type,
        "mediaUrl": mediaUrl,
      });
      // 🔹 Atualiza a última mensagem na coleção "chats"
      await _firestore.collection("chats").doc(clienteId).set({
        "lastMessage": lastMsg,
        "lastMessageTime": FieldValue.serverTimestamp(),
        "foto": foto,
        "nome": nome
      }, SetOptions(merge: true));
    } catch (e) {
      print("Erro ao enviar mensagem: $e");
    }
  }

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
      String? mime = file.mimeType?.split("/").last;
      Reference ref = FirebaseStorage.instance.ref().child('$path/${cliente.id}/$fileName.$mime');
      String fileUrl = "";
      
      if (kIsWeb) {
        Uint8List fileBytes = await file.readAsBytes();
        UploadTask uploadTask = ref.putData(fileBytes, SettableMetadata(contentType: file.mimeType));
        TaskSnapshot snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
      } else {
        File fileToUpload = File(file.path);
        UploadTask uploadTask = ref.putFile(fileToUpload, SettableMetadata(contentType: file.mimeType));
        TaskSnapshot snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();  
      }

      // Enviar mensagem com link do arquivo
      sendMessage(
        cliente.id,
        mensagem,
        cliente.nome,
        cliente.foto,
        fileType, // Tipo do arquivo
        fileUrl // URL do arquivo
      );

    } catch (e) {
      print("Erro ao enviar arquivo: $e");
    }
  }

  Future<void> pickImageVideo() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    XFile? selectedFile;
    String? fileType;

    if (pickedFile != null ) {
      selectedFile = XFile(pickedFile.path);
      fileType = pickedFile.path.endsWith(".mp4") ? "video" : "image";
      await uploadFile(selectedFile, fileType, fileType);
    }
  }

  Future<void> pickDoc() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    XFile? selectedFile;
    String fileType = "doc";

    if (result != null) {
      if (kIsWeb) { 
        // 📌 Flutter Web: Usa `bytes`

        Uint8List? fileBytes = result.files.first.bytes;
        selectedFile = XFile.fromData(fileBytes!, mimeType: lookupMimeType('', headerBytes: fileBytes) ?? 'application/octet-stream');
        String extensao = selectedFile.mimeType!.split("/").last;
        print("mime: ${selectedFile.mimeType}");
        print("Entensão: ${extensao}");
        if (extensao == "mp4") {
          fileType = "video";
        } else if (extensao == "jpg" || extensao == "png" || extensao == "jpeg") {
          fileType = "image";
        } else {
          fileType = "doc";
        }

        await uploadFile(selectedFile, fileType, fileType);
      } else {
        // 📌 Flutter Mobile/Desktop: Usa `path`
        selectedFile = XFile(result.files.single.path!);
        await uploadFile(selectedFile, fileType, fileType);
        // Aqui você pode fazer upload do arquivo via File(filePath)
      }
    }
  }

  Future<void> loadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        imageData = response.bodyBytes;
      } else {
        print("Erro ao baixar imagem 2: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao baixar imagem 1: ${e}");
    }
  }

  scrollToBottom(){
    if (scrollMsgs.hasClients) {
      scrollMsgs.animateTo(scrollMsgs.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}