import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocabvault2/models/word_list.dart';
import '../models/word.dart';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/quiz_result.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.wordList});

  final WordList wordList;

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Word> words = [];
  int currentIndex = 0;
  int score = 0;
  bool isLoading = true;
  Random random = Random();
  int questionType = 0; // 0: Türkçe -> İngilizce, 1: İngilizce -> Türkçe, 2: Yazma Görevi
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  List<bool> answers = [];
  final TextEditingController _textEditingController = TextEditingController();
  late DateTime quizStartTime;
  bool _hasShownTutorial = false;
  String currentFeedback = '';
  bool showFeedback = false;
  String _selectedAnswer = ""; // Sınıf değişkenleri arasına ekleyin

  @override
  void initState() {
    super.initState();
    quizStartTime = DateTime.now(); // Quiz başladığında tarih ve saat bilgisini kaydet
    _showWordListDialog();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7690250755006392/9374915842',
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _showWordListDialog() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wordLists')
          .get();

      List<WordList> wordLists = querySnapshot.docs
          .map((doc) => WordList.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      showDialog(
        context: context,
        barrierDismissible: false, // Dışarı tıklandığında kapanmasını engeller
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Kelime Listesi Seçin',
              style: TextStyle(
                color: Colors.amber.shade800,
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
              if (wordLists.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dialog'u kapat
                    Navigator.of(context).pop(); // Quiz ekranını kapat
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: Text('İptal'),
                ),
              if (wordLists.isEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dialog'u kapat
                    Navigator.of(context).pop(); // Quiz ekranını kapat
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber.shade700,
                  ),
                  child: Text('Ana Sayfaya Dön'),
                ),
            ],
          );
        },
      );
    }
  }

  Future<void> _loadWords(String listId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wordLists')
          .doc(listId)
          .get();

      List<Word> loadedWords = (docSnapshot['words'] as List)
          .map((wordData) => Word.fromMap(wordData as Map<String, dynamic>, docSnapshot.id))
          .toList();
      
      // En az 4 kelime olmasını sağla (yoksa hata olur)
      if (loadedWords.isEmpty) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kelime listesi boş!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        words = loadedWords;
        isLoading = false;
        _nextQuestion();
        
        // Tutorial gösterimi için kullanıcı arayüzü güncellemesi tamamlandıktan sonra çağrı yapılıyor
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTutorialDialog();
        });
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading words: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelimeler yüklenirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nextQuestion() {
    setState(() {
      questionType = random.nextInt(3); // 0: Türkçe -> İngilizce, 1: İngilizce -> Türkçe, 2: Yazma Görevi
      _textEditingController.clear();
      showFeedback = false;
    });
  }

  void checkAnswer(String selectedAnswer) {
    bool isCorrect = false;
    String correctAnswer = "";
    
    // Seçilen cevabı kaydet
    _selectedAnswer = selectedAnswer;

    if (questionType == 0) {
      correctAnswer = words[currentIndex].word;
      isCorrect = selectedAnswer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
    } else if (questionType == 1) {
      correctAnswer = words[currentIndex].meaning;
      isCorrect = selectedAnswer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
    } else if (questionType == 2) {
      correctAnswer = words[currentIndex].word;
      isCorrect = selectedAnswer.trim().toLowerCase() == correctAnswer.toLowerCase().trim();
    }

    // Geri bildirim göster
    setState(() {
      showFeedback = true;
      if (isCorrect) {
        currentFeedback = 'Doğru! 👍';
      } else {
        currentFeedback = 'Yanlış. Doğru cevap: $correctAnswer';
      }
    });

    // Kısa bir süre bekleyip sonraki soruya geç
    Future.delayed(Duration(milliseconds: 1200), () {
      if (!mounted) return;
      
      answers.add(isCorrect);
      if (isCorrect) {
        score++;
      }

      if (currentIndex < words.length - 1) {
        setState(() {
          currentIndex++;
          _nextQuestion();
        });
      } else {
        // Quiz bitti, sonucu kaydet ve sonuç ekranına yönlendir
        _saveQuizScore();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              correctAnswers: score,
              incorrectAnswers: words.length - score,
              words: words,
              answers: answers,
            ),
          ),
        );
      }
    });
  }

  void _saveQuizScore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      CollectionReference scoresCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quizScores');
          
      await scoresCollection.add({
        'timestamp': quizStartTime.toIso8601String(),
        'score': score,
        'totalQuestions': words.length,
        'percentage': (score / words.length) * 100,
      });
    } catch (e) {
      print('Error saving quiz score: $e');
    }
  }

  Future<void> _showTutorialDialog() async {
    // Sadece bir kez göster
    if (_hasShownTutorial) return Future.value();
    _hasShownTutorial = true;
    
    return showDialog(
      context: context,
      barrierDismissible: false, // Dışına tıklandığında kapanmaz
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.amber.shade50],
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
                    child: Icon(Icons.quiz, color: Colors.amber.shade700, size: 24),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Quiz Nasıl Çalışır?',
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
                    icon: Icons.translate,
                    title: 'Türkçe-İngilizce Çevirisi',
                    description: 'Verilen Türkçe kelimenin İngilizce karşılığını seçin.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildTutorialStep(
                    icon: Icons.language,
                    title: 'İngilizce-Türkçe Çevirisi',
                    description: 'Verilen İngilizce kelimenin Türkçe karşılığını seçin.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildTutorialStep(
                    icon: Icons.edit,
                    title: 'Yazma Görevi',
                    description: 'Verilen Türkçe kelimenin İngilizce karşılığını yazın.',
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

  // Tutorial adımları için yardımcı widget
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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.grey.shade800,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.amber.shade50, Colors.grey.shade100],
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
                  "Kelimeler yükleniyor...",
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

    if (words.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey.shade800,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.amber.shade50, Colors.grey.shade100],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.amber.shade300,
                ),
                SizedBox(height: 20),
                Text(
                  'Kelime listesi boş!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Lütfen kelime ekleyip tekrar deneyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Ana Sayfaya Dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // Ekranın klavye ile yeniden boyutlandırılmasını engelle
      appBar: AppBar(
        title: Text('Quiz', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey.shade800, // Amber'dan mavi renge değiştirildi
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                '${currentIndex + 1} / ${words.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.shade50, Colors.grey.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // İlerleme çubuğu
              LinearProgressIndicator(
                value: (currentIndex + 1) / words.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
              ),
              
              // Skor göstergesi
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber.shade400,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Skor: $score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              
              // İçerik alanını Expanded yerine SingleChildScrollView ile değiştirildi
              Expanded(
                child: SingleChildScrollView(
                  // Klavye açıldığında otomatik kaydırmayı etkinleştir
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0), // Alt kısımda ekstra padding
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        // Soru kartı
                        Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Colors.amber.shade50],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                // Soru tipi ikonu
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    questionType == 0 ? Icons.translate : 
                                    questionType == 1 ? Icons.language : 
                                    Icons.edit,
                                    color: Colors.amber.shade700,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                _buildQuestion(),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Cevap seçenekleri
                        _buildAnswerOptions(),
                        
                        // Yazma görevi için gönder butonu
                        if (questionType == 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton(
                              onPressed: showFeedback ? null : () => checkAnswer(_textEditingController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                disabledBackgroundColor: Colors.grey.shade400,
                              ),
                              child: Text(
                                'Cevabı Gönder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        
                        // Geri bildirim alanı
                        if (showFeedback)
                          AnimatedOpacity(
                            opacity: showFeedback ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: Container(
                              margin: EdgeInsets.only(top: 16),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: currentFeedback.startsWith('Doğru') ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: currentFeedback.startsWith('Doğru') ? Colors.green.shade400 : Colors.red.shade400,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    currentFeedback.startsWith('Doğru') ? Icons.check_circle : Icons.cancel,
                                    color: currentFeedback.startsWith('Doğru') ? Colors.green.shade700 : Colors.red.shade700,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    currentFeedback,
                                    style: TextStyle(
                                      color: currentFeedback.startsWith('Doğru') ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                        // Klavye için ekstra boşluk
                        questionType == 2 ? SizedBox(height: 200) : SizedBox(height: 0),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Reklam alanı
              if (_isBannerAdReady)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    if (questionType == 0) {
      return Column(
        children: [
          Text(
            'Türkçe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            words[currentIndex].meaning,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'İngilizcesi nedir?',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    } else if (questionType == 1) {
      return Column(
        children: [
          Text(
            'İngilizce',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            words[currentIndex].word,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Türkçesi nedir?',
            style: TextStyle(
              fontSize: 14, 
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            'Türkçe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            words[currentIndex].meaning,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'İngilizcesini yazınız:',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _textEditingController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.amber.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
              ),
              labelText: 'İngilizce',
              labelStyle: TextStyle(color: Colors.grey.shade600),
            ),
            onSubmitted: (value) {
              if (!showFeedback) {
                checkAnswer(value);
              }
            },
            enabled: !showFeedback,
          ),
        ],
      );
    }
  }

  Widget _buildAnswerOptions() {
    if (questionType == 2) {
      return Container(); // Yazma görevi için seçenekler yok
    }

    List<String> options = _generateOptions();
    String correctAnswer = "";
    
    if (questionType == 0) {
      correctAnswer = words[currentIndex].word;
    } else {
      correctAnswer = words[currentIndex].meaning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: options.map((option) {
          bool isCorrectOption = option.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
          bool isSelectedWrongOption = showFeedback && !isCorrectOption && 
                                   option == _textEditingController.text; // Seçilen yanlış cevap
        
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: ElevatedButton(
              onPressed: showFeedback ? null : () => checkAnswer(option),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: showFeedback && isCorrectOption 
                    ? Colors.green.shade100 
                    : isSelectedWrongOption
                        ? Colors.red.shade100  // Yanlış seçenek için kırmızı arkaplan
                        : Colors.white,
                foregroundColor: showFeedback && isCorrectOption
                    ? Colors.green.shade800
                    : isSelectedWrongOption
                        ? Colors.red.shade800  // Yanlış seçenek için kırmızı yazı
                        : Colors.grey.shade800,
                disabledBackgroundColor: showFeedback && isCorrectOption 
                    ? Colors.green.shade100 
                    : isSelectedWrongOption
                        ? Colors.red.shade100  // Yanlış seçenek için kırmızı arkaplan (disabled)
                        : Colors.grey.shade100,
                disabledForegroundColor: showFeedback && isCorrectOption
                    ? Colors.green.shade800
                    : isSelectedWrongOption
                        ? Colors.red.shade800  // Yanlış seçenek için kırmızı yazı (disabled)
                        : Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: showFeedback && isCorrectOption 
                        ? Colors.green.shade400 
                        : isSelectedWrongOption
                            ? Colors.red.shade400  // Yanlış seçenek için kırmızı kenarlık
                            : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (showFeedback && isCorrectOption)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    ),
                  if (showFeedback && isSelectedWrongOption)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                    ),
                  Expanded(
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: (showFeedback && (isCorrectOption || isSelectedWrongOption)) 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> _generateOptions() {
    List<String> options = [];
    String correctAnswer;

    if (questionType == 0) {
      correctAnswer = words[currentIndex].word;
    } else {
      correctAnswer = words[currentIndex].meaning;
    }

    options.add(correctAnswer);
    
    // Çoğaltılmış kelime listesini oluşturma
    List<String> allOptions = [];
    if (questionType == 0) {
      allOptions = words.map((word) => word.word).toList();
    } else {
      allOptions = words.map((word) => word.meaning).toList();
    }
    
    // Doğru cevabı çıkar, tekrar eklenmemesi için
    allOptions.remove(correctAnswer);
    
    // Karıştır ve ilk 3 tanesini al
    allOptions.shuffle();
    options.addAll(allOptions.take(3));
    
    if (options.length < 4) {
      // Eğer yeterli benzersiz seçenek yoksa, mevcut seçeneklerle doldur
      while (options.length < 4) {
        String existingOption = options[random.nextInt(options.length)];
        if (!options.contains("$existingOption?")) {
          options.add("$existingOption?");
        }
      }
    }

    options.shuffle();
    return options;
  }
}

// WidgetStateProperty sınıfı burada tanımlanmamış, bunu flutter'ın MaterialStateProperty'si ile değiştirelim