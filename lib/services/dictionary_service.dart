import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dictionary_entry.dart';
import 'package:translator/translator.dart';

class DictionaryService {
  static const String primaryApiUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';
  static const String backupApiUrl = 'https://api.wordnik.com/v4/word.json/';
  static const String wordnikApiKey = '?api_key=YOUR_API_KEY_HERE'; // Wordnik API anahtarı alın ve buraya ekleyin
  static const String dataMuse = 'https://api.datamuse.com/words?ml=';
  static const String suggestionsUrl = 'https://api.datamuse.com/sug';
  
  final translator = GoogleTranslator();
  
  // Ana kelime arama metodu
  Future<List<DictionaryEntry>> searchWord(String word) async {
    if (word.isEmpty) return [];
    
    try {
      // İlk olarak birincil API'yi deneyin
      final List<DictionaryEntry>? primaryResults = await _tryPrimaryApi(word);
      if (primaryResults != null && primaryResults.isNotEmpty) {
        // Başarılı sonuçları çevirin ve döndürün
        return await _translateEntries(primaryResults);
      }
      
      // Birincil API başarısız olursa, yedek API'yi deneyin
      final List<DictionaryEntry>? backupResults = await _tryBackupApis(word);
      if (backupResults != null && backupResults.isNotEmpty) {
        // Başarılı sonuçları çevirin ve döndürün
        return await _translateEntries(backupResults);
      }
      
      // Türevleri ve benzer kelimeleri kontrol edin
      final derivedResults = await _findDerivedWords(word);
      if (derivedResults.isNotEmpty) {
        return derivedResults;
      }
      
      // Tüm API'ler başarısız olursa, hata fırlat
      throw Exception('Kelime bulunamadı');
      
    } catch (e) {
      if (e.toString().contains('Kelime bulunamadı')) {
        throw Exception('Kelime bulunamadı');
      }
      throw Exception('Bir hata oluştu: $e');
    }
  }
  
  // Birincil API'den kelimeyi arama
  Future<List<DictionaryEntry>?> _tryPrimaryApi(String word) async {
    try {
      final response = await http.get(Uri.parse('$primaryApiUrl$word'))
          .timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((data) => DictionaryEntry.fromJson(data)).toList();
      }
      return null;
    } catch (e) {
      print('Birincil API hatası: $e');
      return null;
    }
  }
  
  // Yedek API'leri deneme
  Future<List<DictionaryEntry>?> _tryBackupApis(String word) async {
    try {
      // DataMuse API'yi kullanarak benzer ve ilişkili kelimeler bulun
      final dataMuseResponse = await http.get(
        Uri.parse('$dataMuse$word&max=1')
      ).timeout(Duration(seconds: 5));
      
      if (dataMuseResponse.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(dataMuseResponse.body);
        if (jsonData.isNotEmpty) {
          String foundWord = jsonData[0]['word'];
          // Bulunan kelimeyi birincil API ile tekrar deneyin
          return await _tryPrimaryApi(foundWord);
        }
      }
      
      // Gelecekte diğer API'ler eklenebilir
      return null;
    } catch (e) {
      print('Yedek API hatası: $e');
      return null;
    }
  }
  
  // Türevleri ve benzer kelimeleri bulma
  Future<List<DictionaryEntry>> _findDerivedWords(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$dataMuse$word&max=5')
      );
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        
        if (jsonData.isNotEmpty) {
          for (var item in jsonData) {
            String similarWord = item['word'];
            
            // Benzer kelimede API'yi deneyin
            final entries = await _tryPrimaryApi(similarWord);
            if (entries != null && entries.isNotEmpty) {
              // Bir not ekleyin
              DictionaryEntry firstEntry = entries.first;
              DictionaryEntry modifiedEntry = DictionaryEntry(
                word: firstEntry.word,
                phonetic: firstEntry.phonetic,
                phonetics: firstEntry.phonetics,
                meanings: firstEntry.meanings,
                sourceUrl: firstEntry.sourceUrl,
                note: 'Aranan kelime bulunamadı, "$similarWord" benzer kelimesi gösteriliyor.',
              );
              
              return await _translateEntries([modifiedEntry]);
            }
          }
        }
      }
      return [];
    } catch (e) {
      print('Benzer kelime arama hatası: $e');
      return [];
    }
  }
  
  // Kelime önerileri getiren metod
  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$suggestionsUrl?s=$query&max=8')
      );
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData
            .map<String>((item) => item['word'] as String)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Öneri alma hatası: $e');
      return [];
    }
  }
  
  // Girişleri Türkçe'ye çeviren metod
  Future<List<DictionaryEntry>> _translateEntries(List<DictionaryEntry> entries) async {
    List<DictionaryEntry> translatedEntries = [];
    
    for (var entry in entries) {
      List<Meaning> translatedMeanings = [];
      
      // Her bir anlam için tanımları çevir
      for (var meaning in entry.meanings) {
        List<Definition> translatedDefinitions = [];
        
        // Her bir tanımı çevir
        for (var def in meaning.definitions) {
          // Tanımı çevir
          final translatedDefinition = await translator.translate(
            def.definition,
            from: 'en', 
            to: 'tr'
          );
          
          // Eğer örnek varsa çevir, ama orijinal İngilizce örneği de sakla
          String? translatedExample;
          if (def.example != null && def.example!.isNotEmpty) {
            final example = await translator.translate(
              def.example!,
              from: 'en', 
              to: 'tr'
            );
            translatedExample = example.text;
          }
          
          // Çevrilmiş tanımı ekle
          translatedDefinitions.add(Definition(
            definition: translatedDefinition.text,
            example: def.example, // İngilizce örnek
            translatedExample: translatedExample, // Türkçe örnek
            synonyms: def.synonyms,
            antonyms: def.antonyms,
          ));
        }
        
        // Çevrilmiş tanımları ekle
        translatedMeanings.add(Meaning(
          partOfSpeech: await _translatePartOfSpeech(meaning.partOfSpeech),
          definitions: translatedDefinitions,
          synonyms: meaning.synonyms,
          antonyms: meaning.antonyms,
        ));
      }
      
      // Çevrilmiş anlamları ekle
      translatedEntries.add(DictionaryEntry(
        word: entry.word,
        phonetic: entry.phonetic,
        phonetics: entry.phonetics,
        meanings: translatedMeanings,
        sourceUrl: entry.sourceUrl,
        note: entry.note, // Notu dahil et
      ));
    }
    
    return translatedEntries;
  }
  
  // İngilizce sözcük türlerini Türkçe'ye çevirir
  Future<String> _translatePartOfSpeech(String partOfSpeech) async {
    // Yaygın sözcük türleri için önceden tanımlanmış çeviriler
    Map<String, String> partMap = {
      'noun': 'isim',
      'verb': 'fiil',
      'adjective': 'sıfat',
      'adverb': 'zarf',
      'pronoun': 'zamir',
      'preposition': 'edat',
      'conjunction': 'bağlaç',
      'interjection': 'ünlem',
      'determiner': 'belirleyici',
      'exclamation': 'ünlem'
    };
    
    // Eğer sözcük türü haritada varsa, doğrudan çevirisini döndür
    if (partMap.containsKey(partOfSpeech.toLowerCase())) {
      return partMap[partOfSpeech.toLowerCase()]!;
    } else {
      // Eğer sözcük türü haritada yoksa, çeviri API'sini kullan
      final translated = await translator.translate(
        partOfSpeech,
        from: 'en', 
        to: 'tr'
      );
      return translated.text;
    }
  }
}