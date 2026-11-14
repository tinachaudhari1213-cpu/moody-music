
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineMusicScreen extends StatefulWidget {
  final String? initialSongPath;

  const OfflineMusicScreen({
    super.key,
    this.initialSongPath,
  });

  @override
  State<OfflineMusicScreen> createState() =>
      _OfflineMusicScreenState();
}

class _OfflineMusicScreenState extends State<OfflineMusicScreen> {
  final AudioPlayer _player = AudioPlayer();
  final Set<String> _favoritePaths = <String>{};

  static const String _favoritesKey = 'offline_favorite_song_paths';
 static const String _historyKey = 'offline_playback_history';

Future<void> _saveOfflineHistory(Map<String, String> song) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final history =
        prefs.getStringList(_historyKey) ?? <String>[];

    final entry = jsonEncode({
      'title': song['title'] ?? 'Unknown Song',
      'artist': 'Offline Music',
      'path': song['path'] ?? '',
      'mood': song['mood'] ?? selectedMood,
      'played_at': DateTime.now().toIso8601String(),
      'source': 'offline',
    });

    // Add the newest play at the beginning.
    history.insert(0, entry);

    // Keep only the latest 100 plays.
    await prefs.setStringList(
      _historyKey,
      history.take(100).toList(),
    );

    debugPrint('Offline history saved: ${song['title']}');
  } catch (e) {
    debugPrint('Could not save offline history: $e');
  }
}
Future<void> _loadFavorites() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedFavorites =
        prefs.getStringList(_favoritesKey) ?? <String>[];

    if (!mounted) return;

    setState(() {
      _favoritePaths
        ..clear()
        ..addAll(savedFavorites);
    });
  } catch (e) {
    debugPrint('Could not load favorites: $e');
  }
}
@override
void initState() {
  super.initState();

  _loadFavorites();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final path = widget.initialSongPath;

    if (path == null || !mounted) return;

    final songIndex = _songs.indexWhere(
      (song) => song['path'] == path,
    );

    if (songIndex == -1) return;

    final song = _songs[songIndex];
    final mood = song['mood'];

    if (mood != null && mood != selectedMood) {
      await _changeMood(mood);
    }

    if (!mounted) return;

    final index = filteredSongs.indexWhere(
      (item) => item['path'] == path,
    );

    if (index != -1) {
      await _playSong(index);
    }
  });
}

  Future<void> _toggleFavorite(Map<String, String> song) async {
    final path = song['path'];
    if (path == null) return;

    final wasFavorite = _favoritePaths.contains(path);
    setState(() {
      if (wasFavorite) {
        _favoritePaths.remove(path);
      } else {
        _favoritePaths.add(path);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoritePaths.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? 'Removed from favorites'
                : 'Added to favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoritePaths.add(path);
        } else {
          _favoritePaths.remove(path);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save favorite. Please try again.')),
      );
    }
  }

  String selectedMood = 'Happy';
  int _currentIndex = -1;
  bool _loading = false;
  String? _error;

  final List<Map<String, String>> _songs = [
    {
      'title': 'Agar Tum Sath Ho',
      'path': 'assets/songs/Agar Tum Sath Ho_320(KoshalWorld.Com) - Copy.mp3',
      'mood': 'Sad',
    },
    {
      'title': 'Badtameez Dil',
      'path': 'assets/songs/Badtameez Dil Yeh Jawaani Hai Deewani 128 Kbps - Copy.mp3',
      'mood': 'Happy',
    },
    {
      'title': 'Gajanana',
      'path': 'assets/songs/Badzhirao_Mastani_Bajirao_Mastani_-_Gajanana_(mp3.pm) - Copy.mp3',
      'mood': 'Energetic',
    },
    {
      'title': 'O Rangrez',
      'path': 'assets/songs/Bhaag_Milkha_Bhaag_-_O_Rangrez_(mp3.pm) - Copy.mp3',
      'mood': 'Rainy Mood',
    },
    {
      'title': 'Zinda',
      'path': 'assets/songs/Bhaag_Milkha_Bhaag_-_Zinda_(mp3.pm).mp3',
      'mood': 'Energetic',
    },
    {
      'title': 'Chal Turu Turu',
      'path': 'assets/songs/Chal-Turu-Turu-Nick-Shinde-Srushti-Ambavale-Abhijeet-Sawant-Sonali-Sonawane-Prasad-Shirsath - Copy.mp3',
      'mood': 'Happy',
    },
    {
      'title': 'Chand Tu Nabhatla',
      'path': 'assets/songs/Chand Tu Nabhatla (PenduJatt.dev) - Copy.mp3',
      'mood': 'Romantic',
    },
    {
      'title': 'Channa Mereya',
      'path': 'assets/songs/Channa Mereya_320(KoshalWorld.Com).mp3',
      'mood': 'Sad',
    },
    {
      'title': 'Chimb Bhijalele',
      'path': 'assets/songs/Chimb-Bhijalele.mp3',
      'mood': 'Romantic',
    },
    {
      'title': 'Ek Ladki Bheegi Bhagi Si',
      'path': 'assets/songs/Ek Ladki Bheegi Bhagi Si Chalti Ka Naam Gaadi 128 Kbps (1).mp3',
      'mood': '90s Classics',
    },
    {
      'title': 'Ek Ladki Ko Dekha',
      'path': 'assets/songs/Ek Ladki Ko Dekha 1942 A Love Story 128 Kbps.mp3',
      'mood': '90s Classics',
    },
    {
      'title': 'Unknown Song',
      'path': 'assets/songs/f6f55b576f32bc520b655d34a920a4957d94791e6c389cd6da5da60c19e668e2.mp3',
      'mood': 'Calm',
    },
    {
      'title': 'Gallan Goodiyaan',
      'path': 'assets/songs/Gallan Goodiyaan Dil Dhadakne Do 128 Kbps.mp3',
      'mood': 'Happy',
    },
    {
      'title': 'Gulabi Sadi',
      'path': 'assets/songs/Gulabi Sadi.mp3',
      'mood': 'Happy',
    },
    {
      'title': 'Hi Yaad Tujhi',
      'path': 'assets/songs/Hi Yaad Tujhi - RaagTune (1).mp3',
      'mood': 'Sad',
    },
    {
      'title': 'Iktara',
      'path': 'assets/songs/Iktara Wake Up Sid 128 Kbps.mp3',
      'mood': 'Calm',
    },
    {
      'title': 'Jai Jai Shivshankar',
      'path': 'assets/songs/Jai Jai Shivshankar War 128 Kbps.mp3',
      'mood': 'Energetic',
    },
    {
      'title': 'Kun Faaya Kun',
      'path': 'assets/songs/Kun Faaya Kun Rockstar 128 Kbps.mp3',
      'mood': 'Calm',
    },
    {
      'title': 'Main Pal Do Pal Ka Shair Hoon',
      'path': 'assets/songs/Main Pal Do Pal Ka Shair Hoon Kabhi Kabhie 128 Kbps.mp3',
      'mood': 'Sad',
    },
    {
      'title': 'Olya Sanjveli',
      'path': 'assets/songs/Olya-Sanjveli.mp3',
      'mood': 'Rainy Mood',
    },
    {
      'title': 'Pehla Nasha',
      'path': 'assets/songs/Pehla Nasha(KoshalWorld.dev).mp3',
      'mood': '90s Classics',
    },
    {
      'title': 'Pratapgadachya Paythyashi Khan',
      'path': 'assets/songs/Pratapgadachya Paythyashi Khan - RaagTune (1).mp3',
      'mood': 'Energetic',
    },
    {
      'title': 'Raabta',
      'path': 'assets/songs/Raabta Agent Vinod 128 Kbps.mp3',
      'mood': 'Romantic',
    },
    {
      'title': 'Rimjhim Gire Sawan',
      'path': 'assets/songs/Rimjhim Gire Sawan Male Manzil 128 Kbps.mp3',
      'mood': 'Rainy Mood',
    },
    {
      'title': 'Sukh Kalale',
      'path': 'assets/songs/Sukh-Kalale.mp3',
      'mood': 'Romantic',
    },
    {
      'title': 'Tip Tip Barsa Paani',
      'path': 'assets/songs/Tip Tip Barsa Paani Mohra 128 Kbps.mp3',
      'mood': 'Rainy Mood',
    },
    {
      'title': 'Tujhe Dekha To',
      'path': 'assets/songs/Tujhe Dekha To Dilwale Dulhania Le Jayenge 128 Kbps.mp3',
      'mood': '90s Classics',
    },
    {
      'title': 'Tum Hi Ho',
      'path': 'assets/songs/Tum Hi Ho Aashiqui 2 128 Kbps.mp3',
      'mood': 'Romantic',
    },
  ];

  List<Map<String, String>> get filteredSongs {
    return _songs
        .where((song) => song['mood'] == selectedMood)
        .toList();
  }

  Map<String, String>? get currentSong {
    final songs = filteredSongs;

    if (_currentIndex < 0 || _currentIndex >= songs.length) {
      return null;
    }

    return songs[_currentIndex];
  }

  Future<void> _playSong(int index) async {
  final songs = filteredSongs;

  if (_loading || index < 0 || index >= songs.length) {
    return;
  }

  setState(() {
    _currentIndex = index;
    _loading = true;
    _error = null;
  });

  try {
    final song = songs[index];

    await _player.setAsset(song['path']!);

    // Save history only after the song loads successfully.
    await _saveOfflineHistory(song);

    if (!mounted) return;

    unawaited(_player.play());
  } catch (e) {
    debugPrint('Song playback error: $e');

    if (mounted) {
      setState(() {
        _error =
            'Song play nahi hua. MP3 file aur asset path check karo.';
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}
  Future<void> _changeMood(String mood) async {
    if (mood == selectedMood) return;

    await _player.stop();

    if (!mounted) return;

    setState(() {
      selectedMood = mood;
      _currentIndex = -1;
      _error = null;
    });
  }

  Future<void> _togglePlayPause() async {
    if (_loading) return;

    if (_currentIndex == -1) {
      if (filteredSongs.isNotEmpty) {
        await _playSong(0);
      }
      return;
    }

    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        unawaited(_player.play());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Playback nahi ho paya.');
      }
    }
  }

  Future<void> _playNext() async {
    final songs = filteredSongs;

    if (_loading || songs.isEmpty) return;

    final next = _currentIndex < 0
        ? 0
        : (_currentIndex + 1) % songs.length;

    await _playSong(next);
  }

  Future<void> _playPrevious() async {
    final songs = filteredSongs;

    if (_loading || songs.isEmpty) return;

    final previous = _currentIndex <= 0
        ? songs.length - 1
        : _currentIndex - 1;

    await _playSong(previous);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';

    return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = filteredSongs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moody Music'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _moodButton('Happy', '😊'),
                _moodButton('Sad', '😢'),
                _moodButton('Calm', '🌿'),
                _moodButton('Romantic', '❤️'),
                _moodButton('Energetic', '⚡'),
                _moodButton('90s Classics', '📻'),
                _moodButton('Rainy Mood', '🌧️'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '$selectedMood Playlist',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text('No songs available for this mood.'),
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final selected = index == _currentIndex;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? Colors.deepPurple
                              : Colors.deepPurple.shade50,
                          child: Icon(
                            selected
                                ? Icons.graphic_eq
                                : Icons.music_note,
                            color: selected
                                ? Colors.white
                                : Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          song['title']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(song['mood']!),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: _favoritePaths.contains(song['path'])
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                              icon: Icon(
                                _favoritePaths.contains(song['path'])
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _favoritePaths.contains(song['path'])
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () => _toggleFavorite(song),
                            ),
                            IconButton(
                              tooltip: 'Play song',
                              icon: const Icon(Icons.play_circle_fill),
                              iconSize: 32,
                              onPressed: _loading
                                  ? null
                                  : () => _playSong(index),
                            ),
                          ],
                        ),
                        onTap: _loading ? null : () => _playSong(index),
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _buildPlayerControls(),
        ],
      ),
    );
  }

  Widget _moodButton(String mood, String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selectedMood == mood,
        label: Text('$emoji $mood'),
        selectedColor: Colors.deepPurple.shade100,
        onSelected: (_) => _changeMood(mood),
      ),
    );
  }

  Widget _buildPlayerControls() {
    final song = currentSong;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              song?['title'] ?? 'Select a song to play',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;

                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, positionSnapshot) {
                    final position =
                        positionSnapshot.data ?? Duration.zero;
                    final maxMs = duration.inMilliseconds;
                    final maxValue =
                        maxMs > 0 ? maxMs.toDouble() : 1.0;
                    final value = position.inMilliseconds
                        .clamp(0, maxMs > 0 ? maxMs : 1)
                        .toDouble();

                    return Column(
                      children: [
                        Slider(
                          value: value.clamp(0.0, maxValue),
                          max: maxValue,
                          onChanged: maxMs <= 0
                              ? null
                              : (v) => _player.seek(
                                    Duration(
                                      milliseconds: v.round(),
                                    ),
                                  ),
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(duration)),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous',
                  onPressed: _loading ? null : _playPrevious,
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 38,
                ),
                const SizedBox(width: 12),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;

                    return IconButton(
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      iconSize: 56,
                    );
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Next',
                  onPressed: _loading ? null : _playNext,
                  icon: const Icon(Icons.skip_next),
                  iconSize: 38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}