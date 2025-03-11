import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'word_list_detail_screen.dart';
import 'package:vocabvault2/models/word_list.dart';

class WordListGroupsScreen extends StatefulWidget {
  const WordListGroupsScreen({super.key});

  @override
  _WordListGroupsScreenState createState() => _WordListGroupsScreenState();
}

class _WordListGroupsScreenState extends State<WordListGroupsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  List<WordList> wordLists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadWordLists();
  }

  Future<void> _loadWordLists() async {
    if (_user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid) // Kullanıcı UID'si ile belgeye erişim
          .collection('wordLists')
          .get();
      if (mounted) {
        setState(() {
          wordLists = querySnapshot.docs
              .map((doc) => WordList.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          isLoading = false;
        });
      }
    } else {
      print('Error: user is not logged in');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addWordList(String listName) async {
    if (_user != null) {
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(_user!.uid) // Kullanıcı UID'si ile belgeye erişim
          .collection('wordLists')
          .add({
        'name': listName,
        'words': [],
      });
      if (mounted) {
        setState(() {
          wordLists.add(WordList(id: docRef.id, name: listName, words: []));
        });
      }
    } else {
      print('Error: user is not logged in');
    }
  }

  Future<void> _deleteWordList(String docId) async {
    if (_user != null) {
      await _firestore
          .collection('users')
          .doc(_user!.uid) // Kullanıcı UID'si ile belgeye erişim
          .collection('wordLists')
          .doc(docId)
          .delete();
      _loadWordLists();
    } else {
      print('Error: user is not logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kelime Listeleri')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: wordLists.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: ListTile(
                    leading: Icon(Icons.list, color: Colors.blue.shade700),
                    title: Text(
                      wordLists[index].name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmationDialog(context, wordLists[index].id),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WordListDetailScreen(
                            wordList: wordLists[index],
                            username: _user!.uid, // Kullanıcı UID'sini geçiyoruz
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? newListName = await _showAddListDialog(context);
          if (newListName != null && newListName.isNotEmpty) {
            await _addWordList(newListName);
            _loadWordLists(); // Yeni listeyi ekledikten sonra listeleri yeniden yükleyin
          }
        },
        tooltip: 'Yeni Liste Ekle',
        backgroundColor: Colors.blue.shade700,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<String?> _showAddListDialog(BuildContext context) async {
    String? listName;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Yeni Liste Ekle'),
          content: TextField(
            onChanged: (value) {
              listName = value;
            },
            decoration: InputDecoration(
              hintText: "Liste İsmi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Ekle'),
              onPressed: () {
                Navigator.of(context).pop(listName);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String docId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Listeyi Sil'),
          content: Text('Bu listeyi silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteWordList(docId);
              },
            ),
          ],
        );
      },
    );
  }
}