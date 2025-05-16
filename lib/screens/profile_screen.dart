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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFAF8F0), Colors.grey.shade200],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                ),
                SizedBox(height: 20),
                Text(
                  "Profiliniz yükleniyor...",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Colors.grey.shade800,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Icon(
                isEditing ? Icons.save : Icons.edit, 
                key: ValueKey<bool>(isEditing),
                color: Colors.white,
              ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAF8F0), Colors.grey.shade200],
          ),
        ),
        child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil resmi kısmı
                  GestureDetector(
                    onTap: isEditing ? () => _showImageSourceOptions() : null,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.amber.shade700,
                            backgroundImage: _image != null 
                                ? FileImage(_image!) 
                                : (_profileImageUrl != null 
                                    ? NetworkImage(_profileImageUrl!) 
                                    : null),
                            child: _image == null && _profileImageUrl == null
                                ? Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : '', 
                                    style: TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold)
                                  )
                                : null,
                          ),
                        ),
                        if (isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Kullanıcı bilgileri kısmı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isEditing 
                            ? TextField(
                                controller: _usernameController,
                                style: TextStyle(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Kullanıcı Adı',
                                  labelStyle: TextStyle(color: Colors.amber.shade700),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.person, color: Colors.amber.shade700, size: 20),
                                ),
                              )
                            : Text(
                                username,
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.alternate_email, size: 14, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              // Kullanıcı adından tüm @ işaretlerini kaldırıp başına sadece bir tane ekle
                              '@${username.replaceAll('@', '')}',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // İstatistikler satırı
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200, width: 1),
                              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatColumn('Listeler', '$wordListCount'),
                              _buildStatDivider(),
                              _buildStatColumn('Kelimeler', '$wordCount'),
                              _buildStatDivider(),
                              _buildStatColumn('Öğrenilen', '${learnedWords.length}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              Divider(color: Colors.grey.shade200, thickness: 1),
              SizedBox(height: 10),
              
              // Alt kısım - Profil ayarları
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.visibility, color: Colors.amber.shade700, size: 22),
                ),
                title: Text(
                  'Profil Görünürlüğü',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  isPublic ? 'Profiliniz herkese açık' : 'Profiliniz gizli',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                trailing: Switch(
                  value: isPublic,
                  activeColor: Colors.amber.shade700,
                  activeTrackColor: Colors.amber.shade200,
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade300,
                  onChanged: isEditing 
                      ? (value) {
                          setState(() {
                            isPublic = value;
                          });
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // İstatistik kolonu için yardımcı metot
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // İstatistikler arası ayırıcı
  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildQuizScoresCard() {
    return Card(
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve rozet bölümü
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz Sonuçları', 
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Performansınızı takip edin',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (quizScores.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${quizScores.length}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
              
              // İçerik bölümü
              quizScores.isEmpty
                  ? _buildEmptyQuizState()
                  : Column(
                      children: [
                        // Özet kısmı
                        _buildQuizSummary(),
                        SizedBox(height: 15),
                        
                        // Detaylı skorlar
                        ...quizScores.map((score) {
                          return Dismissible(
                            key: Key(score['id']),
                            direction: isEditing ? DismissDirection.endToStart : DismissDirection.none,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.delete, color: Colors.red.shade700),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Skoru Sil'),
                                    content: Text('Bu quiz skorunu silmek istediğinize emin misiniz?'),
                                    actions: [
                                      TextButton(
                                        child: Text('İptal'),
                                        onPressed: () => Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: Text('Sil', style: TextStyle(color: Colors.red)),
                                        onPressed: () => Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              _deleteQuizScore(score['id'], quizScores.indexOf(score));
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: _buildScoreCircle(score['score']),
                                title: Wrap(  // Row yerine Wrap widget'ı kullanarak taşma sorununu çözüyoruz
                                  spacing: 8,
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Quiz Skoru',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getScoreColor(score['score']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getScoreLabel(score['score']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getScoreColor(score['score']),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isEditing
                                    ? IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                        tooltip: 'Skoru sil',
                                        onPressed: () => _deleteQuizScoreWithConfirmation(score['id'], quizScores.indexOf(score)),
                                      )
                                    : Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                onTap: () {
                                  // Quiz detayına gitmek için tıklama
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Yeni yardımcı metotlar
  Widget _buildEmptyQuizState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz_outlined,
              size: 36,
              color: Colors.amber.shade300,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Henüz quiz sonucu bulunmamaktadır',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Quiz çözerek bilgilerinizi test edin ve ilerlemenizi takip edin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 20),
          OutlinedButton.icon(
            icon: Icon(Icons.play_arrow_rounded),
            label: Text('Quiz Başlat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber.shade700,
              side: BorderSide(color: Colors.amber.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              // Quiz başlatma sayfasına yönlendir
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSummary() {
    // Ortalama skoru hesapla
    double avgScore = 0;
    if (quizScores.isNotEmpty) {
      avgScore = quizScores.fold(0.0, (prev, score) => prev + (score['score'] as num)) / quizScores.length;
    }
    
    // En yüksek skoru bul
    int highestScore = 0;
    if (quizScores.isNotEmpty) {
      highestScore = quizScores.map((s) => (s['score'] as num).toInt()).reduce((curr, next) => curr > next ? curr : next);
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.amber.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade100.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      // Row yerine Wrap kullanarak taşma sorununu çözelim
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // boşlukları azaltıp eşit dağıt
          children: [
            _buildSummaryItem('Quiz', '${quizScores.length}', Icons.format_list_numbered), // Daha kısa etiket
            
            // Daha ince ayraç ve daha az boşluk
            Container(width: 1, height: 40, color: Colors.amber.shade200.withOpacity(0.5)),
            
            _buildSummaryItem('Ortalama', avgScore.toStringAsFixed(1), Icons.bar_chart), // Daha kısa etiket
            
            // Daha ince ayraç ve daha az boşluk
            Container(width: 1, height: 40, color: Colors.amber.shade200.withOpacity(0.5)),
            
            _buildSummaryItem('En İyi', '$highestScore', Icons.trending_up), // Daha kısa etiket
          ],
        ),
      ),
    );
  }

  // Özet öğelerini biraz daha kompakt hale getirelim
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Kompakt boyut
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // Merkeze hizalama
            children: [
              Icon(icon, size: 14, color: Colors.amber.shade700), // Daha küçük ikon
              SizedBox(width: 3), // Daha az boşluk
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, // Daha küçük yazı
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Daha küçük değer yazısı
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(dynamic score) {
    // Score renk ve boyutunu belirle
    Color circleColor = _getScoreColor(score);
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            circleColor.withOpacity(0.7),
            circleColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: circleColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    int scoreValue = score is int ? score : int.tryParse(score.toString()) ?? 0;
    
    if (scoreValue >= 80) return Colors.green.shade600;
    if (scoreValue >= 60) return Colors.amber.shade700;
    if (scoreValue >= 40) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  String _getScoreLabel(dynamic score) {
    int scoreValue = score is int ? score : int.tryParse(score.toString()) ?? 0;
    
    if (scoreValue >= 80) return 'Mükemmel';
    if (scoreValue >= 60) return 'İyi';
    if (scoreValue >= 40) return 'Orta';
    return 'Geliştirilebilir';
  }

  Future<void> _deleteQuizScoreWithConfirmation(String docId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Skoru Sil'),
          content: Text('Bu quiz skorunu silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    
    if (confirm == true) {
      _deleteQuizScore(docId, index);
    }
  }

  Widget _buildLearnedWordsCard() {
    return Card(
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: Colors.amber.shade700, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Öğrenilen Kelimeler', 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              if (isEditing)
                Container(
                  margin: EdgeInsets.only(bottom: 15),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newWordController,
                          decoration: InputDecoration(
                            hintText: 'Yeni Kelime',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final word = _newWordController.text.trim();
                          if (word.isNotEmpty) {
                            _addLearnedWord(word);
                          }
                        },
                        child: Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              learnedWords.isEmpty
                  ? Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Henüz öğrenilen kelime bulunmamaktadır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: learnedWords.length,
                      itemBuilder: (context, index) {
                        final word = learnedWords[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                word['word'][0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                            title: Text(
                              word['word'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            trailing: isEditing
                                ? IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red.shade400),
                                    onPressed: () => _deleteLearnedWord(word['id'], index),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Resim seçme seçenekleri için modal
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profil Fotoğrafını Değiştir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.delete,
                  label: 'Kaldır',
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfileImage();
                  },
                  iconColor: Colors.red.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({required IconData icon, required String label, required VoidCallback onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Colors.amber.shade700, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Profil fotoğrafını kaldırmak için metot (eksikse ekleyelim)
  Future<void> _removeProfileImage() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profileImageUrl': null,
      });

      setState(() {
        _profileImageUrl = null;
        _image = null;
      });

      _showSnackBar('Profil fotoğrafı kaldırıldı');
    } catch (e) {
      print('Error removing profile image: $e');
      _showSnackBar('Profil fotoğrafı kaldırılırken bir hata oluştu');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.amber.shade700,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }
}