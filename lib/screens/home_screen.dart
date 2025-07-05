import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:vocabvault2/screens/dictionary_screen.dart';
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
import 'word_detail_screen.dart';
import '../models/word_list.dart' as models;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/word_of_day_service.dart';
import 'package:flutter/services.dart';

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
    ProfileScreen(),
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
        .where((word) => !learnedWords.contains(word.toLowerCase()))
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
    Icons.camera_alt,
    Icons.settings,
    Icons.help,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VocabVault', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.grey.shade800,
        elevation: 4,
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.grey.shade800,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      drawer: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Drawer(
            backgroundColor: Colors.grey.shade100,
            elevation: 5,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.amber.shade50,
                        radius: 30,
                        child: Icon(Icons.person, size: 40, color: Colors.amber.shade700),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String username = 'Kullanıcı';
                          
                          if (snapshot.hasData && snapshot.data != null) {
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            if (userData != null && userData['username'] != null) {
                              username = userData['username'];
                            } else if (FirebaseAuth.instance.currentUser?.displayName != null) {
                              username = FirebaseAuth.instance.currentUser!.displayName!;
                            } else if (FirebaseAuth.instance.currentUser?.email != null) {
                              final email = FirebaseAuth.instance.currentUser!.email!;
                              username = email.split('@')[0];
                              username = username[0].toUpperCase() + username.substring(1);
                            }
                          }
                          
                          return Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Colors.grey.shade700),
                  title: const Text('Gizlilik Politikası'),
                  onTap: () {
                    Navigator.pop(context);
                    _showPrivacyPolicy(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.red.shade400),
                  title: const Text('Çıkış Yap'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _signOut(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                            ),
                            child: const Text('Çıkış Yap'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
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
          color: Colors.grey.shade800,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey.shade800,
            elevation: 0,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.explore),
                activeIcon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.explore, color: Colors.amber.shade700),
                ),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: Container(
                  padding: const EdgeInsets.all(10),
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
                  padding: const EdgeInsets.all(12),
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
                  child: const Icon(Icons.document_scanner, color: Colors.white, size: 26),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(12),
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
                  child: const Icon(Icons.document_scanner, color: Colors.white, size: 26),
                ),
                label: 'Tara',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.tune),
                activeIcon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.tune, color: Colors.amber.shade700),
                ),
                label: 'Ayarlar',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.help_rounded),
                activeIcon: Container(
                  padding: const EdgeInsets.all(10),
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
            selectedItemColor: Colors.amber.shade400,
            unselectedItemColor: Colors.grey.shade300,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            showUnselectedLabels: true,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigation will be handled automatically by AuthStateChanges listener
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              const Text('Çıkış yapılırken bir hata oluştu'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.amber.shade700),
            const SizedBox(width: 10),
            const Text('Gizlilik Politikası'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'VocabVault Gizlilik Politikası',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Son güncellenme: Haziran 2025',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'VocabVault, kullanıcılarımızın gizliliğini korumaya büyük önem vermektedir. Bu politika, uygulamamızı kullanırken topladığımız verileri ve bunların nasıl kullanıldığını açıklar.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Toplanan Veriler',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Hesap bilgileri (e-posta, kullanıcı adı)\n'
                '• Kelime listeleri ve öğrenme ilerlemesi\n'
                '• Uygulama kullanım istatistikleri\n'
                '• Cihaz bilgileri (işletim sistemi, dil ayarları)',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '2. Verilerin Kullanımı',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Topladığımız veriler şu amaçlarla kullanılır:\n'
                '• Kişiselleştirilmiş öğrenme deneyimi sunmak\n'
                '• Uygulama performansını ve kullanıcı deneyimini iyileştirmek\n'
                '• Kullanıcı hesaplarını yönetmek ve güvenliği sağlamak',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '3. Veri Güvenliği',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verileriniz Firebase altyapısında güvenli bir şekilde saklanmaktadır. Verilere erişim sınırlandırılmıştır ve endüstri standardı güvenlik önlemleri uygulanmaktadır.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '4. Üçüncü Taraf Hizmetleri',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uygulamamız, aşağıdaki üçüncü taraf hizmetlerini kullanmaktadır:\n'
                '• Firebase (Kimlik doğrulama, veritabanı)\n'
                '• Google AdMob (Reklamlar)\n'
                '• Google ML Kit (Görüntü işleme)\n'
                '• Çeşitli Sözlük API\'leri',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '5. İletişim',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gizlilik politikamızla ilgili sorularınız için vavocab@gmail.com adresine e-posta gönderebilirsiniz.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}

// Home Content (Ana İçerik) widget'ı
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _userName = 'Kullanıcı';
  int _wordsLearned = 0;
  int _dailyGoal = 20;
  int _streak = 0;
  Future<Map<String, dynamic>>? _wordOfDayFuture;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _wordOfDayFuture = WordOfDayService.getWordOfDay();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _userName = 'Yükleniyor...';
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Kullanıcı profil verilerini al
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userData = userDoc.data();
        
        // Bugünün ilerleme verilerini al
        final today = DateTime.now();
        final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final progressData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('progress')
            .doc(dateString)
            .get();
        
        if (mounted) {
          // Öncelik 1: Firestore'dan 'username' alanını kullan
          String name = userData?['username'] ?? '';
          
          // Öncelik 2: Eğer username boşsa, Auth'dan displayName'i dene
          if (name.isEmpty) {
            name = user.displayName ?? '';
          }
          
          // Öncelik 3: Hala boşsa, e-posta ön ekini kullan
          if (name.isEmpty) {
            if (user.email != null && user.email!.isNotEmpty) {
              name = user.email!.split('@')[0]; // @ işaretinden önceki kısmı isim olarak kullan
              // İlk harfi büyük yap
              if (name.isNotEmpty) {
                name = name[0].toUpperCase() + name.substring(1);
              }
            } else {
              name = 'Kullanıcı';
            }
          }
          
          setState(() {
            _userName = name;
            _dailyGoal = userData?['dailyGoal'] ?? 20;
            _streak = userData?['streak'] ?? 0;
            _wordsLearned = progressData.data()?['wordsLearned'] ?? 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userName = 'Kullanıcı';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _userName = 'Kullanıcı';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 32.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [const Color(0xFFFAF8F0), Colors.grey.shade200],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Karşılama başlık bölümü
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, 
                  vertical: 16.0
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String name = 'Kullanıcı';
                            
                            if (snapshot.hasData && snapshot.data != null) {
                              final userData = snapshot.data!.data() as Map<String, dynamic>?;
                              if (userData != null && userData['username'] != null) {
                                name = userData['username'];
                              } else if (FirebaseAuth.instance.currentUser?.displayName != null) {
                                name = FirebaseAuth.instance.currentUser!.displayName!;
                              } else if (FirebaseAuth.instance.currentUser?.email != null) {
                                final email = FirebaseAuth.instance.currentUser!.email!;
                                name = email.split('@')[0];
                                name = name[0].toUpperCase() + name.substring(1);
                              }
                            }
                            
                            return Text(
                              'Merhaba, $name!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        if (_streak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department, 
                                  color: Colors.amber.shade700, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '$_streak gün',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bugün ne kadar öğrenmek istersin?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Günlük hedef ilerleme bölümü
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.yellow.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Günlük Hedef',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$_wordsLearned / $_dailyGoal kelime',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _dailyGoal > 0 ? _wordsLearned / _dailyGoal : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _wordsLearned >= _dailyGoal 
                              ? Colors.green.shade400 
                              : Colors.amber.shade500,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Günün kelimesi kartı
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8.0,
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _wordOfDayFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildWordOfTheDayLoadingCard(message: "Günün kelimesi yükleniyor...");
                    }
                    
                    if (!snapshot.hasData || snapshot.data == null) {
                      return _buildWordOfTheDayFallbackCard();
                    }
                    
                    // Türkçe çevirinin mevcut olup olmadığını kontrol et
                    final wordData = snapshot.data!;
                    final hasTurkishMeaning = wordData['meaning'] is Map && 
                                              wordData['meaning']['tr'] != null &&
                                              wordData['meaning']['tr'].isNotEmpty;
                    
                    if (!hasTurkishMeaning && !_isTranslating) {
                      // Türkçe çeviri yoksa ve zaten çeviri yapılmıyorsa, çeviri yapılıyor durumunu göster
                      _isTranslating = true;
                      // Çeviri yenilemeyi tetikle
                      Future.delayed(Duration.zero, () async {
                        final freshData = await WordOfDayService.getWordOfDay();
                        if (mounted) {
                          setState(() {
                            _wordOfDayFuture = Future.value(freshData);
                            _isTranslating = false;
                          });
                        }
                      });
                      
                      return _buildWordOfTheDayLoadingCard(message: "Çeviri yapılıyor...");
                    }
                    
                    return _buildCollapsibleWordOfTheDay(wordData);
                  },
                ),
              ),
              
              // Özellik kartları ızgarası
              GridView.count(
                crossAxisCount: screenWidth > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(horizontalPadding),
                childAspectRatio: 1.0,
                children: <Widget>[
                  _buildFeatureCard(context, 'Quiz Başlat', Icons.play_circle_fill_rounded, 
                      QuizScreen(wordList: models.WordList(id: "temp", name: "Word Lists", words: []))),
                  _buildFeatureCard(context, 'Kelime Listeleri', Icons.format_list_bulleted_rounded, 
                      WordListGroupsScreen()),
                  _buildFeatureCard(context, 'Kelime Kartları', Icons.style_rounded, 
                      FlashcardScreen()),
                  _buildFeatureCard(context, 'Kelime Eşleştirme', Icons.extension_rounded, 
                      MatchWordScreen()),
                  _buildFeatureCard(context, 'Öğren', Icons.school_rounded, 
                      LearnScreen()),
                  _buildDictionaryButton(context),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.amber.shade100),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.amber.shade700),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Günün kelimesi için katlanır kartı oluştur
  Widget _buildCollapsibleWordOfTheDay(Map<String, dynamic> wordData) {
    final meaning = wordData['meaning'] is Map 
        ? wordData['meaning']['tr'] ?? wordData['meaning']['en'] ?? 'Tanım bulunamadı'
        : wordData['meaning'] ?? 'Tanım bulunamadı';
        
    final partOfSpeech = wordData['partOfSpeech'] is Map
        ? wordData['partOfSpeech']['tr'] ?? wordData['partOfSpeech']['en'] ?? ''
        : wordData['partOfSpeech'] ?? '';
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Detay sayfasına yönlendir
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordDetailScreen(wordData: wordData),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade50, Colors.amber.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve gösterge
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Günün Kelimesi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const Spacer(),
                    // Kelime türü (isim, fiil vb.)
                    if (partOfSpeech.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          partOfSpeech,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber.shade700),
                  ],
                ),
              ),
              
              Divider(color: Colors.amber.shade200),
              
              // Kelime ve anlamı
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kelime ve telaffuz
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          wordData['word'] ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (wordData['pronunciation'] != null)
                          Text(
                            wordData['pronunciation'],
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.volume_up, color: Colors.amber.shade600, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            // Telaffuz çalma
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Kelime anlamı - maksimum 2 satır göster, devamı detay sayfasında
                    Text(
                      meaning,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Devamını göster butonu
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Detay sayfasına yönlendir
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordDetailScreen(wordData: wordData),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Detayları Göster',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Yükleniyor durumunda günün kelimesi kartı
  Widget _buildWordOfTheDayLoadingCard({String message = "Yükleniyor..."}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Günün Kelimesi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
              const Spacer(),
              Icon(Icons.refresh, color: Colors.amber.shade600, size: 20),
            ],
          ),
          Divider(color: Colors.amber.shade200),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Yedek kelime kartı
  Widget _buildWordOfTheDayFallbackCard() {
    // Bugün için kelime yoksa yedek veri
    final Map<String, dynamic> fallbackWord = {
      'word': 'serendipity',
      'partOfSpeech': 'isim',
      'meaning': 'şans eseri güzel bir şey bulmak',
      'example': 'Finding that rare book was pure serendipity.',
      'exampleTranslation': 'O nadir kitabı bulmak tamamen şans eseriydi.',
      'synonyms': ['chance', 'fortune', 'luck', 'coincidence'],
    };
    
    return _buildCollapsibleWordOfTheDay(fallbackWord);
  }

  Widget _buildDictionaryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DictionaryScreen(initialQuery: null,)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.amber.shade100),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_rounded, size: 40, color: Colors.amber.shade700),
            const SizedBox(height: 12),
            Text(
              'Sözlük',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kelime türünü çeviren yardımcı metod
  String _translatePartOfSpeech(String pos) {
    final Map<String, String> translations = {
      'noun': 'isim',
      'verb': 'fiil',
      'adjective': 'sıfat',
      'adverb': 'zarf',
      'pronoun': 'zamir',
      'preposition': 'edat',
      'conjunction': 'bağlaç',
      'interjection': 'ünlem',
    };
    
    return translations[pos.toLowerCase()] ?? pos;
  }

  // Kullanıcının kelime listesine verilen kelimeyi ekler
  Future<void> _addWordToUserList(Map<String, dynamic> wordData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Giriş yapmalısınız.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }
    try {
      final userWordsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('words');
      final word = wordData['word'] ?? '';
      if (word.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kelime bilgisi eksik.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
        return;
      }
      // Kelime zaten var mı kontrol et
      final existing = await userWordsRef.where('word', isEqualTo: word).get();
      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bu kelime zaten listenizde var.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
        return;
      }
      await userWordsRef.add({
        'word': word,
        'meaning': wordData['meaning'] ?? '',
        'partOfSpeech': wordData['partOfSpeech'] ?? '',
        'example': wordData['example'] ?? '',
        'exampleTranslation': wordData['exampleTranslation'] ?? '',
        'synonyms': wordData['synonyms'] ?? [],
        'addedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kelime listenize eklendi!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kelime eklenirken hata oluştu.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}