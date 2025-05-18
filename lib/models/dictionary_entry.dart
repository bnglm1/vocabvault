class DictionaryEntry {
  final String word;
  final String? phonetic;
  final List<Phonetic> phonetics;
  final List<Meaning> meanings;
  final String? sourceUrl;
  final String? note; // Not alanı ekledik

  DictionaryEntry({
    required this.word,
    this.phonetic,
    required this.phonetics,
    required this.meanings,
    this.sourceUrl,
    this.note,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    List<Meaning> meanings = [];
    if (json['meanings'] != null) {
      meanings = List<Meaning>.from(
        json['meanings'].map((x) => Meaning.fromJson(x)),
      );
    }

    List<Phonetic> phonetics = [];
    if (json['phonetics'] != null) {
      phonetics = List<Phonetic>.from(
        json['phonetics'].map((x) => Phonetic.fromJson(x)),
      );
    }

    return DictionaryEntry(
      word: json['word'] ?? '',
      phonetic: json['phonetic'],
      phonetics: phonetics,
      meanings: meanings,
      sourceUrl: json['sourceUrl'],
      note: null, // Varsayılan olarak not yok
    );
  }
}

class Phonetic {
  final String? text;
  final String? audio;

  Phonetic({this.text, this.audio});

  factory Phonetic.fromJson(Map<String, dynamic> json) {
    return Phonetic(
      text: json['text'],
      audio: json['audio'],
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;
  final List<String>? synonyms;
  final List<String>? antonyms;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
    this.synonyms,
    this.antonyms,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    List<Definition> definitions = [];
    if (json['definitions'] != null) {
      definitions = List<Definition>.from(
        json['definitions'].map((x) => Definition.fromJson(x)),
      );
    }

    return Meaning(
      partOfSpeech: json['partOfSpeech'] ?? '',
      definitions: definitions,
      synonyms: json['synonyms'] != null ? List<String>.from(json['synonyms']) : [],
      antonyms: json['antonyms'] != null ? List<String>.from(json['antonyms']) : [],
    );
  }
}

class Definition {
  final String definition; // Türkçe tanım
  final String? example; // İngilizce örnek
  final String? translatedExample; // Türkçe örnek
  final List<String>? synonyms;
  final List<String>? antonyms;

  Definition({
    required this.definition,
    this.example,
    this.translatedExample,
    this.synonyms,
    this.antonyms,
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] ?? '',
      example: json['example'],
      translatedExample: null, // Çeviri işlemi sonradan yapılacak
      synonyms: json['synonyms'] != null ? List<String>.from(json['synonyms']) : [],
      antonyms: json['antonyms'] != null ? List<String>.from(json['antonyms']) : [],
    );
  }
}