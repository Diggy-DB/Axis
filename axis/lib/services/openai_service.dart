import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reflection.dart';
import '../models/user.dart';
import '../models/task.dart';

class OpenAIService {
  final String apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIService({required this.apiKey});

  /// Generate next day's reflection prompt based on today's reflection
  Future<String> generateNextDayPrompt({
    required Reflection todayReflection,
    required UserModel user,
    List<Reflection>? previousReflections,
  }) async {
    final userContext = _buildUserContext(user);
    final reflectionHistory =
        _buildReflectionHistory(previousReflections ?? []);

    final prompt = '''
You are a personalized AI coach for ${user.firstName ?? 'the user'}. 

USER PROFILE:
$userContext

RECENT REFLECTION HISTORY:
$reflectionHistory

TODAY'S REFLECTION:
Mood: ${todayReflection.mood}/10
Energy: ${todayReflection.energy}/10
Text: ${todayReflection.text}
${todayReflection.gratitude != null ? 'Gratitude: ${todayReflection.gratitude}' : ''}
${todayReflection.challenges != null ? 'Challenges: ${todayReflection.challenges}' : ''}
${todayReflection.wins != null ? 'Wins: ${todayReflection.wins}' : ''}

Based on today's reflection and the user's profile, generate a thoughtful, encouraging prompt for tomorrow's reflection. The prompt should:
1. Address any concerns or challenges mentioned
2. Build on their wins and positive moments
3. Align with their core values and ambitions
4. Be personal, warm, and motivating
5. Be 2-3 sentences maximum

Generate only the prompt text, nothing else.
''';

    return await _callOpenAI(prompt);
  }

  /// Generate daily summary message for home page
  Future<String> generateDailySummary({
    required Reflection reflection,
    required UserModel user,
    required List<Task> completedTasks,
    required double productiveHours,
    List<Reflection>? previousReflections,
  }) async {
    final userContext = _buildUserContext(user);
    final reflectionHistory =
        _buildReflectionHistory(previousReflections ?? []);

    final prompt = '''
You are a personalized AI coach for ${user.firstName ?? 'the user'}.

USER PROFILE:
$userContext

RECENT REFLECTION HISTORY:
$reflectionHistory

YESTERDAY'S PERFORMANCE:
- Tasks completed: ${completedTasks.length}
- Productive hours: ${productiveHours.toStringAsFixed(1)}
- Mood: ${reflection.mood}/10
- Energy: ${reflection.energy}/10

YESTERDAY'S REFLECTION:
${reflection.text}
${reflection.gratitude != null ? '\nGratitude: ${reflection.gratitude}' : ''}
${reflection.challenges != null ? '\nChallenges: ${reflection.challenges}' : ''}
${reflection.wins != null ? '\nWins: ${reflection.wins}' : ''}

Generate a warm, encouraging daily summary message that:
1. Celebrates their achievements
2. Acknowledges their challenges with empathy
3. Highlights patterns or improvements you notice
4. Motivates them for today
5. Aligns with their values and ambitions
6. Is conversational and personal (2-4 sentences)

Generate only the message text, nothing else.
''';

    return await _callOpenAI(prompt);
  }

  /// Extract key insight from reflection
  Future<String?> extractKeyInsight({
    required Reflection reflection,
    required UserModel user,
  }) async {
    if (reflection.text.trim().length < 50) return null;

    final userContext = _buildUserContext(user);

    final prompt = '''
You are analyzing a reflection for ${user.firstName ?? 'the user'}.

USER PROFILE:
$userContext

REFLECTION:
${reflection.text}
${reflection.challenges != null ? '\nChallenges: ${reflection.challenges}' : ''}
${reflection.wins != null ? '\nWins: ${reflection.wins}' : ''}

Extract one key insight or pattern from this reflection that relates to the user's growth, values, or ambitions. Be specific and actionable.

Return only the insight in one sentence (max 20 words).
''';

    return await _callOpenAI(prompt);
  }

  String _buildUserContext(UserModel user) {
    return '''
Name: ${user.firstName ?? 'User'}
Core Values: ${user.coreValues ?? 'Not specified'}
Worldview & Purpose: ${user.worldview ?? 'Not specified'}
Ambitions: ${user.ambition ?? 'Not specified'}
''';
  }

  String _buildReflectionHistory(List<Reflection> reflections) {
    if (reflections.isEmpty) return 'No previous reflections';

    final recent = reflections.take(5).toList();
    return recent.map((r) {
      return '${r.date.toString().split(' ')[0]}: Mood ${r.mood}/10, Energy ${r.energy}/10 - ${r.preview}';
    }).join('\n');
  }

  Future<String> _callOpenAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini', // Using cost-effective model
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a thoughtful, empathetic AI coach who helps people with personal growth through reflection.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        print('OpenAI API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate AI response');
      }
    } catch (e) {
      print('Error calling OpenAI: $e');
      rethrow;
    }
  }
}
