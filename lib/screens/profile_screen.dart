import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/date_symbol_data_local.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  String username = '';
  bool isPublic = true;
  int wordListCount = 0;
  int wordCount = 0;
  List<Map<String, dynamic>> quizScores = [];
  List<Map<String, dynamic>> learnedWords = [];
  bool isLoading = true;
  bool isEditing = false;
  File? _image;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _newWordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    initializeDateFormatting('tr', null).then((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        username = userData['username'] ?? '';
        isPublic = userData['isPublic'] ?? true;
        _profileImageUrl = userData['profileImageUrl'];
        _usernameController.text = username;
      }

      final wordListsFuture = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('wordLists').get();
      final quizScoresFuture = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('quizScores').get();
      final learnedWordsFuture = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('learnedWords').get();

      final results = await Future.wait([wordListsFuture, quizScoresFuture, learnedWordsFuture]);

      wordListCount = results[0].docs.length;
      wordCount = results[0].docs.fold(0, (sum, doc) {
        final words = doc.data()['words'] as List<dynamic>? ?? [];
        return sum + words.length;
      });

      quizScores = results[1].docs.map((doc) {
        final data = doc.data();
        return {
          'score': data['score'],
          'id': doc.id,
        };
      }).toList();

      learnedWords = results[2].docs.map((doc) {
        final data = doc.data();
        return {
          'word': data['word'] as String,
          'id': doc.id,
        };
      }).toList();

      print('Quiz scores: $quizScores');
      print('Learned words: $learnedWords');
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Resim seçilirken bir hata oluştu');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null || user == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${user!.uid}.jpg');
      await storageRef.putFile(_image!);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profileImageUrl': downloadUrl,
      });
      setState(() {
        _profileImageUrl = downloadUrl;
      });
      _showSnackBar('Resim başarıyla güncellendi');
    } catch (e) {
      print('Error uploading image: $e');
      _showSnackBar('Resim yüklenirken bir hata oluştu');
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'username': _usernameController.text,
        'isPublic': isPublic,
      });
      setState(() {
        username = _usernameController.text;
        isEditing = false;
      });
      _showSnackBar('Profil başarıyla güncellendi');
    } catch (e) {
      print('Error saving profile: $e');
      _showSnackBar('Profil kaydedilirken bir hata oluştu');
    }
  }

  Future<void> _addLearnedWord(String word) async {
    if (user == null) return;

    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('learnedWords').add({
        'word': word,
      });

      setState(() {
        learnedWords.insert(0, {
          'word': word,
          'id': docRef.id,
        });
      });

      _newWordController.clear();
      _showSnackBar('Kelime başarıyla eklendi');
    } catch (e) {
      print('Error adding learned word: $e');
      _showSnackBar('Kelime eklenirken bir hata oluştu');
    }
  }

  Future<void> _deleteLearnedWord(String docId, int index) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('learnedWords')
          .doc(docId)
          .delete();

      setState(() {
        learnedWords.removeAt(index);
      });

      _showSnackBar('Kelime başarıyla silindi');
    } catch (e) {
      print('Error deleting learned word: $e');
      _showSnackBar('Kelime silinirken bir hata oluştu');
    }
  }

  Future<void> _deleteQuizScore(String docId, int index) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('quizScores')
          .doc(docId)
          .delete();

      setState(() {
        quizScores.removeAt(index);
      });

      _showSnackBar('Quiz sonucu başarıyla silindi');
    } catch (e) {
      print('Error deleting quiz score: $e');
      _showSnackBar('Quiz sonucu silinirken bir hata oluştu');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Icon(isEditing ? Icons.save : Icons.edit, key: ValueKey<bool>(isEditing)),
            ),
            onPressed: () {
              if (isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              SizedBox(height: 20),
              _buildQuizScoresCard(),
              SizedBox(height: 20),
              _buildLearnedWordsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue,
                    backgroundImage: _image != null ? FileImage(_image!) : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null),
                    child: _image == null && _profileImageUrl == null
                        ? Text(username.isNotEmpty ? username[0].toUpperCase() : '', style: TextStyle(fontSize: 40, color: Colors.white))
                        : null,
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Toplam Kelime Listesi: $wordListCount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Toplam Kelime Sayısı: $wordCount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScoresCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiz Sonuçları:', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 10),
            quizScores.isEmpty
                ? Text('Henüz quiz sonucu bulunmamaktadır.')
                : Column(
                    children: quizScores.map((score) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            'Skor: ${score['score']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: isEditing
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteQuizScore(score['id'], quizScores.indexOf(score)),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> saveQuizResult(int score, Duration duration) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
  
    await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('quizScores')
      .add({
        'score': score,
        'timestamp': FieldValue.serverTimestamp(), // Server timestamp kullanın
        'duration': duration.inSeconds, // Save duration in seconds
      });
    
    // Quiz sonuç sayfasına yönlendirme veya diğer işlemler buraya gelebilir
  }

  Widget _buildLearnedWordsCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Öğrenilen Kelimeler:', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 10),
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newWordController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Yeni Kelime Ekle',
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _addLearnedWord(value.trim());
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        final word = _newWordController.text.trim();
                        if (word.isNotEmpty) {
                          _addLearnedWord(word);
                        }
                      },
                      icon: Icon(Icons.add),
                      label: Text('Ekle'),
                    ),
                  ],
                ),
              ),
            learnedWords.isEmpty
                ? Text('Henüz öğrenilen kelime bulunmamaktadır.')
                : Column(
                    children: learnedWords.map((word) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            word['word'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: isEditing
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteLearnedWord(word['id'], learnedWords.indexOf(word)),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}