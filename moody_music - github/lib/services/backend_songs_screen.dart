
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'api_service.dart';

class BackendSongsScreen extends StatefulWidget {
  const BackendSongsScreen({super.key});

  @override
  State<BackendSongsScreen> createState() =>
      _BackendSongsScreenState();
}

class _BackendSongsScreenState
    extends State<BackendSongsScreen> {
  late Future<List<dynamic>> songsFuture;

  final AudioPlayer player = AudioPlayer();
  int? playingIndex;
  bool isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    songsFuture = ApiService.getSongs();
  }

  Future<void> playSong(
    Map<String, dynamic> song,
    int index,
  ) async {
    try {
      final audioUrl = song['audio_url'];

      if (audioUrl == null ||
          audioUrl.toString().isEmpty) {
        // Use the test MP3 until database paths are mapped.
        await player.setUrl(
          'http://10.0.2.2:5000/music/test_song.mp3',
        );
      } else {
        final url = audioUrl.toString();
        final fullUrl = url.startsWith('http')
            ? url
            : 'http://10.0.2.2:5000$url';

        await player.setUrl(fullUrl);
      }

      await player.play();

      if (mounted) {
        setState(() {
          playingIndex = index;
          isLoadingAudio = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingAudio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play song: $e')),
        );
      }
    }
  }

  Future<void> toggleSong(
    Map<String, dynamic> song,
    int index,
  ) async {
    if (playingIndex == index && player.playing) {
      await player.pause();
      if (mounted) setState(() {});
      return;
    }

    setState(() => isLoadingAudio = true);
    await playSong(song, index);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Songs')),
      body: FutureBuilder<List<dynamic>>(
        future: songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load songs.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final songs = snapshot.data ?? [];

          if (songs.isEmpty) {
            return const Center(
              child: Text('No songs found.'),
            );
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = Map<String, dynamic>.from(
                songs[index] as Map,
              );

              final isCurrent = playingIndex == index;

              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(
                  song['title']?.toString() ?? 'Unknown Song',
                ),
                subtitle: Text(
                  '${song['artist'] ?? 'Unknown Artist'}'
                  ' • ${song['mood'] ?? 'No Mood'}',
                ),
                trailing: IconButton(
                  icon: Icon(
                    isCurrent && player.playing
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  onPressed: isLoadingAudio
                      ? null
                      : () => toggleSong(song, index),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
