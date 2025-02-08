// lib/app/screens/audio_player_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const AudioPlayerWidget({super.key, required this.audioPlayer});

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  double playbackSpeed = 1.0;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  late final StreamSubscription _durationSubscription;
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _playerCompleteSubscription =
        widget.audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
      }
    });
    _durationSubscription =
        widget.audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          duration = d;
        });
      }
    });
    _positionSubscription =
        widget.audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          position = p;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerCompleteSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.blue),
          onPressed: () async {
            if (isPlaying) {
              await widget.audioPlayer.pause();
            } else {
              await widget.audioPlayer.setPlaybackRate(playbackSpeed);
              await widget.audioPlayer.resume();
            }
            if (mounted) {
              setState(() {
                isPlaying = !isPlaying;
              });
            }
          },
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: duration.inSeconds > 0
                ? duration.inSeconds.toDouble()
                : 1,
            value: position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
            onChanged: (value) async {
              await widget.audioPlayer
                  .seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Text("-${_formatDuration(duration - position)}",
            style: const TextStyle(fontSize: 12)),
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
              widget.audioPlayer.setPlaybackRate(speed);
              if (mounted) {
                setState(() {
                  playbackSpeed = speed;
                });
              }
            }
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}