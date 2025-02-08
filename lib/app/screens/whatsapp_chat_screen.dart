// lib/app/screens/whatsapp_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_vetor/app/screens/audio_player_widget.dart';
import '../controllers/whatsapp_controller.dart';
import '../controllers/media_cache_controller.dart';
// Import condicional para openUrl (web vs. não-web)
import 'package:whatsapp_vetor/app/utils/web_utils_stub.dart'
    if (dart.library.html) 'package:whatsapp_vetor/app/utils/web_utils.dart';
import 'full_screen_video_player.dart';

/// Helper para verificar se duas datas são do mesmo dia
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class WhatsAppChatScreen extends StatefulWidget {
  const WhatsAppChatScreen({super.key});

  @override
  WhatsAppChatScreenState createState() => WhatsAppChatScreenState();
}

class WhatsAppChatScreenState extends State<WhatsAppChatScreen> {
  final WhatsAppController controller = Get.find<WhatsAppController>();
  final MediaCacheController mediaCacheController =
      Get.find<MediaCacheController>();
  final TextEditingController messageController = TextEditingController();
  bool _isRecording = false;
  FlutterSoundRecorder? _recorder;
  String? _imageToShow;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initRecorder();
    }
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    String path =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: path);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    String? recordedPath = await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (recordedPath != null) {
      await controller.uploadFile(XFile(recordedPath), "audio", "Áudio");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Certifique-se de que controller.tamanhoDaTelaChat tenha um valor finito
    if (controller.tamanhoDaTelaChat.value == double.infinity ||
        controller.tamanhoDaTelaChat.value == 0) {
      controller.tamanhoDaTelaChat.value =
          MediaQuery.of(context).size.width - 100; // ajuste conforme necessário
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.client.value.nome,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        automaticallyImplyLeading: !kIsWeb,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black, size: 20),
      ),
      body: Stack(
        children: [
          _buildMessagesList(),
          if (_imageToShow != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _imageToShow = null;
                });
              },
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: CachedNetworkImage(
                  imageUrl: _imageToShow!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white, size: 30),
                ),
              ),
            ),
        ],
      ),
      // O campo de entrada fica fixo na parte inferior
      bottomNavigationBar: _buildMessageInput(),
    );
  }

  /// Constrói a lista de mensagens com separação por dia
  Widget _buildMessagesList() {
    return Obx(() {
      return StreamBuilder<QuerySnapshot>(
        stream: controller.getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma mensagem'));
          }
          List<DocumentSnapshot> messages = snapshot.data!.docs;
          List<Widget> items = [];
          DateTime? lastDate;
          for (var message in messages) {
            DateTime messageDate =
                (message['timestamp'] as Timestamp).toDate();
            if (lastDate == null || !isSameDay(lastDate, messageDate)) {
              items.add(_buildDateDivider(messageDate));
            }
            items.add(_buildMessageItem(message));
            lastDate = messageDate;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.scrollToBottom();
          });
          return ListView(
            controller: controller.scrollMsgs,
            children: items,
          );
        },
      );
    });
  }

  /// Constrói o divider com a data
  Widget _buildDateDivider(DateTime date) {
    String formattedDate = DateFormat.yMMMMd().format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          formattedDate,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  /// Constrói um widget para a mensagem (incluindo horário) 
  Widget _buildMessageItem(DocumentSnapshot message) {
    bool isSentByCompany = message['sender'] == "empresa";
    String? fileType = message['type'];
    double maxContWidth = (fileType == "image" || fileType == "video")
        ? controller.tamanhoDaTelaChat.value * 0.4
        : controller.tamanhoDaTelaChat.value * 0.7;
    Widget content = _buildMessageContent(message);
    DateTime messageTime = (message['timestamp'] as Timestamp).toDate();
    String timeFormatted = DateFormat.Hm().format(messageTime);
    return Align(
      alignment:
          isSentByCompany ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Aqui não forçamos uma largura mínima para textos (ficará ajustada ao conteúdo)
        constraints: BoxConstraints(
          minHeight: 30,
          maxWidth: maxContWidth,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(6), // margem interna maior
        decoration: BoxDecoration(
          color: isSentByCompany ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: fileType == "text"
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              children: [
                fileType == "text"
                    ? content
                    : Expanded(child: content),
                const SizedBox(width: 4),
                if (isSentByCompany)
                  _buildMessageStatusIcon(message['status']),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeFormatted,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o conteúdo da mensagem com base no tipo.
  /// Para textos, exibe o conteúdo; para imagens e vídeos, exibe a preview; para áudio, o player.
  Widget _buildMessageContent(DocumentSnapshot message) {
    String? fileType = message['type'];
    String? fileUrl = message['mediaUrl'];
    if (fileType == "text" || fileUrl == null || fileUrl.isEmpty) {
      return Text(
        message['text'] ?? '',
        style: const TextStyle(fontSize: 14),
        softWrap: true,
      );
    } else if (fileType == "image") {
      return GestureDetector(
        onTap: () {
          setState(() {
            _imageToShow = fileUrl;
          });
        },
        child: CachedNetworkImage(
          imageUrl: fileUrl,
          fit: BoxFit.cover,
          // Reduz a altura máxima da miniatura em 40% (de 37.5 para aproximadamente 22.5 pixels)
          placeholder: (context, url) => const SizedBox(
            height: 22.5,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error, size: 30),
        ),
      );
    } else if (fileType == "video") {
      return _buildVideoPlayer(fileUrl);
    } else if (fileType == "audio") {
      return _buildAudioPlayer(fileUrl);
    } else {
      return _buildDocumentButton(fileUrl);
    }
  }

  Widget _buildMessageStatusIcon(String? status) {
    if (status == "send") {
      return const Icon(Icons.access_time, color: Colors.grey, size: 12);
    } else if (status == "enviada") {
      return const Icon(Icons.check, color: Colors.green, size: 12);
    } else if (status == "received") {
      return const Icon(Icons.done_all, color: Colors.blue, size: 12);
    }
    return const SizedBox.shrink();
  }

  /// Preview do vídeo: exibe um container de 200 pixels de altura com ícone de play.
  Widget _buildVideoPlayer(String videoUrl) {
    return GestureDetector(
      onTap: () {
        _showFullScreenVideo(videoUrl);
      },
      child: Container(
        height: 200,
        color: Colors.black26,
        child: const Center(
          child: Icon(
            Icons.play_circle_filled,
            size: 50,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Botão para abrir documentos.
  Widget _buildDocumentButton(String documentUrl) {
    return ElevatedButton(
      onPressed: () async {
        if (kIsWeb) {
          openUrl(documentUrl);
        } else {
          final Uri url = Uri.parse(documentUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            Get.snackbar("Erro", "Não foi possível abrir o documento",
                snackPosition: SnackPosition.BOTTOM);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: const Text("Abrir"),
    );
  }

  /// Constrói o widget do player de áudio.
  Widget _buildAudioPlayer(String audioUrl) {
    return FutureBuilder<AudioPlayer>(
      future: mediaCacheController.getAudioPlayer(audioUrl),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(strokeWidth: 2);
        }
        final AudioPlayer audioPlayer = snapshot.data!;
        return AudioPlayerWidget(audioPlayer: audioPlayer);
      },
    );
  }

  /// Campo de entrada de mensagem, variando de 1 a 3 linhas.
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.green, size: 20),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Digite...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          kIsWeb
              ? IconButton(
                  icon: const Icon(Icons.mic, color: Colors.grey, size: 20),
                  onPressed: () {
                    Get.snackbar("Atenção", "Gravação não disponível no Web",
                        snackPosition: SnackPosition.BOTTOM);
                  },
                )
              : !_isRecording
                  ? IconButton(
                      icon: const Icon(Icons.mic, color: Colors.red, size: 20),
                      onPressed: _startRecording,
                    )
                  : IconButton(
                      icon: const Icon(Icons.stop, color: Colors.green, size: 20),
                      onPressed: _stopRecording,
                    ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green, size: 20),
            onPressed: () {
              controller.sendMessage(
                controller.client.value.id,
                messageController.text.trim(),
                controller.client.value.nome,
                controller.client.value.foto,
                "text",
                "",
              );
              messageController.clear();
            },
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue, size: 20),
              title: const Text('Imagem', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                controller.pickImageVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_collection,
                  color: Colors.red, size: 20),
              title: const Text('Vídeo', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                controller.pickImageVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file,
                  color: Colors.grey, size: 20),
              title: const Text('Documento', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                controller.pickDoc();
              },
            ),
          ],
        );
      },
    );
  }

  /// Navega para a tela cheia do vídeo.
  void _showFullScreenVideo(String videoUrl) {
    // Filtra a lista de mensagens para obter apenas os vídeos.
    // Supondo que controller.getMessages() retorne um stream de QuerySnapshot
    // e que as mensagens estejam ordenadas por timestamp.
    // Aqui vamos extrair a lista de URLs de vídeo diretamente do snapshot.
    // Uma abordagem simples (mas você pode mover essa lógica para o controller):
    List<String> videoUrls = [];
    // Obtemos o último snapshot armazenado (se disponível) do stream.
    // Como estamos usando Obx com StreamBuilder, podemos ter a lista disponível.
    // Caso contrário, você precisará gerenciar essa lista no controller.
    // Para este exemplo, vamos supor que o controller possui um método getVideoUrls().
    videoUrls = controller.getVideoUrls(); // Você precisa implementar esse método se ainda não existir.

    int currentIndex = videoUrls.indexOf(videoUrl);
    if (currentIndex < 0) {
      currentIndex = 0;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenVideoPlayerScreen(videoUrls: videoUrls, initialIndex: currentIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    super.dispose();
  }
}