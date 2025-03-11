import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocabvault2/models/word_list.dart';
import '../models/word.dart';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/quiz_result.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.wordList});

  final WordList wordList;

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Word> words = [];
  int currentIndex = 0;
  int score = 0;
  bool isLoading = true;
  Random random = Random();
  int questionType = 0; // 0: Türkçe -> İngilizce, 1: İngilizce -> Türkçe, 2: Yazma Görevi
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  List<bool> answers = [];
  final TextEditingController _textEditingController = TextEditingController();
  late DateTime quizStartTime;

  @override
  void initState() {
    super.initState();
    quizStartTime = DateTime.now(); // Quiz başladığında tarih ve saat bilgisini kaydet
    _showWordListDialog();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7690250755006392/9374915842', // Replace with your actual Ad Unit ID
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _showWordListDialog() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wordLists')
          .get();

      List<WordList> wordLists = querySnapshot.docs
          .map((doc) => WordList.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Kelime Listesi Seçin'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: wordLists.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(wordLists[index].name),
                    onTap: () {
                      Navigator.of(context).pop();
                      _loadWords(wordLists[index].id);
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _loadWords(String listId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wordLists')
          .doc(listId)
          .get();

      List<Word> loadedWords = (docSnapshot['words'] as List)
          .map((wordData) => Word.fromMap(wordData as Map<String, dynamic>, docSnapshot.id))
          .toList();

      setState(() {
        words = loadedWords;
        isLoading = false;
        _nextQuestion();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading words: $e');
    }
  }

  void _nextQuestion() {
    setState(() {
      questionType = random.nextInt(3); // 0: Türkçe -> İngilizce, 1: İngilizce -> Türkçe, 2: Yazma Görevi
      _textEditingController.clear();
    });
  }

  void checkAnswer(String selectedAnswer) {
    bool isCorrect = false;

    if (questionType == 0) {
      isCorrect = selectedAnswer.toLowerCase() == words[currentIndex].word.toLowerCase();
    } else if (questionType == 1) {
      isCorrect = selectedAnswer.toLowerCase() == words[currentIndex].meaning.toLowerCase();
    } else if (questionType == 2) {
      isCorrect = selectedAnswer.trim().toLowerCase() == words[currentIndex].word.toLowerCase();
    }

    answers.add(isCorrect);

    if (isCorrect) {
      score++;
    }

    if (currentIndex < words.length - 1) {
      currentIndex++;
      _nextQuestion();
    } else {
      // Quiz bitti, sonucu kaydet ve sonuç ekranına yönlendir
      _saveQuizScore();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            correctAnswers: score,
            incorrectAnswers: words.length - score,
            words: words,
            answers: answers,
          ),
        ),
      );
    }
  }

  void _saveQuizScore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      CollectionReference scoresCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quizScores');
      await scoresCollection.add({
        'timestamp': quizStartTime.toIso8601String(), // Quiz başladığında kaydedilen tarih ve saat
        'score': score,
      });
    } catch (e) {
      print('Error saving quiz score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue.shade700),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue.shade700),
        body: Center(child: Text('Kelime listesi boş!')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Quiz', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue.shade700),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue.shade200, Colors.blue.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuestion(),
              SizedBox(height: 20),
              _buildAnswerOptions(),
              if (questionType == 2)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      checkAnswer(_textEditingController.text);
                    },
                    child: Text('Cevabı Yolla'),
                  ),
                ),
              SizedBox(height: 20),
              Text(
                'Skor: $score',
                style: TextStyle(fontSize: 16, color: Colors.blue.shade900),
              ),
              if (_isBannerAdReady)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    if (questionType == 0) {
      return Column(
        children: [
          Text(
            'Türkçe: ${words[currentIndex].meaning}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
          ),
          Text(
            'İngilizcesi nedir?',
            style: TextStyle(fontSize: 18, color: Colors.blue.shade800),
          ),
        ],
      );
    } else if (questionType == 1) {
      return Column(
        children: [
          Text(
            'İngilizce: ${words[currentIndex].word}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
          ),
          Text(
            'Türkçesi nedir?',
            style: TextStyle(fontSize: 18, color: Colors.blue.shade800),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            'Türkçe: ${words[currentIndex].meaning}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
          ),
          Text(
            'İngilizcesini yazınız:',
            style: TextStyle(fontSize: 18, color: Colors.blue.shade800),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textEditingController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'İngilizce',
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildAnswerOptions() {
    if (questionType == 2) {
      return Container(); // Yazma görevi için seçenekler yok
    }

    List<String> options = _generateOptions();

    return Column(
      children: options.map((option) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: ElevatedButton(
            onPressed: () => checkAnswer(option),
            style: ButtonStyle(
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _generateOptions() {
    List<String> options = [];
    String correctAnswer;

    if (questionType == 0) {
      correctAnswer = words[currentIndex].word;
    } else {
      correctAnswer = words[currentIndex].meaning;
    }

    options.add(correctAnswer);

    while (options.length < 4) {
      String option;
      if (questionType == 0) {
        option = words[random.nextInt(words.length)].word;
      } else {
        option = words[random.nextInt(words.length)].meaning;
      }

      if (!options.contains(option)) {
        options.add(option);
      }
    }

    options.shuffle();
    return options;
  }
}