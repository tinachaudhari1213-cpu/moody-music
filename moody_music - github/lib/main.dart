import 'dart:convert';
import 'dart:math';

import 'offline_music_screen.dart';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'services/api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MoodyMusicApp());
}

// GLOBAL USER DATA

int? currentUserId;
String currentUserName = '';
String currentUserEmail = '';

// MAIN APP

final ValueNotifier<ThemeMode> moodyThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.dark,
);

class MoodyMusicApp extends StatelessWidget {
  const MoodyMusicApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const accent = Color(0xFF9B78D4);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: dark ? const Color(0xFF211D2A) : const Color(0xFFFFFCFF),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF15121B)
          : const Color(0xFFF8F4FB),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF15121B)
            : const Color(0xFFF8F4FB),
        foregroundColor: dark
            ? const Color(0xFFF8F3FF)
            : const Color(0xFF30253D),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF211D2A) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF211D2A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xFF30283B)
            : const Color(0xFF3E3150),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF1D1925) : Colors.white,
        indicatorColor: dark
            ? const Color(0xFF443455)
            : const Color(0xFFECE0F8),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: moodyThemeMode,
      builder: (context, mode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Moody Music',
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: mode,
        home: LoginScreen(),
      ),
    );
  }
}

// HOME SCREEN

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> songs = [];
  bool loading = true;

  final List<Map<String, String>> moods = const [
    {'emoji': '😊', 'name': 'Happy'},
    {'emoji': '😔', 'name': 'Sad'},
    {'emoji': '😌', 'name': 'Calm'},
    {'emoji': '😡', 'name': 'Angry'},
    {'emoji': '❤️', 'name': 'Romantic'},
    {'emoji': '⚡', 'name': 'Energetic'},
    {'emoji': '🌧️', 'name': 'Rainy Romance'},
    {'emoji': '📼', 'name': '90s Classics'},
  ];

  @override
  void initState() {
    super.initState();
    loadSongs();
    
  }
  

  Future<void> loadSongs() async {
    try {
      final result = await ApiService.getSongs();

      if (!mounted) return;

      setState(() {
        songs = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  void openMood(String emoji, String mood) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodScreen(emoji: emoji, mood: mood, songs: songs),
      ),
    );
  }

  
Future<void> surpriseMe() async {
  if (songs.isEmpty) {
    await loadSongs();
  }

  if (songs.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No songs available right now.'),
      ),
    );
    return;
  }

  // Select a random song from the database/API list.
  final random = Random();
  final song = songs[random.nextInt(songs.length)];

  final title = (song['title'] ?? '').toString();
  final artist = (song['artist'] ?? '').toString();

  if (title.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Song title is not available.'),
      ),
    );
    return;
  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Finding a surprise song...')),
  );

  try {
    final results = await ApiService.searchYouTube(
      '$title $artist official song',
    );

    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No YouTube result found. Try again.'),
        ),
      );
      return;
    }

    final first = results.first as Map;
    final videoId =
        (first['video_id'] ?? first['id'] ?? '').toString();

    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('YouTube video ID not found.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YouTubePlayerScreen(
          videoId: videoId,
          title: title,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to play surprise song: $e')),
    );
  }
}


  void openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(songs: songs)),
    );
  }

  void openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    const moodColors = <Color>[
      Color(0xFFF3C7D5),
      Color(0xFFC9C6F2),
      Color(0xFFBCE3D6),
      Color(0xFFF3D3B3),
      Color(0xFFEBC0D8),
      Color(0xFFF4D58D),
      Color(0xFFB9D8E8),
      Color(0xFFD9C3AA),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBFA4E8), Color(0xFF8F72BC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'moody music',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                    color: textColor,
                  ),
                ),
                Text(
                  'YOUR SOUND, YOUR FEELING',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.4,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch appearance',
            onPressed: () {
              moodyThemeMode.value = moodyThemeMode.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSongs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A little music,',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: textColor,
                ),
              ),
              Text(
                'a little more you.',
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: Color(0xFF9B78D4),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hi ${currentUserName.isEmpty ? 'there' : currentUserName} ✨  What are we feeling today?',
                style: TextStyle(fontSize: 14, color: muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFBCA4DE),
                      Color(0xFF8F78B8),
                      Color(0xFF66547F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -8,
                      top: -14,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 115,
                        color: Colors.white.withValues(alpha: .13),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'YOUR DAILY SOUNDTRACK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        const Text(
                          'Let your mood\nchoose the music.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Little moments deserve their own melody.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .85),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 19),
                        FilledButton.icon(
                          onPressed: surpriseMe,
                          icon: const Icon(Icons.shuffle_rounded, size: 18),
                          label: const Text('Surprise me'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF5C4777),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OfflineMusicScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.library_music),
                  label: const Text('Play Offline Music'),
                ),
              ),
              const SizedBox(height: 16),

              /*
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BackendSongsScreen(),
        ),
      );
    },
    icon: const Icon(Icons.cloud_download_outlined),
    label: const Text('Test Backend Songs'),
  ),
),
*/
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              const SizedBox(height: 29),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tune into yourself',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick the feeling that fits right now',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                  Text(
                    '${moods.length} moods',
                    style: TextStyle(
                      fontSize: 11,
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: moods.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final mood = moods[index];
                  final swatch = moodColors[index % moodColors.length];
                  return Material(
                    color: dark ? const Color(0xFF211D2A) : Colors.white,
                    borderRadius: BorderRadius.circular(23),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(23),
                      onTap: () => openMood(mood['emoji']!, mood['name']!),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(
                            color: dark
                                ? Colors.white.withValues(alpha: .055)
                                : const Color(0xFFEAE2F1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 47,
                                  height: 47,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: swatch.withValues(
                                      alpha: dark ? .20 : .52,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    mood['emoji']!,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_outward_rounded,
                                  size: 17,
                                  color: muted,
                                ),
                              ],
                            ),
                            Text(
                              mood['name']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Made for your moment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: openSearch,
                    child: const Text('See all  →'),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (songs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'No songs found yet. Pull down to refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                )
              else
                ...songs
                    .take(4)
                    .map(
                      (song) => SongTile(
                        song: song,
                        onTap: () {
                          final index = songs.indexOf(song);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistScreen(
                                mood: song['mood'] ?? 'Music',
                                songs: songs,
                                initialIndex: index,
                                autoPlay: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 18),
              Text(
                'Your library',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickCard(
                      icon: Icons.favorite_rounded,
                      title: 'Favorites',
                      onTap: openFavorites,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickCard(
                      icon: Icons.history_rounded,
                      title: 'Recently played',
                      onTap: openHistory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  'made for every version of you ♡',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        
onDestinationSelected: (index) {
  if (index == 1) {
    openSearch();
  } else if (index == 2) {
    openFavorites();
  } else if (index == 3) {
    openHistory();
  } else if (index == 4) {
    openProfile();
  }
},

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// QUICK CARD

class QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFB57AFF), size: 30),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}

// SONG TILE

class SongTile extends StatelessWidget {
  final dynamic song;
  final VoidCallback onTap;

  const SongTile({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF9C6BFF), Color(0xFF443075)],
            ),
          ),
          child: const Icon(Icons.music_note),
        ),
        title: Text(
          song['title'] ?? 'Unknown Song',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${song['artist'] ?? 'Unknown Artist'} • ${song['mood'] ?? ''}',
        ),
        trailing: const Icon(
          Icons.play_circle_fill,
          color: Color(0xFFB57AFF),
          size: 35,
        ),
      ),
    );
  }
}

// MOOD SONG SUGGESTIONS: 5 songs for each mood
const Map<String, List<Map<String, String>>> moodSongSuggestions = {
  'Happy': [
    {'title': 'Gallan Goodiyaan', 'artist': 'Dil Dhadakne Do'},
    {'title': 'Badtameez Dil', 'artist': 'Yeh Jawaani Hai Deewani'},
    {'title': 'Zingaat', 'artist': 'Sairat / Dhadak'},
    {'title': 'Gulabi Sadi', 'artist': 'Sanju Rathod'},
    {'title': 'Chaal Turu Turu', 'artist': 'Marathi'},
  ],
  'Sad': [
    {'title': 'Channa Mereya', 'artist': 'Arijit Singh'},
    {'title': 'Agar Tum Saath Ho', 'artist': 'Alka Yagnik, Arijit Singh'},
    {'title': 'Tadap Tadap', 'artist': 'KK'},
    {'title': 'Hi Yaad Tujhi', 'artist': 'Marathi'},
    {'title': 'Saang Mana', 'artist': 'Marathi'},
  ],
  'Calm': [
    {'title': 'Iktara', 'artist': 'Kavita Seth'},
    {
      'title': 'Kun Faya Kun',
      'artist': 'A.R. Rahman, Javed Ali, Mohit Chauhan',
    },
    {'title': 'Phir Le Aya Dil', 'artist': 'Arijit Singh'},
    {'title': 'Maan Udhan Varyache', 'artist': 'Shankar Mahadevan'},
    {'title': 'Oli Ti Maati', 'artist': 'Marathi'},
  ],
  'Angry': [
    {
      'title': 'Sultan Title Track',
      'artist': 'Sukhwinder Singh, Shadab Faridi',
    },
    {'title': 'Zinda', 'artist': 'Siddharth Mahadevan'},
    {'title': 'Apna Time Aayega', 'artist': 'Ranveer Singh'},
    {'title': 'Dolby Walya', 'artist': 'Nagesh Morvekar'},
    {'title': 'Malhari', 'artist': 'Vishal Dadlani'},
  ],
  'Romantic': [
    {'title': 'Tum Se Hi', 'artist': 'Mohit Chauhan'},
    {'title': 'Tum Hi Ho', 'artist': 'Arijit Singh'},
    {'title': 'Raabta', 'artist': 'Arijit Singh'},
    {'title': 'Sukh Kalale', 'artist': 'Marathi'},
    {'title': 'Kevadyacha Paan Tu', 'artist': 'Ajay Gogavale, Aarya Ambekar'},
  ],
  'Energetic': [
    {
      'title': 'Kar Har Maidaan Fateh',
      'artist': 'Sukhwinder Singh, Shreya Ghoshal',
    },
    {'title': 'Jai Jai Shivshankar', 'artist': 'Vishal Dadlani, Benny Dayal'},
    {'title': 'Apsara Aali', 'artist': 'Bela Shende, Ajay Gogavale'},
    {'title': 'Chandra', 'artist': 'Shreya Ghoshal'},
    {'title': 'Zingaat', 'artist': 'Ajay-Atul'},
  ],
  'Rainy Romance': [
    {'title': 'Rimjhim Rimjhim', 'artist': 'Kumar Sanu, Kavita Krishnamurthy'},
    {'title': 'Tip Tip Barsa Paani', 'artist': 'Alka Yagnik, Udit Narayan'},
    {'title': 'Koi Ladki Hai', 'artist': 'Lata Mangeshkar, Udit Narayan'},
    {'title': 'Olya Sanjveli', 'artist': 'Swapnil Bandodkar'},
    {'title': 'Chimba Paavsan Raan', 'artist': 'Marathi'},
  ],
  '90s Classics': [
    {'title': 'Pehla Nasha', 'artist': 'Udit Narayan, Sadhana Sargam'},
    {'title': 'Tujhe Dekha To', 'artist': 'Kumar Sanu, Lata Mangeshkar'},
    {'title': 'Ek Ladki Ko Dekha', 'artist': 'Kumar Sanu'},
    {'title': 'Tu Hi Re', 'artist': 'Hariharan, Kavita Krishnamurthy'},
    {'title': 'Dheere Dheere Se', 'artist': 'Kumar Sanu, Anuradha Paudwal'},
  ],
};

// MOOD SCREEN
class MoodScreen extends StatelessWidget {
  final String emoji;
  final String mood;
  final List<dynamic> songs;

  const MoodScreen({
    super.key,
    required this.emoji,
    required this.mood,
    required this.songs,
  });

  String getRecommendation() {
    switch (mood) {
      case 'Happy':
        return 'Enjoy energetic and cheerful music!';
      case 'Sad':
        return 'Let soothing music help you move toward a calmer mood.';
      case 'Calm':
        return 'Relax with peaceful and soft music.';
      case 'Angry':
        return 'Choose music to release energy and relax.';
      case 'Romantic':
        return 'Enjoy beautiful romantic songs.';
      case 'Energetic':
        return 'Get ready for some high-energy music!';
      case 'Rainy Romance':
        return 'Romantic songs for rainy days and cozy moments.';
      case '90s Classics':
        return 'Revisit evergreen melodies from the 90s.';
      default:
        return 'Here are songs selected for you.';
    }
  }

void _playDatabaseSong(BuildContext context, dynamic song) {
  final selectedMood = mood.trim().toLowerCase();

  final moodSongs = songs.where((item) {
    if (item is! Map) return false;

    final songMood = (item['mood'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return songMood == selectedMood;
  }).toList();

  final selectedIndex = moodSongs.indexWhere((item) {
    if (item is! Map || song is! Map) return false;

    return item['id'].toString() == song['id'].toString();
  });

  if (moodSongs.isEmpty || selectedIndex == -1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No songs found for $mood mood.')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlaylistScreen(
        mood: mood,
        songs: moodSongs,
        initialIndex: selectedIndex,
        autoPlay: true,
      ),
    ),
  );
}

  Future<void> _playSuggestion(
    BuildContext context,
    Map<String, String> song,
  ) async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Searching YouTube...')));
    try {
      final results = await ApiService.searchYouTube(
        '${song['title']} ${song['artist']} official song',
      );
      if (!context.mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No YouTube result found for this song.'),
          ),
        );
        return;
      }
      final first = results.first as Map;
      final videoId = (first['video_id'] ?? first['id'] ?? '').toString();
      if (videoId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The search result has no video ID.')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YouTubePlayerScreen(
            videoId: videoId,
            title: song['title'] ?? 'Song',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to play song: $e')));
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final suggestions = songs.where((song) {
  if (song is! Map) return false;

  final songMood = (song['mood'] ?? '')
      .toString()
      .trim()
      .toLowerCase();

  return songMood == mood.trim().toLowerCase();
}).map<Map<String, String>>((song) {
  return {
    'title': (song['title'] ?? 'Unknown Song').toString(),
    'artist': (song['artist'] ?? 'Unknown Artist').toString(),
  };
}).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Your Mood')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Text(emoji, style: const TextStyle(fontSize: 85)),
            const SizedBox(height: 15),
            Text(
              mood,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              getRecommendation(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: suggestions.isEmpty
    ? null
    : () {
        final selectedSong = songs.firstWhere(
          (item) =>
              item is Map &&
              item['title'] == suggestions.first['title'] &&
              (item['mood'] ?? '').toString().toLowerCase() ==
                  mood.toLowerCase(),
        );

        _playDatabaseSong(context, selectedSong);
      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play First Suggestion'),
              ),
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Songs for your mood (${suggestions.length})',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (suggestions.isNotEmpty)
              ...suggestions.map(
                (song) => SongTile(
                  song: {
                    'title': song['title'] ?? 'Unknown Song',
                    'artist': song['artist'] ?? 'Unknown Artist',
                    'mood': mood,
                  },
                  onTap: () => _playSuggestion(context, song),
                ),
              )
            else
              const Text('No suggestions available for this mood.'),
            const SizedBox(height: 15),
            Text(
              'Online playback requires an internet connection.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// PLAYLIST / MUSIC PLAYER SCREEN

class PlaylistScreen extends StatefulWidget {
  final String mood;
  final List<dynamic> songs;
  final int initialIndex;
  final bool autoPlay;

  const PlaylistScreen({
    super.key,
    required this.mood,
    required this.songs,
    this.initialIndex = 0,
    this.autoPlay = false,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final AudioPlayer _player = AudioPlayer();

  late int currentIndex;

  bool _isPlaying = false;
  bool _songLoaded = false;
  bool _isFavorite = false;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  dynamic get currentSong =>
      widget.songs.isNotEmpty ? widget.songs[currentIndex] : null;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex.clamp(
      0,
      max(0, widget.songs.length - 1),
    );

    _player.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state.playing;
      });
    });

    _player.durationStream.listen((duration) {
      if (!mounted) return;

      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });

    _player.positionStream.listen((position) {
      if (!mounted) return;

      setState(() {
        _position = position;
      });
    });

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadSong();
      });
    }
  }

  String getMoodReason() {
    switch (widget.mood.toLowerCase()) {
      case 'happy':
        return 'This song was selected because its mood matches positive and cheerful energy.';
      case 'sad':
        return 'This song was selected to match your current mood and provide a soothing listening experience.';
      case 'calm':
        return 'This song was selected because it has a relaxing and peaceful mood.';
      case 'angry':
        return 'This song was selected to help shift an intense mood toward a calmer listening experience.';
      case 'romantic':
        return 'This song was selected because it matches a romantic and emotional atmosphere.';
      case 'energetic':
        return 'This song was selected because it matches an energetic and active mood.';
      default:
        return 'This song was selected based on your current mood.';
    }
  }

  String getMoodEmoji() {
    switch (widget.mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😔';
      case 'calm':
        return '😌';
      case 'angry':
        return '😡';
      case 'romantic':
        return '❤️';
      case 'energetic':
        return '⚡';
      default:
        return '🎵';
    }
  }

  Future<void> loadSong() async {
    if (currentSong == null) return;

    try {
      await _player.stop();

      final audioUrl = currentSong['audio_url']?.toString();
      final path = currentSong['file_path']?.toString();
      debugPrint('SONG FILE PATH: $path');
      if (audioUrl != null && audioUrl.isNotEmpty) {
        final uri = Uri.parse(audioUrl);
        final fullUrl = uri.hasScheme
            ? audioUrl
            : '${ApiService.baseUrl}${audioUrl.startsWith('/') ? '' : '/'}$audioUrl';

        await _player.setUrl(fullUrl);
      } else if (path != null && path.isNotEmpty) {
        await _player.setAsset(path);
      } else {
        throw Exception('Song audio is not available.');
      }

      _songLoaded = true;

      if (currentUserId != null && currentSong['id'] != null) {
        try {
          await ApiService.addHistory(
            currentUserId!,
            int.parse(currentSong['id'].toString()),
          );
        } catch (_) {}
      }

      if (!mounted) return;

await loadFavoriteStatus();

if (!mounted) return;

setState(() {});

await _player.play();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not play song: $e')));
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (!_songLoaded) {
          await loadSong();
        } else {
          await _player.play();
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Playback error: $e')));
    }
  }

  Future<void> previousSong() async {
    if (widget.songs.isEmpty) return;

    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    setState(() {
      currentIndex =
          (currentIndex - 1 + widget.songs.length) % widget.songs.length;
      _songLoaded = false;
    });

    await loadSong();
  }

  Future<void> nextSong() async {
    if (widget.songs.isEmpty) return;

    setState(() {
      currentIndex = (currentIndex + 1) % widget.songs.length;
      _songLoaded = false;
    });

    await loadSong();
  }

  

Future<void> addFavorite() async {
  if (currentUserId == null ||
      currentSong == null ||
      currentSong['id'] == null) {
    return;
  }

  final userId = currentUserId!;
  final songId = int.tryParse(currentSong['id'].toString());

  if (songId == null) return;

  final wasFavorite = _isFavorite;

  try {
    if (wasFavorite) {
      await ApiService.removeFavorite(userId, songId);
    } else {
      await ApiService.addFavorite(userId, songId);
    }

    if (!mounted) return;

    setState(() {
      _isFavorite = !wasFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite
              ? 'Removed from favorites 💔'
              : 'Added to favorites ❤️',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Favorite update failed: $e')),
    );
  }
}

Future<void> loadFavoriteStatus() async {
  if (currentUserId == null ||
      currentSong == null ||
      currentSong['id'] == null) {
    return;
  }

  try {
    final songId = int.parse(currentSong['id'].toString());

    final favorites = await ApiService.getFavorites(currentUserId!);

    final isFavorite = favorites.any(
      (song) => song['id'].toString() == songId.toString(),
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = isFavorite;
    });
  } catch (e) {
    debugPrint('Could not load favorite status: $e');
  }
}



  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (currentSong == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Music Player')),
        body: const Center(child: Text('No song available.')),
      );
    }

    final maxSeconds = _duration.inSeconds > 0
        ? _duration.inSeconds.toDouble()
        : 1.0;

    final currentSeconds = _position.inSeconds
        .clamp(0, maxSeconds.toInt())
        .toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(widget.mood), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C6BFF), Color(0xFF443075)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  getMoodEmoji(),
                  style: const TextStyle(fontSize: 100),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Text(
              currentSong['title'] ?? 'Unknown Song',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              currentSong['artist'] ?? 'Unknown Artist',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(_position)),
                Text(formatDuration(_duration)),
              ],
            ),

            Slider(
              value: currentSeconds,
              max: maxSeconds,
              onChanged: (value) {
                _player.seek(Duration(seconds: value.toInt()));
              },
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: previousSong,
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 42,
                ),

                const SizedBox(width: 10),

                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9C6BFF),
                  ),
                  child: IconButton(
                    onPressed: togglePlayPause,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 38,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  onPressed: nextSong,
                  icon: const Icon(Icons.skip_next),
                  iconSize: 42,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _isFavorite ? null : addFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  color: const Color(0xFFFF6B9D),
                  iconSize: 30,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why this song? 🎵',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    getMoodReason(),
                    style: TextStyle(color: Colors.grey.shade400, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// SEARCH SCREEN

class SearchScreen extends StatefulWidget {
  final List<dynamic> songs;

  const SearchScreen({super.key, required this.songs});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> filteredSongs = [];
  List<dynamic> youtubeResults = [];

  bool searchingYouTube = false;

  @override
  void initState() {
    super.initState();
    filteredSongs = List.from(widget.songs);
  }

  void searchLocalSongs(String query) {
    final text = query.trim().toLowerCase();

    setState(() {
      if (text.isEmpty) {
        filteredSongs = List.from(widget.songs);
      } else {
        filteredSongs = widget.songs.where((song) {
          final title = (song['title'] ?? '').toString().toLowerCase();
          final artist = (song['artist'] ?? '').toString().toLowerCase();
          final mood = (song['mood'] ?? '').toString().toLowerCase();

          return title.contains(text) ||
              artist.contains(text) ||
              mood.contains(text);
        }).toList();
      }
    });
  }

  Future<void> searchYouTube() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a song name.')),
      );
      return;
    }

    setState(() {
      searchingYouTube = true;
      youtubeResults = [];
    });

    try {
      final results = await ApiService.searchYouTube(query);

      if (!mounted) return;

      setState(() {
        youtubeResults = results;
        searchingYouTube = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        searchingYouTube = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('YouTube search failed: $e')));
    }
  }

  void openLocalSong(dynamic song) {
    final index = widget.songs.indexOf(song);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(
          mood: song['mood'] ?? 'Music',
          songs: widget.songs,
          initialIndex: index < 0 ? 0 : index,
          autoPlay: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: searchLocalSongs,
              onSubmitted: (_) => searchYouTube(),
              decoration: InputDecoration(
                hintText: 'Search songs, artists or moods...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: searchYouTube,
                  icon: const Icon(Icons.youtube_searched_for),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1720),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Local Songs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (filteredSongs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No local songs found.')),
              )
            else
              ...filteredSongs.map(
                (song) => SongTile(
                  song: song,
                  onTap: () {
                    openLocalSong(song);
                  },
                ),
              ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YouTube',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (searchingYouTube)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (youtubeResults.isEmpty && !searchingYouTube)
              Text(
                'Search for any song on YouTube.',
                style: TextStyle(color: Colors.grey.shade500),
              )
            else
              ...youtubeResults.map((video) => YouTubeResultTile(video: video)),
          ],
        ),
      ),
    );
  }
}

// YOUTUBE RESULT TILE

class YouTubeResultTile extends StatelessWidget {
  final dynamic video;

  const YouTubeResultTile({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final videoId = video['video_id']?.toString() ?? '';

    final title = video['title']?.toString() ?? 'YouTube Video';

    final channel = video['channelTitle']?.toString() ?? 'YouTube';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        leading: Container(
          width: 60,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.red.shade900,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(channel, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.open_in_new),
        onTap: videoId.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        YouTubePlayerScreen(videoId: videoId, title: title),
                  ),
                );
              },
      ),
    );
  }
}

// YOUTUBE PLAYER SCREEN

class YouTubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const YouTubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
      ),
    );
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          YoutubePlayer(controller: controller, aspectRatio: 16 / 9),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// HISTORY SCREEN

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> history = [];
  bool loading = true;

  static const String _historyKey = 'offline_playback_history';

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    final List<dynamic> combinedHistory = [];

    // Load offline history.
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHistory =
          prefs.getStringList(_historyKey) ?? [];

      for (final entry in savedHistory) {
        try {
          final decoded = jsonDecode(entry);

          if (decoded is Map) {
            combinedHistory.add({
              ...Map<String, dynamic>.from(decoded),
              'is_offline_history': true,
            });
          }
        } catch (e) {
          debugPrint('Skipping invalid history entry: $e');
        }
      }
    } catch (e) {
      debugPrint('Offline history error: $e');
    }

    // Load backend history.
    if (currentUserId != null) {
      try {
        final result = await ApiService.getHistory(currentUserId!);

        for (final song in result) {
          combinedHistory.add({
            ...Map<String, dynamic>.from(song),
            'is_offline_history': false,
          });
        }
      } catch (e) {
        debugPrint('Backend history error: $e');
      }
    }

    // Sort newest first.
    DateTime getPlayedAt(dynamic song) {
      final value = song['played_at'] ?? song['playedAt'];

      return DateTime.tryParse(value?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    combinedHistory.sort((a, b) => getPlayedAt(b).compareTo(getPlayedAt(a)));

    if (!mounted) return;

    setState(() {
      history = combinedHistory;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recently Played')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(child: Text('No listening history yet.'))
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final song = history[index];
                  final isOffline = song['is_offline_history'] == true;

                  final songData = {
                    'id': song['song_id'] ?? song['id'],
                    'title': song['title'] ?? 'Unknown Song',
                    'artist':
                        song['artist'] ??
                        (isOffline ? 'Offline Music' : 'Unknown Artist'),
                    'mood': song['mood'] ?? 'Calm',
                    'file_path': isOffline ? song['path'] : song['file_path'],
                    'audio_url': song['audio_url'],
                  };

                  return SongTile(
                    song: songData,
                    onTap: () {
                      if (isOffline) {
                        // Open offline music screen for local songs.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OfflineMusicScreen(),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistScreen(
                            mood: songData['mood'] ?? 'Music',
                            songs: [songData],
                            initialIndex: 0,
                            autoPlay: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

// FAVORITES SCREEN

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> favorites = [];
  bool loading = true;

  static const String _favoritesKey = 'offline_favorite_song_paths';

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final List<dynamic> allFavorites = [];

    // 1. Load offline favorites from phone storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = prefs.getStringList(_favoritesKey) ?? [];

      for (final path in paths) {
        final filename = path
            .split('/')
            .last
            .replaceAll('.mp3', '')
            .replaceAll('_', ' ');

        allFavorites.add({
          'id': 'offline_$path',
          'title': filename,
          'artist': 'Offline Music',
          'mood': 'Offline',
          'file_path': path,
          'is_offline_favorite': true,
        });
      }
    } catch (e) {
      debugPrint('Offline favorites error: $e');
    }

    // 2. Load backend/MySQL favorites
    if (currentUserId != null) {
      try {
        final result = await ApiService.getFavorites(currentUserId!);

        allFavorites.addAll(result);
      } catch (e) {
        debugPrint('Backend favorites error: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      favorites = allFavorites;
      loading = false;
    });
  }

  Future<void> removeFavorite(dynamic song) async {
    try {
      // Remove offline favorite from phone storage
      if (song['is_offline_favorite'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final path = song['file_path']?.toString();

        if (path != null) {
          final paths = prefs.getStringList(_favoritesKey) ?? [];
          paths.remove(path);
          await prefs.setStringList(_favoritesKey, paths);
        }
      } else {
        // Remove backend favorite from MySQL
        if (currentUserId == null) return;

        final songId = song['song_id'] ?? song['id'];
        if (songId == null) return;

        await ApiService.removeFavorite(
          currentUserId!,
          int.parse(songId.toString()),
        );
      }

      await loadFavorites();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove favorite: $e')));

      await loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites ❤️')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
          ? const Center(child: Text('No favorite songs yet.'))
          : RefreshIndicator(
              onRefresh: loadFavorites,
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final song = favorites[index];
                  final isOffline = song['is_offline_favorite'] == true;

                  final songId = song['song_id'] ?? song['id'];

                  return Dismissible(
                    key: ValueKey(
                      isOffline ? song['file_path'] : 'backend_$songId',
                    ),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      removeFavorite(song);
                    },
                    child: SongTile(
                      song: song,
                      onTap: () {
                        final songData = {
                          'id': songId,
                          'title': song['title'],
                          'artist': song['artist'],
                          'mood': song['mood'],
                          'file_path': song['file_path'],
                          'audio_url': song['audio_url'],
                        };

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistScreen(
                              mood: songData['mood'] ?? 'Music',
                              songs: [songData],
                              initialIndex: 0,
                              autoPlay: true,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// PROFILE SCREEN

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void openMoodJourney(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MoodJourneyScreen()),
    );
  }

  void logout(BuildContext context) {
    currentUserId = null;
    currentUserName = '';
    currentUserEmail = '';

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),

            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF9C6BFF),
              child: Text(
                currentUserName.isEmpty
                    ? '?'
                    : currentUserName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              currentUserName.isEmpty ? 'Music Lover' : currentUserName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              currentUserEmail,
              style: TextStyle(color: Colors.grey.shade400),
            ),

            const SizedBox(height: 30),

            ProfileOption(
              icon: Icons.route,
              title: 'Mood Journey',
              subtitle: 'See your mood-based listening journey',
              onTap: () => openMoodJourney(context),
            ),

            ProfileOption(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences and theme',
              onTap: () => openSettings(context),
            ),

            ProfileOption(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

// PROFILE OPTION

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFF9C6BFF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFB57AFF)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// MOOD JOURNEY SCREEN

class MoodJourneyScreen extends StatefulWidget {
  const MoodJourneyScreen({super.key});

  @override
  State<MoodJourneyScreen> createState() => _MoodJourneyScreenState();
}

class _MoodJourneyScreenState extends State<MoodJourneyScreen> {
  List<dynamic> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadJourney();
  }

  Future<void> loadJourney() async {
    if (currentUserId == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      final result = await ApiService.getHistory(currentUserId!);

      if (!mounted) return;

      setState(() {
        history = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  String emojiForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😔';
      case 'calm':
        return '😌';
      case 'angry':
        return '😡';
      case 'romantic':
        return '❤️';
      case 'energetic':
        return '⚡';
      default:
        return '🎵';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Journey')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(
              child: Text(
                'Start listening to songs to build your Mood Journey.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];

                final mood = item['mood']?.toString() ?? 'Music';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1720),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        emojiForMood(mood),
                        style: const TextStyle(fontSize: 35),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']?.toString() ?? 'Unknown Song',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              mood,
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// SETTINGS SCREEN

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool autoplay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          
Card(
  child: RadioGroup<ThemeMode>(
    groupValue: moodyThemeMode.value,
    onChanged: (ThemeMode? value) {
      if (value != null) {
        moodyThemeMode.value = value;
      }
    },
    child: Column(
      children: [
        RadioListTile<ThemeMode>(
          value: ThemeMode.system,
          title: const Text('Match device theme'),
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.light,
          title: const Text('Light mode'),
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.dark,
          title: const Text('Dark mode'),
        ),
      ],
    ),
  ),
),


          const SizedBox(height: 15),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive music recommendations'),
                  value: notifications,
                  onChanged: (value) {
                    setState(() {
                      notifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Autoplay'),
                  subtitle: const Text('Automatically play selected songs'),
                  value: autoplay,
                  onChanged: (value) {
                    setState(() {
                      autoplay = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moody Music',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'A mood-based music recommendation application with local and YouTube music support.',
                ),
                SizedBox(height: 10),
                Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// LOGIN SCREEN


 // LOGIN SCREEN

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

Future<void> login() async {
  final email = emailController.text.trim();
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter email and password.'),
      ),
    );
    return;
  }

  setState(() {
    loading = true;
  });

  try {
    debugPrint('LOGIN: Sending request to backend');

    final result = await ApiService.loginUser(
      email: email,
      password: password,
    );

    debugPrint('LOGIN RESULT: $result');

    if (!mounted) return;

    if (result['success'] != true) {
      throw Exception(
        result['message']?.toString() ?? 'Login failed',
      );
    }

    // Backend returns user_id, username and email directly.
    currentUserId = int.tryParse(
      result['user_id']?.toString() ?? '',
    );

    currentUserName =
        result['username']?.toString() ?? '';

    currentUserEmail =
        result['email']?.toString() ?? email;

    if (currentUserId == null) {
      throw Exception('User ID missing from server response.');
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  } catch (e) {
    debugPrint('LOGIN ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login failed: $e'),
        duration: const Duration(seconds: 5),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}


  void openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moody Music'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const Text('🎧', style: TextStyle(fontSize: 75)),
                const SizedBox(height: 15),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to discover music for your mood.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: openRegister,
                  child: const Text(
                    "Don't have an account? Register",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// REGISTER SCREEN

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  Future<void> register() async {
    final name = nameController.text.trim();

    final email = emailController.text.trim();

    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must contain at least 6 characters.'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await ApiService.registerUser(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text('🎧', style: TextStyle(fontSize: 70)),

              const SizedBox(height: 15),

              const Text(
                'Join Moody Music',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
