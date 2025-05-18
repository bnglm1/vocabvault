import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart'; // Bu satırı ekleyin
import '../models/word_list.dart' as word_list_model;
import '../models/word.dart' as word_model;

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late Future<List<word_list_model.WordList>> _wordListsFuture;
  bool _hasShownTutorial = false; // Tutorial diyalogunun gösterilip gösterilmediğini kontrol eder

  @override
  void initState() {
    super.initState();
    _wordListsFuture = _fetchWordLists();
    
    // İnitState içinde SchedulerBinding kullanarak diyaloğu gösteriyoruz
    // Bu, widget tamamen build edildikten sonra diyaloğun gösterilmesini sağlar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
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

  // Diğer metotlar aynı kalacak...

  // Tanıtım diyaloğunu gösteren yeni metot
  void _showTutorialDialog() {
    // Eğer diyalog zaten gösterilmişse tekrar gösterme
    if (_hasShownTutorial) return;
    _hasShownTutorial = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: SingleChildScrollView( // Dialog içeriğini kaydırılabilir yapalım
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
                  // Başlık - Row yerine Column kullandım taşmayı önlemek için
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.help_outline, color: Colors.amber.shade700, size: 24),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Kelime Kartları Nasıl Kullanılır?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Adımlar burada...
                  _buildTutorialStep(
                    icon: Icons.expand_more,
                    title: 'Kelime Listesini Açın',
                    description: 'İstediğiniz kelime listesinin başlığına tıklayarak listede bulunan kelimeleri görebilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildTutorialStep(
                    icon: Icons.touch_app,
                    title: 'Karta Dokunun',
                    description: 'Kelime kartının ön yüzünde kelime, arka yüzünde anlamı gösterilir. Kartı çevirmek için üzerine dokunun.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildTutorialStep(
                    icon: Icons.autorenew,
                    title: 'Tekrar Çevirin',
                    description: 'Kartı tekrar çevirmek için arka yüze dokunun. İstediğiniz kadar çevirebilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildTutorialStep(
                    icon: Icons.volume_up,
                    title: 'Sesli Telaffuz',
                    description: 'Kelimenin telaffuzunu duymak için kelime kartının sağ üst köşesindeki ses simgesine dokunun.',
                  ),
                  SizedBox(height: 20),
                  
                  // Animasyonlu kart örneği - Ekrana sığacak şekilde dinamik genişlik kullanıyoruz
                  Container(
                    width: MediaQuery.of(context).size.width > 350 ? 230 : MediaQuery.of(context).size.width * 0.6,
                    height: 120, // Biraz daha küçülttük
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.amber.shade50],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade200.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Book',
                                style: TextStyle(
                                  fontSize: 20, // Yazı boyutunu küçülttük
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Icon(
                                Icons.touch_app_rounded, 
                                color: Colors.amber.shade700,
                                size: 24, // İkon boyutunu küçülttük
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Dokunarak çevirin',
                                style: TextStyle(
                                  fontSize: 10, // Yazı boyutunu küçülttük
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Icon(Icons.menu_book, color: Colors.amber.shade200, size: 14),
                        ),
                        // Burada ses ikonunu da ekleyelim
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.volume_up, color: Colors.amber.shade700, size: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Kapat butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
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
          ),
        );
      },
    );
  }

  // Tanıtım adımları için yardımcı widget
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelime Kartları',
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
        child: FutureBuilder<List<word_list_model.WordList>>(
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
                    title: Text(
                      wordList.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    collapsedBackgroundColor: Colors.white,
                    backgroundColor: Colors.amber.shade50,
                    iconColor: Colors.amber.shade700,
                    collapsedIconColor: Colors.grey.shade700,
                    childrenPadding: EdgeInsets.symmetric(vertical: 8),
                    children: wordList.words.map((word) {
                      return Flashcard(word: word);
                    }).toList(),
                  );
                },
              );
            }
          },
        ),
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
  final AudioPlayer _audioPlayer = AudioPlayer(); // Bu satırı ekleyin
  bool _isLoadingAudio = false; // Bu satırı ekleyin
  bool _audioError = false; // Bu satırı ekleyin

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

  // Kelime telaffuzunu çalma fonksiyonu
  Future<void> _playPronunciation() async {
    // Ses çalarken kartın çevrilmesini engelleyelim
    if (_isLoadingAudio) return;
    
    setState(() {
      _isLoadingAudio = true;
      _audioError = false;
    });
    
    try {
      // Text-to-Speech API üzerinden kelimeyi alalım
      String word = widget.word.word.trim().toLowerCase();
      String audioUrl = "https://ssl.gstatic.com/dictionary/static/sounds/oxford/${word}--_us_1.mp3";
      
      await _audioPlayer.play(UrlSource(audioUrl));
      
      // Ses çalma tamamlandığında loading durumunu kapatalım
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
          });
        }
      });
      
    } catch (e) {
      print("Ses oynatma hatası: $e");
      
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _audioError = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Telaffuz bulunamadı'),
            backgroundColor: Colors.red.shade400,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose(); // Bu satırı ekleyin
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      behavior: HitTestBehavior.deferToChild, // Bu satırı ekleyin
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
      shadowColor: Colors.black26,
      child: Container(
        // Sabit değerler yerine ekrana uyumlu değerler
        width: MediaQuery.of(context).size.width > 400 ? 300 : MediaQuery.of(context).size.width * 0.85,
        height: 180, // Biraz daha küçük yükseklik
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade200.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16), // Daha küçük padding
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Icon(
                Icons.menu_book,
                color: Colors.amber.shade200,
                size: 18, // Daha küçük ikon
              ),
            ),
            
            // Telaffuz butonu ekle
            Positioned(
              top: 10,
              right: 10,
              child: InkWell(
                onTap: _playPronunciation, // Ses çalma metodunu çağır
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoadingAudio
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                        ),
                      )
                    : Icon(
                        _audioError ? Icons.volume_off : Icons.volume_up,
                        color: Colors.amber.shade700,
                        size: 18,
                      ),
                ),
              ),
            ),
            
            // Ortadaki kelime ve alt kısımdaki metin aynı kalacak
            Center(
              child: Text(
                widget.word.word,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(
                'Çevirmek için dokunun',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black26,
      child: Container(
        width: MediaQuery.of(context).size.width > 400 ? 300 : MediaQuery.of(context).size.width * 0.85,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade50, Colors.amber.shade100],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade300.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Icon(
                Icons.translate,
                color: Colors.amber.shade300,
                size: 18,
              ),
            ),
            Center(
              child: Text(
                widget.word.meaning,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(
                'Çevirmek için dokunun',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}