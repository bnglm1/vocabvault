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
        title: Text('VocabVault', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_enhance),
            label: 'Tara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Yardım',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey, // Seçili olmayan ikonların rengi
        onTap: _onItemTapped,
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
          colors: [Colors.blue.shade200, Colors.blue.shade50],
        ),
      ),
      child: Center(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          padding: EdgeInsets.all(20),
          children: <Widget>[
            _buildCard(context, 'Quiz Başlat', Icons.play_arrow, QuizScreen(wordList: WordList(id: "temp", name: "Word Lists", words: []))),
            _buildCard(context, 'Kelime Listeleri oluştur', Icons.list, WordListGroupsScreen()),
            _buildCard(context, 'Kelime Kartları', Icons.card_membership, FlashcardScreen()),
            _buildCard(context, 'Kelime Eşleştirme', Icons.gamepad, MatchWordScreen()),
            _buildCard(context, 'Öğren', Icons.school, LearnScreen()), // Yeni ekranı ekleyin
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String text, IconData icon, Widget destination) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 50, color: Colors.blue.shade700),
              SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}