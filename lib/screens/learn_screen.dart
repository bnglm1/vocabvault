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
  bool _hasShownTutorial = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // İlk olarak tutorial'ı göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Bilgilendirme kartı ekliyoruz
  void _showTutorialDialog() {
    if (_hasShownTutorial) return;
    _hasShownTutorial = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Dışına tıklayarak kapatmayı engelliyoruz
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.yellow.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.school, color: Colors.amber.shade700, size: 24),
                ),
                SizedBox(height: 12),
                Text(
                  'Kelimeleri Nasıl Öğrenirsiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 20),

                // Adım 1
                _buildTutorialStep(
                  icon: Icons.touch_app,
                  title: 'Kartı çevirin',
                  description: 'Kelimenin anlamını görmek için karta dokunun.',
                ),
                SizedBox(height: 16),

                // Adım 2
                _buildTutorialStep(
                  icon: Icons.swipe_right_alt,
                  title: 'Sağa kaydırın',
                  description: 'Kelimeyi öğrendiyseniz sağa kaydırın. Kelime öğrenilen kelimeler listenize eklenecek.',
                ),
                SizedBox(height: 16),

                // Adım 3
                _buildTutorialStep(
                  icon: Icons.swipe_left_alt,
                  title: 'Sola kaydırın',
                  description: 'Kelimeyi tekrar etmek istiyorsanız sola kaydırın. Bu kelimeyi daha sonra tekrar çalışacaksınız.',
                ),

                SizedBox(height: 24),

                // Kapat butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showWordListDialog(); // Tutorial kapandıktan sonra kelime listesini göster
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: Text(
                      'Anladım',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Adım için yardımcı widget
  Widget _buildTutorialStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Icon(icon, color: Colors.amber.shade700, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // Dışına tıklayarak kapatmayı engelliyoruz
          builder: (context) {
            return AlertDialog(
              title: Text(
                'Kelime Listesi Seçin',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: 300),
                child: wordLists.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sentiment_dissatisfied, 
                                 size: 48, color: Colors.amber.shade300),
                              SizedBox(height: 16),
                              Text(
                                'Henüz kelime listeniz bulunmuyor.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: wordLists.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.symmetric(vertical: 4),
                            color: Colors.amber.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.amber.shade200, width: 1),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                              title: Text(
                                wordLists[index].name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _loadWords(wordLists[index].id);
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                if (wordLists.isEmpty)
                  TextButton(
                    child: Text(
                      'Geri Dön',
                      style: TextStyle(color: Colors.amber.shade700),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        );
      }
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

  // Tamamlama diyaloğunu güncelliyoruz
  void _showCompletionDialog() {
    double percentage = initialWords.isNotEmpty ? (learnedWords / initialWords.length) * 100 : 0;

    showDialog(
      context: context,
      barrierDismissible: false, // Dışına tıklayarak kapatmayı engelliyoruz
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration, color: Colors.amber.shade700, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                'Öğrenme Tamamlandı!',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
              ),
              SizedBox(height: 20),
              Text(
                'Kelimelerin %${percentage.toStringAsFixed(1)} kadarını öğrendiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$learnedWords kelimeyi başarıyla öğrendiniz.',
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text('Ana Sayfaya Dön'),
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
      appBar: AppBar(
        title: Text(
          'Öğren',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey.shade800,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAF8F0), Colors.grey.shade200],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Kelimeler yükleniyor...",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              )
            : words.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle, 
                            color: Colors.amber.shade700, 
                            size: 60,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Tüm kelimeleri öğrendiniz!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Yeni kelimeler ekleyerek öğrenmeye devam edebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 32),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Yeni Liste Oluştur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Dismissible(
                        key: Key(words[currentIndex].word),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          _onCardSwiped(direction);
                        },
                        background: Container(
                          color: Colors.green.withOpacity(0.3),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 20),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 36,
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.orange.withOpacity(0.3),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(
                            Icons.replay,
                            color: Colors.orange,
                            size: 36,
                          ),
                        ),
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
                      
                      // İlerleme bilgisi
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.amber.shade700,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Öğrenilen: $learnedWords',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    height: 16,
                                    width: 1,
                                    margin: EdgeInsets.symmetric(horizontal: 8),
                                    color: Colors.grey.shade300,
                                  ),
                                  Text(
                                    'Kalan: ${words.length}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

// Flashcard sınıfını güncelliyoruz
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
      shadowColor: Colors.black26,
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: showTranslation 
                ? [Colors.amber.shade50, Colors.amber.shade100] 
                : [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: (showTranslation ? Colors.amber.shade300 : Colors.amber.shade200).withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Icon(
                showTranslation ? Icons.translate : Icons.menu_book,
                color: showTranslation ? Colors.amber.shade300 : Colors.amber.shade200,
                size: 20,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    showTranslation ? word.meaning : word.word,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  Icon(
                    Icons.touch_app,
                    color: showTranslation ? Colors.amber.shade500 : Colors.amber.shade300,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    showTranslation ? 'Kelimeyi görmek için dokunun' : 'Anlamı görmek için dokunun',
                    style: TextStyle(
                      fontSize: 14,
                      color: showTranslation ? Colors.grey.shade600 : Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSwipeHint(
                    icon: Icons.swipe_right_alt,
                    label: "Öğrendim",
                    color: Colors.green.shade300,
                  ),
                  SizedBox(width: 30),
                  _buildSwipeHint(
                    icon: Icons.swipe_left_alt,
                    label: "Tekrar Et",
                    color: Colors.orange.shade300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Kaydırma ipucu gösterimi
  Widget _buildSwipeHint({
    required IconData icon, 
    required String label, 
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}