import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get openAIApiKey {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'your_openai_api_key_here') {
      throw Exception(
        'OPENAI_API_KEY not configured. Please set it in your .env file.',
      );
    }
    return key;
  }

  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}
