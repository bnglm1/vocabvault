import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/word.dart';
import '../models/word_list.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  _LearnScreenState createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  List<Word> words = [];
  List<Word> initialWords = [];
  bool isLoading = true;
  int currentIndex = 0;
  bool showTranslation = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;
  Map<String, int> wordAttempts = {};
  int learnedWords = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _showWordListDialog();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showWordListDialog() async {
    if (_user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
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
    if (_user != null) {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('wordLists')
          .doc(listId)
          .get();

      List<Word> wordList = (docSnapshot['words'] as List)
          .map((wordData) => Word.fromMap(wordData as Map<String, dynamic>, docSnapshot.id))
          .toList();

      setState(() {
        words = wordList;
        initialWords = List.from(wordList);
        isLoading = false;
      });
    } else {
      print('Error: user is not logged in');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onCardSwiped(DismissDirection direction) {
    setState(() {
      if (direction == DismissDirection.endToStart) {
        // Sola kaydırma
        String wordId = words[currentIndex].id;
        if (wordAttempts.containsKey(wordId)) {
          wordAttempts[wordId] = wordAttempts[wordId]! + 1;
        } else {
          wordAttempts[wordId] = 1;
        }

        if (wordAttempts[wordId]! < 2) {
          words.add(words.removeAt(currentIndex));
        } else {
          words.removeAt(currentIndex);
        }
      } else if (direction == DismissDirection.startToEnd) {
        // Sağa kaydırma
        learnedWords++;
        _markAsLearned(words[currentIndex].word);
        words.removeAt(currentIndex);
      }

      if (words.isEmpty) {
        _showCompletionDialog();
      }

      showTranslation = false;
      _isFlipped = false;
      _controller.reset();
    });
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
      showTranslation = !showTranslation;
    });
  }

  void _showCompletionDialog() {
    double percentage = (learnedWords / initialWords.length) * 100;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Öğrenme Tamamlandı!'),
          content: Text('Kelimelerin %${percentage.toStringAsFixed(1)} kadarını öğrendiniz.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsLearned(String word) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('learnedWords')
          .add({
            'word': word,
            'timestamp': Timestamp.now(), // Tarih ve saat bilgisini ekliyoruz
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$word öğrenilen kelimeler listesine eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error marking word as learned: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelime öğrenilen kelimeler listesine eklenirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Öğren')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : words.isEmpty
              ? Center(child: Text('Tüm kelimeleri öğrendiniz!'))
              : Dismissible(
                  key: Key(words[currentIndex].word),
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    _onCardSwiped(direction);
                  },
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final angle = _animation.value * 3.1415926535897932;
                          final transform = Matrix4.rotationY(angle);
                          return Transform(
                            transform: transform,
                            alignment: Alignment.center,
                            child: _animation.value < 0.5
                                ? Flashcard(word: words[currentIndex], showTranslation: false)
                                : Transform(
                                    transform: Matrix4.rotationY(3.1415926535897932),
                                    alignment: Alignment.center,
                                    child: Flashcard(word: words[currentIndex], showTranslation: true),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }
}

class Flashcard extends StatelessWidget {
  final Word word;
  final bool showTranslation;

  const Flashcard({
    super.key,
    required this.word,
    this.showTranslation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Container(
        width: 300,
        height: 400, // Kartın yüksekliğini artırdık
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            showTranslation ? word.meaning : word.word,
            textAlign: TextAlign.center, // Metni ortaladık
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}