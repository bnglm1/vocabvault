import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WordOfDayService {
  // Yerel önbellek anahtarları
  static const String cacheKey = 'word_of_day_cache';
  static const String cacheDateKey = 'word_of_day_date';

  // API başarısız olursa kelime havuzundan seçim yap
  static Future<Map<String, dynamic>> getWordOfDay({bool forceRefresh = false}) async {
    try {
      // Günün tarihini kontrol et
      final currentDate = _getCurrentDateString();
      final prefs = await SharedPreferences.getInstance();
      
      // Bugün için önbellekte kelime var mı kontrol et
      // forceRefresh = true ise önbelleği atlayıp yeni kelime seç
      if (!forceRefresh) {
        final cachedDate = prefs.getString(cacheDateKey);
        if (cachedDate == currentDate) {
          final cachedWord = prefs.getString(cacheKey);
          if (cachedWord != null) {
            return json.decode(cachedWord);
          }
        }
      }
      
      // Günün kelimesini seç (tamamen yerel, API kullanma)
      final word = _getLocalWordDictionary()[DateTime.now().day % _getLocalWordDictionary().length];
      
      // Sonucu önbelleğe al
      await prefs.setString(cacheKey, json.encode(word));
      await prefs.setString(cacheDateKey, currentDate);
      
      return word;
    } catch (e) {
      print('Günün kelimesini getirirken hata: $e');
      // Güvenli bir kelime dön
      return _getLocalWordDictionary()[0];
    }
  }
  
  // Tarih formatını oluştur
  static String _getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  // Tam kapsamlı yerel kelime sözlüğü
  static List<Map<String, dynamic>> _getLocalWordDictionary() {
    return [
      {
        'word': 'serendipity',
        'partOfSpeech': 'isim',
        'meaning': {
          'en': 'the occurrence and development of events by chance in a happy or beneficial way',
          'tr': 'şans eseri güzel bir şey bulmak'
        },
        'example': 'Finding that rare book was pure serendipity.',
        'exampleTranslation': 'O nadir kitabı bulmak tamamen şans eseriydi.',
        'synonyms': ['chance', 'fortune', 'luck', 'coincidence'],
        'pronunciation': '/ˌsɛrənˈdɪpɪti/'
      },
      {
        'word': 'eloquent',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'fluent or persuasive in speaking or writing',
          'tr': 'akıcı ve ikna edici konuşma yeteneğine sahip'
        },
        'example': 'Her eloquent speech moved the entire audience.',
        'exampleTranslation': 'Onun akıcı konuşması tüm izleyicileri etkiledi.',
        'synonyms': ['fluent', 'articulate', 'expressive', 'silver-tongued'],
        'pronunciation': '/ˈɛləkwənt/'
      },
      {
        'word': 'perseverance',
        'partOfSpeech': 'isim',
        'meaning': {
          'en': 'persistence in doing something despite difficulty or delay in achieving success',
          'tr': 'zorluklara rağmen bir şeyi yapmakta ısrar etme, azim'
        },
        'example': 'His perseverance in the face of adversity was admirable.',
        'exampleTranslation': 'Zorluklar karşısında gösterdiği azim takdire şayandı.',
        'synonyms': ['persistence', 'determination', 'tenacity', 'steadfastness'],
        'pronunciation': '/ˌpərsəˈvɪrəns/'
      },
      {
        'word': 'ephemeral',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'lasting for a very short time',
          'tr': 'çok kısa süren, geçici'
        },
        'example': 'Fashions are ephemeral: they come and go quickly.',
        'exampleTranslation': 'Modalar geçicidir: hızla gelir ve giderler.',
        'synonyms': ['fleeting', 'transitory', 'short-lived', 'momentary'],
        'pronunciation': '/əˈfɛmərəl/'
      },
      {
        'word': 'ambiguous',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'open to more than one interpretation; not having one obvious meaning',
          'tr': 'birden fazla anlama gelebilen, belirsiz'
        },
        'example': 'His statement was ambiguous and could be interpreted in different ways.',
        'exampleTranslation': 'Açıklaması belirsizdi ve farklı şekillerde yorumlanabilirdi.',
        'synonyms': ['equivocal', 'unclear', 'vague', 'indefinite'],
        'pronunciation': '/æmˈbɪɡjuəs/'
      },
      {
        'word': 'mellifluous',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': '(of a sound) pleasingly smooth and musical to hear',
          'tr': 'kulağa bal gibi tatlı gelen, ahenkli'
        },
        'example': 'She had a mellifluous voice that captivated the listeners.',
        'exampleTranslation': 'Dinleyicileri büyüleyen ahenkli bir sesi vardı.',
        'synonyms': ['sweet-sounding', 'melodious', 'honeyed', 'euphonious'],
        'pronunciation': '/məˈlɪfluəs/'
      },
      {
        'word': 'ubiquitous',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'present, appearing, or found everywhere',
          'tr': 'her yerde var olan, yaygın'
        },
        'example': 'Mobile phones are now ubiquitous in modern society.',
        'exampleTranslation': 'Cep telefonları artık modern toplumda her yerde bulunuyor.',
        'synonyms': ['omnipresent', 'ever-present', 'pervasive', 'universal'],
        'pronunciation': '/juːˈbɪkwɪtəs/'
      },
      {
        'word': 'quintessential',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'representing the most perfect or typical example of a quality or class',
          'tr': 'bir şeyin en mükemmel örneği, özü'
        },
        'example': 'He is the quintessential English gentleman.',
        'exampleTranslation': 'O, tipik bir İngiliz beyefendisidir.',
        'synonyms': ['archetypal', 'classic', 'definitive', 'representative'],
        'pronunciation': '/ˌkwɪntɪˈsɛnʃəl/'
      },
      {
        'word': 'meticulous',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'showing great attention to detail; very careful and precise',
          'tr': 'ayrıntılara çok dikkat eden, titiz'
        },
        'example': 'His meticulous research led to an important discovery.',
        'exampleTranslation': 'Titiz araştırması önemli bir keşfe yol açtı.',
        'synonyms': ['thorough', 'careful', 'precise', 'fastidious'],
        'pronunciation': '/məˈtɪkjələs/'
      },
      {
        'word': 'resilient',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'able to withstand or recover quickly from difficult conditions',
          'tr': 'zorluklardan çabuk toparlanabilen, esnek, dayanıklı'
        },
        'example': 'Children are often remarkably resilient in the face of hardship.',
        'exampleTranslation': 'Çocuklar genellikle zorluklar karşısında şaşırtıcı derecede esnektir.',
        'synonyms': ['hardy', 'adaptable', 'buoyant', 'strong'],
        'pronunciation': '/rɪˈzɪliənt/'
      },
      {
        'word': 'paradigm',
        'partOfSpeech': 'isim',
        'meaning': {
          'en': 'a typical example or pattern of something; a model',
          'tr': 'örnek model, düşünce kalıbı'
        },
        'example': 'The discovery led to a new paradigm in scientific thinking.',
        'exampleTranslation': 'Keşif, bilimsel düşüncede yeni bir model oluşmasına yol açtı.',
        'synonyms': ['model', 'pattern', 'example', 'archetype'],
        'pronunciation': '/ˈpærəˌdaɪm/'
      },
      {
        'word': 'benevolent',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'well meaning and kindly',
          'tr': 'hayırsever, iyiliksever'
        },
        'example': 'The benevolent donor wished to remain anonymous.',
        'exampleTranslation': 'İyiliksever bağışçı anonim kalmayı diledi.',
        'synonyms': ['kind', 'charitable', 'generous', 'philanthropic'],
        'pronunciation': '/bəˈnɛvələnt/'
      },
      {
        'word': 'ethereal',
        'partOfSpeech': 'sıfat',
        'meaning': {
          'en': 'extremely delicate and light in a way that seems too perfect for this world',
          'tr': 'çok narin ve hafif, dünyevi olmayan'
        },
        'example': 'Her ethereal beauty captivated everyone in the room.',
        'exampleTranslation': 'Onun dünyevi olmayan güzelliği odadaki herkesi büyüledi.',
        'synonyms': ['delicate', 'exquisite', 'heavenly', 'celestial'],
        'pronunciation': '/ɪˈθɪəriəl/'
      }
    ];
  }
}