import 'word.dart';

class UserProfile {
  String userId;
  List<Word> learnedWords;
  Map<String, int> quizScores;

  UserProfile({required this.userId, required this.learnedWords, required this.quizScores});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<Word> words = (json['learnedWords'] as List).map((i) => Word.fromMap(i, i['id'])).toList();
    Map<String, int> scores = Map<String, int>.from(json['quizScores']);
    
    return UserProfile(
      userId: json['userId'],
      learnedWords: words,
      quizScores: scores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'learnedWords': learnedWords.map((word) => word.toMap()).toList(),
      'quizScores': quizScores,
    };
  }
}