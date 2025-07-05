import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static const String _cachePrefix = 'translation_';
  static String _currentLanguage = 'tr'; // Varsayılan Türkçe

  // Basit çeviri metinleri (offline kullanım için)
  static final Map<String, Map<String, String>> _localTranslations = {
    'tr': {
      'app_title': 'VocabVault',
      'home': 'Ana Sayfa',
      'word_lists': 'Kelime Listeleri',
      'flashcards': 'Kelime Kartları',
      'dictionary': 'Sözlük',
      'settings': 'Ayarlar',
      'language': 'Dil',
      'turkish': 'Türkçe',
      'english': 'İngilizce',
      'touch_to_flip': 'Çevirmek için dokunun',
      'pronunciation_not_found': 'Telaffuz bulunamadı',
      'understand': 'Anladım',
      'how_to_use_flashcards': 'Kelime Kartları Nasıl Kullanılır?',
      'dark_mode': 'Karanlık Mod',
      'notifications': 'Bildirimler',
      'language_settings': 'Dil Ayarları'
    },
    'en': {
      'app_title': 'VocabVault',
      'home': 'Home',
      'word_lists': 'Word Lists',
      'flashcards': 'Flashcards',
      'dictionary': 'Dictionary',
      'settings': 'Settings',
      'language': 'Language',
      'turkish': 'Turkish',
      'english': 'English',
      'touch_to_flip': 'Touch to flip',
      'pronunciation_not_found': 'Pronunciation not found',
      'understand': 'I Understand',
      'how_to_use_flashcards': 'How to Use Flashcards?',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'language_settings': 'Language Settings'
    }
  };

  // Dil kodunu yükle
  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'tr';
  }

  // Dili değiştir
  static Future<void> changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    _currentLanguage = languageCode;
  }

  // Geçerli dil kodunu al
  static String getCurrentLanguage() {
    return _currentLanguage;
  }
  
  // Dil adını göster
  static String getLanguageName() {
    return _currentLanguage == 'tr' ? 'Türkçe' : 'English';
  }

  // Çeviri al (önce önbellekten, sonra yerel çevirilerden, gerekirse API'den)
  static Future<String> translate(String key) async {
    // 1. Önce yerel çevirilerden kontrol et
    if (_localTranslations.containsKey(_currentLanguage) && 
        _localTranslations[_currentLanguage]!.containsKey(key)) {
      return _localTranslations[_currentLanguage]![key]!;
    }
    
    // 2. Önbellekte var mı kontrol et
    final prefs = await SharedPreferences.getInstance();
    final cachedTranslation = prefs.getString('$_cachePrefix${_currentLanguage}_$key');
    if (cachedTranslation != null) {
      return cachedTranslation;
    }
    
    // 3. API'den çeviriyi al
    try {
      // Ücretsiz çeviri API'si
      final response = await http.get(
        Uri.parse('https://api.mymemory.translated.net/get?q=$key&langpair=en|$_currentLanguage')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation = data['responseData']['translatedText'];
        
        // Önbelleğe kaydet
        await prefs.setString('$_cachePrefix${_currentLanguage}_$key', translation);
        return translation;
      }
    } catch (e) {
      print('Translation API error: $e');
    }
    
    // 4. Hiçbiri başarılı olmazsa orijinal metni döndür
    return key;
  }
}