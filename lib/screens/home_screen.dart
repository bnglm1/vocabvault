import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'quiz_screen.dart';
import 'profile_screen.dart';
import 'word_list_groups_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'flashcard_screen.dart';
import 'sign_in_screen.dart';
import 'scanned_words_screen.dart';
import 'match_word_screen.dart';
import 'learn_screen.dart'; 
import '../models/word_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  File? _image;
  List<String> learnedWords = [];
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),
    ProfileScreen(), // Default score value
    Container(), // Placeholder for scan button
    const SettingsScreen(),
    const HelpScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadLearnedWords();

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

  Future<void> _loadLearnedWords() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final learnedWordsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('learnedWords')
          .get();
      setState(() {
        learnedWords = learnedWordsSnapshot.docs.map((doc) => doc['word'] as String).toList();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _pickImage();
    } else {
      setState(() {
        _selectedIndex = index;
        _animationController.forward(from: 0.0);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _extractTextFromImage(_image!);
    }
  }

  Future<void> _extractTextFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final List<String> excludedWords = [
      'to', 'a', 'an', 'the', 'your', 'you', 'it', 'he', 'she', 'they', 'we', 'i', 'me', 'my', 'mine', 'ours', 'us', 'him', 'her', 'his', 'hers', 'its', 'their', 'theirs',
      'and', 'or', 'but', 'so', 'because', 'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'shall', 'should',
      'can', 'could', 'may', 'might', 'must', 'of', 'in', 'on', 'at', 'by', 'with', 'about', 'for', 'as', 'into', 'onto', 'upon', 'together', 'from', 'out', 'off', 'up', 'down',
      'over', 'under', 'through', 'between', 'among', 'against', 'before', 'after', 'during', 'without', 'within', 'along', 'across', 'behind', 'around', 'above', 'below', 'beside',
    ];

    final List<String> words = recognizedText.blocks
        .expand((block) => block.lines)
        .expand((line) => line.elements)
        .map((element) => element.text)
        .where((word) => !excludedWords.contains(word.toLowerCase()))
        .where((word) => RegExp(r'^[a-zA-Z]+$').hasMatch(word))
        .where((word) => !learnedWords.contains(word.toLowerCase())) // Öğrenilmiş kelimeleri çıkar
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannedWordsScreen(words: words),
      ),
    );
  }

  final iconList = <IconData>[
    Icons.home,
    Icons.person,
    Icons.camera_alt, // Scan button
    Icons.settings,
    Icons.help,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'VocabVault', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.grey.shade800, // Mavi -> Koyu Gri
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          if (_isBannerAdReady)
            Container(
              alignment: Alignment.center,
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800, // Beyazdan gri tona değiştirildi
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey.shade800, // Beyazdan gri tona değiştirildi
            elevation: 0,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                activeIcon: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.explore, color: Colors.amber.shade700),
                ),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, color: Colors.amber.shade700),
                ),
                label: 'Profil',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.amber.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(Icons.document_scanner, color: Colors.white, size: 26),
                ),
                activeIcon: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.amber.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: Icon(Icons.document_scanner, color: Colors.white, size: 26),
                ),
                label: 'Tara',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune),
                activeIcon: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.tune, color: Colors.amber.shade700),
                ),
                label: 'Ayarlar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.help_rounded),
                activeIcon: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.help_rounded, color: Colors.amber.shade700),
                ),
                label: 'Yardım',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber.shade400, // Biraz daha açık amber tonu
            unselectedItemColor: Colors.grey.shade300, // Açık gri - Koyu arka plan için daha görünür
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: TextStyle(fontSize: 11),
            showUnselectedLabels: true,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFAF8F0), Colors.grey.shade200], // Mavi tonları -> Sarı-gri tonları
        ),
      ),
      child: Center(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          padding: EdgeInsets.all(24),
          childAspectRatio: 1.0,
          children: <Widget>[
            _buildFeatureCard(context, 'Quiz Başlat', Icons.play_circle_fill_rounded, 
                QuizScreen(wordList: WordList(id: "temp", name: "Word Lists", words: []))),
            _buildFeatureCard(context, 'Kelime Listeleri', Icons.format_list_bulleted_rounded, 
                WordListGroupsScreen()),
            _buildFeatureCard(context, 'Kelime Kartları', Icons.style_rounded, 
                FlashcardScreen()),
            _buildFeatureCard(context, 'Kelime Eşleştirme', Icons.extension_rounded, 
                MatchWordScreen()),
            _buildFeatureCard(context, 'Öğren', Icons.school_rounded, 
                LearnScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String text, IconData icon, Widget destination) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  size: 48, 
                  color: Colors.amber.shade700, // Mavi -> Amber
                ),
              ),
              SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800, // Mavi -> Koyu Gri
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}