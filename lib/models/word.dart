class Word {
  final String id;
  final String word;
  final String meaning;
  final String exampleSentence; // Yeni parametre

  Word({required this.id, required this.word, required this.meaning, required this.exampleSentence});

  factory Word.fromMap(Map<String, dynamic> data, String documentId) {
    return Word(
      id: documentId,
      word: data['word'] ?? '',
      meaning: data['meaning'] ?? '',
      exampleSentence: data['exampleSentence'] ?? '', // Yeni parametre
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'meaning': meaning,
      'exampleSentence': exampleSentence, // Yeni parametre
    };
  }
}