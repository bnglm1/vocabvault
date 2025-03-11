import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScannedWordsScreen extends StatefulWidget {
  final List<String> words;

  const ScannedWordsScreen({super.key, required this.words});

  @override
  _ScannedWordsScreenState createState() => _ScannedWordsScreenState();
}

class _ScannedWordsScreenState extends State<ScannedWordsScreen> {
  final translator = GoogleTranslator();
  final Map<String, String> translations = {};
  final TextEditingController _listNameController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _translateWords();
  }

  Future<void> _translateWords() async {
    for (String word in widget.words) {
      final translation = await translator.translate(word, from: 'en', to: 'tr');
      if (mounted) {
        setState(() {
          translations[word] = translation.text;
        });
      }
    }
  }

  Future<void> _saveWordList() async {
    final listName = _listNameController.text;
    if (listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir liste ismi girin')),
      );
      return;
    }

    final wordList = widget.words.map((word) => {
      'word': word,
      'meaning': translations[word] ?? 'Çeviri bulunamadı',
    }).toList();

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('wordLists')
          .add({
        'name': listName,
        'words': wordList,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelime listesi kaydedildi')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı oturumu açık değil')),
      );
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kelime Listesi İsmi'),
          content: TextField(
            controller: _listNameController,
            decoration: InputDecoration(hintText: 'Liste ismini girin'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveWordList();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanned Words'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _showSaveDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.words.length,
        itemBuilder: (context, index) {
          final word = widget.words[index];
          final translation = translations[word] ?? 'Çeviri yapılıyor...';
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(word, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(translation),
            ),
          );
        },
      ),
    );
  }
}