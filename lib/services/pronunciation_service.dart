import 'package:http/http.dart' as http;


class PronunciationService {
  static Future<String?> getPronunciationUrl(String word) async {
    List<String> apiEndpoints = [
      "https://ssl.gstatic.com/dictionary/static/sounds/oxford/${word.toLowerCase()}--_us_1.mp3",
      "https://media.merriam-webster.com/audio/prons/en/us/mp3/${word.toLowerCase()[0]}/${word.toLowerCase()}.mp3",
      "https://www.howjsay.com/mp3/${word.toLowerCase()}.mp3"
    ];
    
    for (var url in apiEndpoints) {
      try {
        final response = await http.head(Uri.parse(url));
        if (response.statusCode == 200) {
          return url;
        }
      } catch (e) {
        continue;
      }
    }
    
    return null;
  }
}