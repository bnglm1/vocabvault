import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ExampleSentenceService {
  static const String dictApiUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';
  static const String wordnikApiUrl = 'https://api.wordnik.com/v4/word.json/';
  static const String wordnikApiKey = 'YOUR_API_KEY_HERE'; // İsteğe bağlı
  
  // Birincil API: Free Dictionary API
  static Future<String?> getExampleFromDictApi(String word) async {
    try {
      final response = await http.get(Uri.parse('$dictApiUrl$word'))
          .timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        // API yanıtından örnek cümleyi çıkar
        for (var entry in data) {
          if (entry['meanings'] != null) {
            for (var meaning in entry['meanings']) {
              if (meaning['definitions'] != null) {
                for (var definition in meaning['definitions']) {
                  if (definition['example'] != null && definition['example'].toString().isNotEmpty) {
                    return definition['example'];
                  }
                }
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Example sentence api error: $e');
      return null;
    }
  }

  // İkincil API: DataMuse
  static Future<String?> getExampleFromDataMuse(String word) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.datamuse.com/words?sp=$word&md=d&max=1')
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['defs'] != null) {
          // DataMuse sadece tanım verir, cümle vermez
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Wordnik API - isteğe bağlı
  static Future<String?> getExampleFromWordnik(String word) async {
    // API key gerektiriyor, isterseniz ekleyin
    if (wordnikApiKey == 'YOUR_API_KEY_HERE') return null;
    
    try {
      final response = await http.get(
        Uri.parse('$wordnikApiUrl$word/examples?limit=1&api_key=$wordnikApiKey')
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['examples'] != null && data['examples'].isNotEmpty) {
          return data['examples'][0]['text'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Ana metod - tüm API'leri deneyin, bulunamazsa boş döndürün
  static Future<String> getExampleSentence(String word) async {
    if (word.isEmpty) return '';
    
    // API'ler sırayla denenir
    String? example = await getExampleFromDictApi(word);
    
    if (example == null) {
      example = await getExampleFromDataMuse(word);
    }
    
    if (example == null) {
      example = await getExampleFromWordnik(word);
    }
    
    // Hiçbir API sonuç vermezse, boş string döndür
    return example ?? '';
  }
}