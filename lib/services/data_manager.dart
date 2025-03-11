import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/word.dart';
import '../models/user_profile.dart';
import 'package:vocabvault2/models/word_list.dart';

class DataManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Word>> loadWords() async {
    CollectionReference wordsCollection = _firestore.collection('words');
    QuerySnapshot querySnapshot = await wordsCollection.get();
    return querySnapshot.docs.map((doc) => Word.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  static Future<void> saveQuizScore(int score) async {
    CollectionReference scoresCollection = _firestore.collection('quizScores');
    await scoresCollection.add({
      'timestamp': DateTime.now().toIso8601String(),
      'score': score,
    });
  }

  static Future<Map<String, int>> loadQuizScores() async {
    CollectionReference scoresCollection = _firestore.collection('quizScores');
    QuerySnapshot querySnapshot = await scoresCollection.get();
    Map<String, int> scores = {};
    for (var doc in querySnapshot.docs) {
      scores[doc['timestamp']] = doc['score'];
    }
    return scores;
  }

  static Future<void> saveProfile(UserProfile profile) async {
    DocumentReference profileDoc = _firestore.collection('profiles').doc(profile.userId);
    await profileDoc.set(profile.toJson());
  }

  static Future<UserProfile> loadProfile(String userId) async {
    DocumentReference profileDoc = _firestore.collection('profiles').doc(userId);
    DocumentSnapshot docSnapshot = await profileDoc.get();
    if (docSnapshot.exists) {
      return UserProfile.fromJson(docSnapshot.data() as Map<String, dynamic>);
    }
    return UserProfile(userId: userId, learnedWords: [], quizScores: {});
  }

  static Future<void> saveWordLists(List<WordList> wordLists) async {
    CollectionReference wordListsCollection = _firestore.collection('wordLists');
    for (WordList wordList in wordLists) {
      await wordListsCollection.doc(wordList.id).set(wordList.toMap());
    }
  }

  static Future<List<WordList>> loadWordLists() async {
    CollectionReference wordListsCollection = _firestore.collection('wordLists');
    QuerySnapshot querySnapshot = await wordListsCollection.get();
    return querySnapshot.docs.map((doc) => WordList.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }
}