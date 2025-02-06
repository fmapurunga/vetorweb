import 'dart:html' as html;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../controllers/whatsapp_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';


class WhatsAppChatScreen extends StatefulWidget {
  final WhatsAppController whatsAppController;
  const WhatsAppChatScreen({super.key, required this.whatsAppController});

  @override
  _WhatsAppChatScreenState createState() => _WhatsAppChatScreenState();
}

class _WhatsAppChatScreenState extends State<WhatsAppChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _imageToShow;
  bool _isRecording = false;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _audioPath;

  Map<String, VideoPlayerController> _videoCache = {};

  @override
  Widget build(BuildContext context) {
    bool isDesktop = kIsWeb;
    double maxMessageWidth = widget.whatsAppController.tamanhoDaTelaChat*0.7;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.whatsAppController.cliente.nome, style: const TextStyle(color: Colors.grey),),
        automaticallyImplyLeading: !isDesktop,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMessagesList(maxMessageWidth)),
              _buildMessageInput(context),
            ],
          ),
          if (_imageToShow != null) _buildFullScreenImage()
        ],
      )
    );
  }

  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initRecorder();
    }
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    String path = "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac";

    await _recorder.startRecorder(toFile: path);
    setState(() {
      _isRecording = true;
      _audioPath = path;
    });
  }

  Future<void> _stopRecording() async {
    String? recordedPath = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    if (recordedPath != null) {
      // Envia o arquivo gravado para o Firebase
      widget.whatsAppController.uploadFile(XFile(recordedPath), "audio", "Áudio");
    }
  }


  Widget _buildMessagesList(double maxMessageWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.whatsAppController.messages, // 🔹 Agora usa a instância correta
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhuma mensagem ainda'));
        }
        WidgetsBinding.instance.addPostFrameCallback((_){widget.whatsAppController.scrollToBottom();});
        var messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: false,
          itemCount: messages.length,
          controller: widget.whatsAppController.scrollMsgs,
          itemBuilder: (context, index) {
            var message = messages[index];
            bool isSentByCompany = message['sender'] == "empresa";
            String? fileType = message['type'];

            bool isMedia = fileType == "image" || fileType == "video";
            double maxContWidth = isMedia ? widget.whatsAppController.tamanhoDaTelaChat*0.4 : maxMessageWidth;

            bool isDoc = fileType == "doc";
            isDoc ? maxContWidth = widget.whatsAppController.tamanhoDaTelaChat*0.2 : maxMessageWidth;

            return Align(
              alignment: isSentByCompany ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxContWidth // 🔹 Mensagem ocupa no máximo 70% da tela
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: (isMedia || isDoc) ? const EdgeInsets.all(3) : const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: fileType == "doc" ? Colors.transparent : (isSentByCompany ? Colors.green[100] : Colors.blue[100]),    ///////AJUSTA AQUI O ÍCONE DA MENSAGEM TIPO DOC
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildMessageContainer(message)
                    ),
                    const SizedBox(width: 5), // Espaço entre a mensagem e o ícone de status
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildMessageStatusIcon(message['status']), // Ícone do status
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageStatusIcon(String? status) {
    if (status == "pending") {
      return const Icon(Icons.access_time, color: Colors.grey, size: 10); // ⏳ Ícone de relógio
    } else if (status == "received") {
      return const Icon(Icons.check_circle, color: Colors.green, size: 10); // ✅ Ícone de check
    } else {
      return const SizedBox.shrink(); // Sem ícone se o status não for pending nem received
    }
  }

  Widget _buildMessageInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50, maxHeight: 200), 
        child: Row(
          children: [
            IconButton(onPressed: (){_showAttachmentOptions(context);}, icon: const Icon(Icons.attach_file, color: Colors.green,)),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            ),
            if (kIsWeb) IconButton(icon: Icon(Icons.mic, color: Colors.grey,), onPressed: (){AlertDialog(content: Text("Não é possível gravar pelo computador"));})
            else if (!_isRecording)
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.red),
                onPressed: _startRecording,
              )
            else
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.green),
                onPressed: _stopRecording,
              ),
              IconButton(
              icon: const Icon(Icons.send, color: Colors.green),
              onPressed: () {
                widget.whatsAppController.sendMessage(
                  widget.whatsAppController.cliente.id,
                  _messageController.text,
                  widget.whatsAppController.cliente.nome,
                  widget.whatsAppController.cliente.foto,
                  "text", //type
                  ""  //mediaUrl
                );
                _messageController.clear();
              },
            ),
          ],
        )
      ),
    );
  }

  _showAttachmentOptions(BuildContext context){
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Enviar Imagem'),
              onTap: () {
                Navigator.pop(context);
                (kIsWeb) ? widget.whatsAppController.pickDoc() : widget.whatsAppController.pickImageVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_collection, color: Colors.red),
              title: const Text('Enviar Vídeo'),
              onTap: () {
                Navigator.pop(context);
                (kIsWeb) ? widget.whatsAppController.pickDoc() : widget.whatsAppController.pickImageVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.grey),
              title: const Text('Enviar Documento'),
              onTap: () {
                Navigator.pop(context);
                widget.whatsAppController.pickDoc();
              },
            ),
          ],
        );
      },
    );
  }

  _buildMessageContainer(DocumentSnapshot message) {
    String? fileType = message['type'];
    String? fileUrl = message['mediaUrl'];
    if (fileType == "text" || fileUrl == null) {
      return Text(
        message['text'] ?? '',
        style: const TextStyle(fontSize: 16),
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    } else if (fileType == "image") {
      return GestureDetector(
        onTap: () {
          setState(() {
            _imageToShow = fileUrl;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            fileUrl,
            width: widget.whatsAppController.tamanhoDaTelaChat*0.4, // 📌 Máximo de altura
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text("Erro ao carregar a imagem");
            },
          ),
        ),
      );
    }  else if (fileType == "video") {
      return _buildVideoPlayer(fileUrl);
    } else if (fileType == "audio") {
      return _buildAudioPlayer(fileUrl);
    } else {
      return _buildDocumentButton(fileUrl);
    }
  }

  _buildVideoPlayer(String videoUrl) {
    if (!_videoCache.containsKey(videoUrl)) {
      _videoCache[videoUrl] = VideoPlayerController.networkUrl(Uri.parse(videoUrl))..initialize();
    }

    return GestureDetector(
      onTap: () {
        _showFullScreenVideo(_videoCache[videoUrl]!);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: _videoCache[videoUrl]!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                "$videoUrl?preview=true",
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.transparent,
                    child: const Icon(Icons.video_file, color: Colors.grey, size: 300,),
                  );
                },
              ),
              const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
            ],
          ),
        )
      )
    );

  } 

  _buildDocumentButton(String documentUrl) {
    return ElevatedButton.icon(
      onPressed: () async {
        if (kIsWeb) {
          // Abrir no Web
          html.window.open(documentUrl, "_blank");
        } else {
          // Abrir no Mobile
          final Uri url = Uri.parse(documentUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            print("Erro ao abrir documento");
          }
        }
      },
      icon: const Icon(Icons.insert_drive_file, color: Colors.white),
      label: const Text("Abrir Documento"),
    );
  }

  Widget _buildFullScreenImage() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _imageToShow = null; // 📌 Fecha a tela cheia ao clicar
        });
      },
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                _imageToShow!,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  setState(() {
                    _imageToShow = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildAudioPlayer(String audioUrl) {
    final AudioPlayer audioPlayer = AudioPlayer();
    double playbackSpeed = 1.0;
    bool isPlaying = false;
    Duration position = Duration.zero;
    Duration duration = Duration.zero;

    // 🔹 Inicializa o áudio e obtém a duração
    Future<Duration> initializeAudio() async {
      await audioPlayer.setSourceUrl(audioUrl);
      return await audioPlayer.getDuration() ?? Duration.zero;
    }

    return FutureBuilder<Duration>(
      future: initializeAudio(), // 🔹 Obtém a duração antes de exibir o player
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // 🔄 Mostra loading enquanto carrega
        }

        duration = snapshot.data ?? Duration.zero;

        return StatefulBuilder(
          builder: (context, setState) {
            // 🔹 Listener para resetar UI ao terminar o áudio
            audioPlayer.onPlayerComplete.listen((_) {
              setState(() {
                isPlaying = false;
                position = Duration.zero;
              });
            });

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // 🔹 Botão Play/Pause
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.blue),
                      onPressed: () async {
                        if (isPlaying) {
                          await audioPlayer.pause();
                        } else {
                          await audioPlayer.setPlaybackRate(playbackSpeed);
                          await audioPlayer.resume();
                        }
                        setState(() {
                          isPlaying = !isPlaying;
                        });
                      },
                    ),

                    // 🔹 Barra de progresso do áudio
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: audioPlayer.onPositionChanged,
                        builder: (context, snapshot) {
                          position = snapshot.data ?? Duration.zero;

                          double sliderValue = duration.inSeconds > 0 ? position.inSeconds.toDouble() : 0;
                          double sliderMax = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1;

                          return Slider(
                            min: 0,
                            max: sliderMax,
                            value: sliderValue.clamp(0, sliderMax), // 🔹 Evita erro do Slider
                            onChanged: (value) async {
                              await audioPlayer.seek(Duration(seconds: value.toInt()));
                            },
                          );
                        },
                      ),
                    ),

                    // 🔹 Texto com tempo restante
                    Text(
                      "-${_formatDuration(duration - position)}",
                      style: const TextStyle(fontSize: 12),
                    ),

                    // 🔹 Seletor de Velocidade
                    DropdownButton<double>(
                      value: playbackSpeed,
                      items: const [
                        DropdownMenuItem(value: 0.75, child: Text("0.75x")),
                        DropdownMenuItem(value: 1.0, child: Text("1x")),
                        DropdownMenuItem(value: 1.5, child: Text("1.5x")),
                        DropdownMenuItem(value: 2.0, child: Text("2x")),
                      ],
                      onChanged: (speed) {
                        if (speed != null) {
                          audioPlayer.setPlaybackRate(speed);
                          setState(() {
                            playbackSpeed = speed;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 Função auxiliar para formatar duração
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _showFullScreenVideo(VideoPlayerController vController) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double videoSpeed = 1.0; // Controle de velocidade
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer( // 🔹 Zoom no vídeo
                          minScale: 1.0,
                          maxScale: 3.0,
                          child: AspectRatio(
                            aspectRatio: vController.value.aspectRatio,
                            child: VideoPlayer(vController),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            vController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              vController.value.isPlaying ? vController.pause() : vController.play();
                            });
                          },
                        ),
                        Positioned(
                          top: 20,
                          right: 20,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            onPressed: () {
                              vController.pause();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: VideoProgressIndicator(
                      vController,
                      allowScrubbing: true, // 🔹 Permite arrastar o progresso
                      colors: const VideoProgressColors(
                        playedColor: Colors.green,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSpeedButton(0.5, videoSpeed, setState, vController),
                        _buildSpeedButton(1.0, videoSpeed, setState, vController),
                        _buildSpeedButton(1.5, videoSpeed, setState, vController),
                        _buildSpeedButton(2.0, videoSpeed, setState, vController),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Botão para ajustar velocidade do vídeo
  Widget _buildSpeedButton(double speed, double currentSpeed, Function setState, VideoPlayerController vController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            vController.setPlaybackSpeed(speed);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: currentSpeed == speed ? Colors.green : Colors.grey[700],
        ),
        child: Text("${speed}x", style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

