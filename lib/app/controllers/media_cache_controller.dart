// lib/app/controllers/media_cache_controller.dart
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class MediaCacheController extends GetxController {
  // Mapa para armazenar VideoPlayerController por URL
  final Map<String, VideoPlayerController> videoControllers = {};
  // Mapa para armazenar AudioPlayer por URL
  final Map<String, AudioPlayer> audioPlayers = {};

  /// Retorna (ou cria se não existir) um VideoPlayerController para a URL informada.
  VideoPlayerController getVideoController(String url) {
    if (!videoControllers.containsKey(url)) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      videoControllers[url] = controller;
      // Inicializa o controlador apenas uma vez
      controller.initialize();
    }
    return videoControllers[url]!;
  }

  /// Retorna (ou cria se não existir) um AudioPlayer para a URL informada.
  Future<AudioPlayer> getAudioPlayer(String url) async {
    if (!audioPlayers.containsKey(url)) {
      final player = AudioPlayer();
      // Configura a fonte de áudio; aguarda a configuração para garantir que o player esteja pronto.
      await player.setSourceUrl(url);
      audioPlayers[url] = player;
    }
    return audioPlayers[url]!;
  }

  @override
  void onClose() {
    // Dispose de todos os VideoPlayerControllers
    for (var vController in videoControllers.values) {
      vController.dispose();
    }
    // Dispose de todos os AudioPlayers
    for (var aPlayer in audioPlayers.values) {
      aPlayer.dispose();
    }
    super.onClose();
  }
}