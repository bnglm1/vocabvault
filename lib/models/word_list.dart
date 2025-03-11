import 'word.dart';

class WordList {
  final String id;
  final String name;
  final List<Word> words;

  WordList({required this.id, required this.name, required this.words});

  factory WordList.fromMap(Map<String, dynamic> data, String documentId) {
    var wordsFromMap = data['words'] as List<dynamic>;
    List<Word> wordsList = wordsFromMap.map((wordData) {
      return Word.fromMap(wordData as Map<String, dynamic>, wordData['id'] ?? '');
    }).toList();

    return WordList(
      id: documentId,
      name: data['name'] ?? '',
      words: wordsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'words': words.map((word) => word.toMap()).toList(),
    };
  }
}