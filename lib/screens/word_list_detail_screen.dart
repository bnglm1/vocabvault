import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';
import '../models/word_list.dart';
import '../models/word.dart';

class WordListDetailScreen extends StatefulWidget {
  final WordList wordList;
  final String username; // Kullanıcı adı

  const WordListDetailScreen({super.key, required this.wordList, required this.username});

  @override
  _WordListDetailScreenState createState() => _WordListDetailScreenState();
}

class _WordListDetailScreenState extends State<WordListDetailScreen> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _exampleSentenceController = TextEditingController();
  final translator = GoogleTranslator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.wordList.name)),
      body: ListView.builder(
        itemCount: widget.wordList.words.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ListTile(
              leading: Icon(Icons.book, color: Colors.blue.shade700),
              title: Text(widget.wordList.words[index].word, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(widget.wordList.words[index].meaning),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue.shade700),
                    onPressed: () => _showEditWordDialog(context, index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red.shade700),
                    onPressed: () => _deleteWord(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _showAddWordDialog(context);
          // Liste güncellendiğinde UI'ı yenile
          setState(() {});
        },
        tooltip: 'Kelime Ekle',
        backgroundColor: Colors.blue.shade700,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleSentenceController.dispose();
    super.dispose();
  }

  Future<void> _showAddWordDialog(BuildContext context) async {
    _wordController.clear();
    _meaningController.clear();
    _exampleSentenceController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kelime Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _wordController,
                decoration: InputDecoration(labelText: 'Kelime'),
                onChanged: (value) {
                  _fetchTranslation(value);
                },
              ),
              TextField(controller: _meaningController, decoration: InputDecoration(labelText: 'Anlamı')),
              TextField(controller: _exampleSentenceController, decoration: InputDecoration(labelText: 'Türkçe Çeviri')),
            ],
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ekle'),
              onPressed: () {
                setState(() {
                  widget.wordList.words.add(Word(
                    id: UniqueKey().toString(),
                    word: _wordController.text,
                    meaning: _meaningController.text,
                    exampleSentence: _exampleSentenceController.text,
                  ));
                });
                _saveWordList();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditWordDialog(BuildContext context, int index) async {
    _wordController.text = widget.wordList.words[index].word;
    _meaningController.text = widget.wordList.words[index].meaning;
    _exampleSentenceController.text = widget.wordList.words[index].exampleSentence;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kelimeyi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _wordController,
                decoration: InputDecoration(labelText: 'Kelime'),
                onChanged: (value) {
                  _fetchTranslation(value);
                },
              ),
              TextField(controller: _meaningController, decoration: InputDecoration(labelText: 'Anlamı')),
              TextField(controller: _exampleSentenceController, decoration: InputDecoration(labelText: 'Türkçe Çeviri')),
            ],
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Kaydet'),
              onPressed: () {
                setState(() {
                  widget.wordList.words[index] = Word(
                    id: widget.wordList.words[index].id,
                    word: _wordController.text,
                    meaning: _meaningController.text,
                    exampleSentence: _exampleSentenceController.text,
                  );
                });
                _saveWordList();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteWord(int index) {
    setState(() {
      widget.wordList.words.removeAt(index);
    });
    _saveWordList();
  }

  void _saveWordList() async {
    if (widget.username.isNotEmpty && widget.wordList.id.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.username) // Kullanıcı adı ile belgeye erişim
          .collection('wordLists')
          .doc(widget.wordList.id)
          .set(widget.wordList.toMap());
    } else {
      print('Error: username or wordList.id is empty');
    }
  }

  Future<void> _fetchTranslation(String word) async {
    final translation = await translator.translate(word, from: 'en', to: 'tr');
    setState(() {
      _meaningController.text = translation.text;
    });
  }
}