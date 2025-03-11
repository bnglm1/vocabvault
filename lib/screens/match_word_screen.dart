import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/word.dart';
import '../models/word_list.dart';

class MatchWordScreen extends StatefulWidget {
  const MatchWordScreen({super.key});

  @override
  _MatchWordScreenState createState() => _MatchWordScreenState();
}

class _MatchWordScreenState extends State<MatchWordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  List<Word> words = [];
  bool isLoading = true;
  Word? selectedWord;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _showWordListDialog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
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

      wordList.shuffle();
      List<Word> selectedWords = wordList.take(8).toList();
      List<Word> allCards = [...selectedWords, ...selectedWords.map((word) => Word(word: word.meaning, meaning: word.word, id: word.id, exampleSentence: word.exampleSentence))];
      allCards.shuffle();

      setState(() {
        words = allCards;
        isLoading = false;
        _startTimer();
      });
    } else {
      print('Error: user is not logged in');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onCardSelected(Word word) {
    setState(() {
      if (selectedWord == null) {
        selectedWord = word;
      } else {
        if ((selectedWord!.word == word.meaning && selectedWord!.meaning == word.word) ||
            (selectedWord!.meaning == word.word && selectedWord!.word == word.meaning)) {
          words.remove(selectedWord);
          words.remove(word);
        }
        selectedWord = null;
      }

      if (words.isEmpty) {
        _timer?.cancel();
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tebrikler!'),
          content: Text('Eşleşmeyi $_seconds saniyede tamamladınız.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kelime Eşleştirme')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Süre: $_seconds saniye', style: TextStyle(fontSize: 24)),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Daha fazla kart göstermek için sütun sayısını artırdık
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: words.length,
                      itemBuilder: (context, index) {
                        return Flashcard(
                          word: words[index],
                          isSelected: selectedWord == words[index],
                          onTap: () => _onCardSelected(words[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class Flashcard extends StatelessWidget {
  final Word word;
  final bool isSelected;
  final VoidCallback onTap;

  const Flashcard({
    super.key,
    required this.word,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.all(5), // Kartların arasındaki boşluğu azalttık
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
        color: isSelected ? Colors.green.shade200 : Colors.blue.shade100,
        child: Container(
          width: 100, // Kartların genişliğini azalttık
          height: 80, // Kartların yüksekliğini azalttık
          padding: EdgeInsets.all(10),
          child: Center(
            child: Text(
              word.word,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}