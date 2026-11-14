import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MoodDetectionScreen extends StatefulWidget {
  const MoodDetectionScreen({super.key});

  @override
  State<MoodDetectionScreen> createState() =>
      _MoodDetectionScreenState();
}

class _MoodDetectionScreenState
    extends State<MoodDetectionScreen> {
  final TextEditingController feelingController =
      TextEditingController();

  bool isLoading = false;
  String? detectedMood;

  String moodEmoji(String mood) {
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

  Future<void> detectMood() async {
    final text = feelingController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please tell me how you are feeling.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      detectedMood = null;
    });

    try {
      final result = await ApiService.predictMood(text);

      if (!mounted) return;

      setState(() {
        detectedMood = result['mood']?.toString();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    feelingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mood Detection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.psychology,
              size: 80,
              color: Colors.deepPurpleAccent,
            ),

            const SizedBox(height: 20),

            const Text(
              'How are you feeling today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Describe your feelings and AI will detect your mood.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: feelingController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Example: I am feeling very happy today...',
                filled: true,
                fillColor: const Color(0xFF1A1A23),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading ? null : detectMood,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                      ),
                label: Text(
                  isLoading
                      ? 'Detecting...'
                      : 'Detect My Mood',
                ),
              ),
            ),

            if (detectedMood != null) ...[
              const SizedBox(height: 35),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        Colors.deepPurple.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Detected Mood',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      moodEmoji(detectedMood!),
                      style: const TextStyle(
                        fontSize: 55,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      detectedMood!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}