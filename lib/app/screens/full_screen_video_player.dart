import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/media_cache_controller.dart';

class FullScreenVideoPlayerScreen extends StatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;
  const FullScreenVideoPlayerScreen({
    super.key,
    required this.videoUrls,
    this.initialIndex = 0,
  });

  @override
  FullScreenVideoPlayerScreenState createState() => FullScreenVideoPlayerScreenState();
}

class FullScreenVideoPlayerScreenState extends State<FullScreenVideoPlayerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final MediaCacheController mediaCacheController = Get.find<MediaCacheController>();
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Retorna o widget que exibe cada vídeo com zoom e play/pause ao tocar.
  Widget _buildVideoPage(String videoUrl) {
    return FutureBuilder(
      future: _initializeAndPlay(videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        VideoPlayerController controller = mediaCacheController.getVideoController(videoUrl);
        return GestureDetector(
          onTap: () {
            setState(() {
              controller.value.isPlaying ? controller.pause() : controller.play();
            });
          },
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Método auxiliar que obtém o controller, inicializa se necessário e inicia o play.
  Future<void> _initializeAndPlay(String videoUrl) async {
    VideoPlayerController controller = mediaCacheController.getVideoController(videoUrl);
    if (!controller.value.isInitialized) {
      await controller.initialize();
    }
    if (!controller.value.isPlaying) {
      await controller.play();
      await controller.setPlaybackSpeed(_playbackSpeed);
    }
  }

  void _changePlaybackSpeed(double speed) {
    VideoPlayerController controller = mediaCacheController.getVideoController(widget.videoUrls[_currentIndex]);
    controller.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Se o usuário tocar fora do conteúdo, fecha a tela
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0.8),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.videoUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {}, // Impede que o onTap do fundo seja acionado
                  child: _buildVideoPage(widget.videoUrls[index]),
                );
              },
            ),
            // Botão de fechar no canto superior direito
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Dropdown para alterar a velocidade de reprodução
            Positioned(
              bottom: 20,
              left: 20,
              child: DropdownButton<double>(
                value: _playbackSpeed,
                dropdownColor: Colors.black87,
                icon: const Icon(Icons.speed, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text("0.5x", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 1.0, child: Text("1x", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 1.5, child: Text("1.5x", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 2.0, child: Text("2x", style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _changePlaybackSpeed(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}