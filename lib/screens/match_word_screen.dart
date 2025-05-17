import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
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
  int _matches = 0;
  int _attempts = 0;
  bool _hasShownTutorial = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // İlk olarak tutorial'ı göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  // Tutorial diyaloğu
  void _showTutorialDialog() {
    if (_hasShownTutorial) return;
    _hasShownTutorial = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  child: Icon(Icons.extension, color: Colors.amber.shade700, size: 24),
                ),
                SizedBox(height: 12),
                Text(
                  'Kelime Eşleştirme Oyunu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 20),
                
                // Adımlar
                _buildTutorialStep(
                  icon: Icons.touch_app,
                  title: 'Kartları açın',
                  description: 'Kelimeleri ve anlamlarını görmek için kartlara dokunun.',
                ),
                SizedBox(height: 16),
                
                _buildTutorialStep(
                  icon: Icons.compare_arrows,
                  title: 'Eşleşmeleri bulun',
                  description: 'İngilizce kelime ile Türkçe anlamını eşleştirin. Doğru eşleşmeler oyun alanından kaldırılır.',
                ),
                SizedBox(height: 16),
                
                _buildTutorialStep(
                  icon: Icons.timer,
                  title: 'Süreyi takip edin',
                  description: 'Tüm eşleşmeleri en kısa sürede bulmaya çalışın. Süreniz kaydedilecek!',
                ),
                
                SizedBox(height: 24),
                
                // Örnek kartlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildExampleCard('Book', false),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward, color: Colors.amber.shade700),
                    SizedBox(width: 12),
                    _buildExampleCard('Kitap', true),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Kapat butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showWordListDialog();
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

  Widget _buildExampleCard(String text, bool isSelected) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [Colors.amber.shade100, Colors.amber.shade200]
              : [Colors.white, Colors.grey.shade100],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.amber.shade800 : Colors.grey.shade700,
          ),
        ),
      ),
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
          barrierDismissible: false,
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
                              subtitle: Text(
                                '${wordLists[index].words.length} kelime',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
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
    setState(() {
      isLoading = true;
      _matches = 0;
      _attempts = 0;
    });
    
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
    
      // Kelime listesinin boyutuna göre seçilecek kelime sayısını belirle
      int totalWords = wordList.length;
      int wordsToTake;
    
      if (totalWords <= 2) {
        wordsToTake = 2; // En az 2 kelime (4 kart)
      } else if (totalWords <= 4) {
        wordsToTake = 4; // 4 kelime (8 kart)
      } else if (totalWords <= 6) {
        wordsToTake = 6; // 6 kelime (12 kart)
      } else {
        wordsToTake = 8; // En fazla 8 kelime (16 kart)
      }
    
      // Kelimeleri seç ve kartları oluştur
      List<Word> selectedWords = wordList.take(wordsToTake).toList();
      List<Word> allCards = [
        ...selectedWords, 
        ...selectedWords.map((word) => Word(
              word: word.meaning, 
              meaning: word.word, 
              id: word.id, 
              exampleSentence: word.exampleSentence)
        )
      ];
      allCards.shuffle();

      setState(() {
        words = allCards;
        isLoading = false;
        _seconds = 0;
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
        // İlk kart seçildi
        selectedWord = word;
      } else {
        _attempts++;
        
        // İkinci kart seçildi, eşleşme kontrol ediliyor
        if ((selectedWord!.word == word.meaning && selectedWord!.meaning == word.word) ||
            (selectedWord!.meaning == word.word && selectedWord!.word == word.meaning)) {
          // Eşleşme başarılı
          words.remove(selectedWord);
          words.remove(word);
          _matches++;
          
          // Kısa bir konfeti efekti
          _confettiController.play();
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _confettiController.stop();
          });
        } else {
          // Eşleşme başarısız
        }
        selectedWord = null;

        if (words.isEmpty) {
          _timer?.cancel();
          Future.delayed(Duration(milliseconds: 500), () {
            _showCompletionDialog();
          });
        }
      }
    });
  }

  void _showCompletionDialog() {
    _confettiController.play();
    
    double accuracy = _attempts > 0 ? _matches / _attempts * 100 : 0;
    String grade;
    
    if (_seconds < 30) {
      grade = "Muhteşem!";
    } else if (_seconds < 60) {
      grade = "Harika!";
    } else if (_seconds < 90) {
      grade = "Çok İyi!";
    } else {
      grade = "İyi!";
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -3.14 / 2, // Yukarı doğru
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.1,
                colors: [
                  Colors.amber.shade200,
                  Colors.amber.shade300, 
                  Colors.amber.shade400,
                  Colors.amber.shade700,
                  Colors.orange.shade300,
                ],
              ),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 28),
              ),
              SizedBox(height: 12),
              Text(
                'TEBRİKLER!',
                style: TextStyle(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 8),
              Text(
                grade,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem(Icons.timer, 'Süre', '$_seconds saniye'),
              SizedBox(height: 12),
              _buildStatItem(Icons.track_changes, 'İsabet', '${accuracy.toStringAsFixed(1)}%'),
              SizedBox(height: 12),
              _buildStatItem(Icons.swipe, 'Hamle', '$_attempts hamle'),
              SizedBox(height: 20),
              Text(
                'Tüm eşleşmeleri başarıyla tamamladınız!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          actions: [
            // Sadece 'Tamam' butonu ekleyelim
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                  Navigator.of(context).pop(); // Oyun ekranını kapat (Ana sayfaya dön)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Tamam',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.amber.shade700, size: 16),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int gridCrossAxisCount = 3;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      gridCrossAxisCount = 6;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelime Eşleştirme',
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
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Timer ve istatistik kartı
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.amber.shade50],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Ortalama için değiştirildi
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.timer, color: Colors.amber.shade700, size: 20),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Süre',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '$_seconds saniye',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Kart ızgarası
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [Colors.amber.shade100, Colors.amber.shade200]
                : [Colors.white, Colors.grey.shade100],
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  word.word,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.amber.shade900 : Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}