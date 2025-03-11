import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/word_list.dart' as word_list_model;
import '../models/word.dart' as word_model;

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late Future<List<word_list_model.WordList>> _wordListsFuture;

  @override
  void initState() {
    super.initState();
    _wordListsFuture = _fetchWordLists();
  }

  Future<List<word_list_model.WordList>> _fetchWordLists() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // Kullanıcı UID'si ile belgeye erişim
        .collection('wordLists')
        .get();

    return querySnapshot.docs.map((doc) {
      List<word_model.Word> words = (doc['words'] as List)
          .map((wordData) => word_model.Word.fromMap(wordData as Map<String, dynamic>, doc.id))
          .toList();
      return word_list_model.WordList(id: doc.id, name: doc['name'], words: words);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kelime Kartları')),
      body: FutureBuilder<List<word_list_model.WordList>>(
        future: _wordListsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Kelime listesi bulunamadı.'));
          } else {
            List<word_list_model.WordList> wordLists = snapshot.data!;
            return ListView.builder(
              itemCount: wordLists.length,
              itemBuilder: (context, index) {
                word_list_model.WordList wordList = wordLists[index];
                return ExpansionTile(
                  title: Text(wordList.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  children: wordList.words.map((word) {
                    return Flashcard(word: word);
                  }).toList(),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Flashcard extends StatefulWidget {
  final word_model.Word word;

  const Flashcard({super.key, required this.word});

  @override
  _FlashcardState createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.1415926535897932;
          return Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: _animation.value < 0.5
                ? _buildFront()
                : Transform(
                    transform: Matrix4.rotationY(3.1415926535897932),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.blue.shade100,
      child: Container(
        width: 300, // Sabit genişlik
        height: 200, // Sabit yükseklik
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(widget.word.word, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.blue.shade200,
      child: Container(
        width: 300, // Sabit genişlik
        height: 200, // Sabit yükseklik
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(widget.word.meaning, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}