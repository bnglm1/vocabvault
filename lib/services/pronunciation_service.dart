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

Future<void> _playPronunciation() async {
  if (_isLoadingAudio) return;
  
  setState(() {
    _isLoadingAudio = true;
    _audioError = false;
  });
  
  try {
    String? audioUrl = await PronunciationService.getPronunciationUrl(widget.word.word);
    
    if (audioUrl != null) {
      await _audioPlayer.play(UrlSource(audioUrl));
      
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
          });
        }
      });
    } else {
      throw Exception("Telaffuz bulunamadı");
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoadingAudio = false;
        _audioError = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Telaffuz bulunamadı'),
          backgroundColor: Colors.red.shade400,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}