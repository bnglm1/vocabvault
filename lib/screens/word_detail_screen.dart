import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> wordData;

  const WordDetailScreen({super.key, required this.wordData});

  @override
  Widget build(BuildContext context) {
    final meaning = wordData['meaning'] is Map 
        ? wordData['meaning']['tr'] ?? wordData['meaning']['en'] ?? 'Tanım bulunamadı'
        : wordData['meaning'] ?? 'Tanım bulunamadı';
        
    final partOfSpeech = wordData['partOfSpeech'] is Map
        ? wordData['partOfSpeech']['tr'] ?? wordData['partOfSpeech']['en'] ?? ''
        : wordData['partOfSpeech'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Daha açık gri arka plan
      appBar: AppBar(
        title: Text(
          'Günün Kelimesi',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.grey.shade700, // Koyu gri başlık
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kelime başlığı
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade600, Colors.grey.shade800], // Gri gradient
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          partOfSpeech,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.volume_up, color: Colors.white),
                        onPressed: () {
                          // Telaffuz çalma
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    wordData['word'] ?? '',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (wordData['pronunciation'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        wordData['pronunciation'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // İçerik bölümü
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Anlam
                  Text(
                    'Anlam',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      meaning,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 25),
                  
                  // Örnek
                  Text(
                    'Örnek Cümle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İngilizce örnek
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: EdgeInsets.only(right: 8, top: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                wordData['example'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Türkçe örnek
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: EdgeInsets.only(right: 8, top: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                wordData['exampleTranslation'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Eş anlamlılar
                  if (wordData.containsKey('synonyms') && 
                      wordData['synonyms'] is List && 
                      (wordData['synonyms'] as List).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 25),
                        Text(
                          'Eş Anlamlılar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (wordData['synonyms'] as List)
                              .map<Widget>((synonym) => Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Text(
                                      synonym.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              // Kelime listesi seçim ekranını göster
              _showWordListSelectionSheet(context, wordData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Kelime Listeme Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Kelime listesi seçim ekranı
  void _showWordListSelectionSheet(BuildContext context, Map<String, dynamic> wordData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WordListSelectionSheet(wordData: wordData),
    );
  }
}

// Kelime listesi seçim component'i - Firestore entegrasyonlu
class WordListSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> wordData;
  
  const WordListSelectionSheet({super.key, required this.wordData});

  @override
  _WordListSelectionSheetState createState() => _WordListSelectionSheetState();
}

class _WordListSelectionSheetState extends State<WordListSelectionSheet> {
  final TextEditingController _newListController = TextEditingController();
  bool _isCreatingNewList = false;
  bool _isLoading = true;
  List<WordListWithWords> _userWordLists = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserWordLists();
  }
  
  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }
  
  // Firestore'dan kullanıcının kelime listelerini yükleme
  Future<void> _loadUserWordLists() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wordLists')
            .get();
            
        final lists = snapshot.docs.map((doc) {
          // Her listede bulunan kelimeler
          List<String> words = [];
          if (doc.data().containsKey('words') && doc['words'] is List) {
            words = (doc['words'] as List)
                .map((w) => w['word']?.toString().toLowerCase() ?? '')
                .where((w) => w.isNotEmpty)
                .toList();
          }
          
          return WordListWithWords(
            id: doc.id,
            name: doc['name'],
            wordCount: (doc['words'] as List?)?.length ?? 0,
            words: words
          );
        }).toList();
            
        setState(() {
          _userWordLists = lists;
        });
      }
    } catch (e) {
      print('Kelime listeleri yüklenirken hata: $e');
      // Demo amaçlı örnek veriler
      setState(() {
        _userWordLists = [
          WordListWithWords(id: '1', name: 'Favori Kelimeler', wordCount: 12, words: []),
          WordListWithWords(id: '2', name: 'Günlük Kelimeler', wordCount: 8, words: []),
          WordListWithWords(id: '3', name: 'Akademik Kelimeler', wordCount: 24, words: []),
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Günün kelimesinin küçük harflerle gösterimi (karşılaştırma için)
    final currentWordLower = widget.wordData['word'].toString().toLowerCase();
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Gri arka plan
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Text(
                  'Kelimeyi Listeye Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 10),
            
            // Kelime bilgisi özeti
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.text_fields, color: Colors.grey.shade700),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.wordData['word'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.wordData['meaning'] is Map 
                              ? widget.wordData['meaning']['tr'] ?? '' 
                              : widget.wordData['meaning'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            Text(
              'Kelime Listeleriniz:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 5),
            
            // Kelime listeleri
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              )
            else if (_userWordLists.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Henüz kelime listeniz bulunmuyor.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _userWordLists.length,
                  itemBuilder: (context, index) {
                    final list = _userWordLists[index];
                    
                    // Kelime bu listede var mı kontrol et
                    final bool wordAlreadyExists = list.words.contains(currentWordLower);
                    
                    return ListTile(
                      leading: Icon(
                        wordAlreadyExists ? Icons.check_circle : Icons.list_alt, 
                        color: wordAlreadyExists ? Colors.green.shade600 : Colors.grey.shade600
                      ),
                      title: Text(
                        list.name,
                        style: TextStyle(
                          color: wordAlreadyExists ? Colors.green.shade600 : Colors.grey.shade800,
                          fontWeight: wordAlreadyExists ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text('${list.wordCount} kelime'),
                          if (wordAlreadyExists)
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Bu kelime zaten listede',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12
                                ),
                              ),
                            ),
                        ],
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      enabled: !wordAlreadyExists, // Eğer kelime zaten varsa devre dışı bırak
                      onTap: wordAlreadyExists 
                        ? null
                        : () {
                            _addWordToList(list.id, list.name);
                            Navigator.pop(context);
                          },
                    );
                  },
                ),
              ),
            
            Divider(color: Colors.grey.shade400),
            
            // Yeni liste oluşturma alanı
            if (_isCreatingNewList)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newListController,
                        decoration: InputDecoration(
                          hintText: 'Yeni liste adı',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        autofocus: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_newListController.text.trim().isNotEmpty) {
                          _createNewList(_newListController.text.trim());
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text('Ekle'),
                    ),
                  ],
                ),
              )
            else
              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text('Yeni Liste Oluştur'),
                onPressed: () {
                  setState(() {
                    _isCreatingNewList = true;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Kelimeyi seçilen listeye ekleme
  Future<void> _addWordToList(String listId, String listName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Oturum açmanız gerekiyor"),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
      
      // Günün kelimesinin küçük harflerle gösterimi
      final currentWordLower = widget.wordData['word'].toString().toLowerCase();
      
      // Önce listeyi çekelim ve kelime zaten var mı kontrol edelim
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wordLists')
          .doc(listId);
      
      final docSnap = await docRef.get();
      
      if (!docSnap.exists) {
        throw Exception('Bu liste artık mevcut değil');
      }
      
      // Listedeki kelimeleri kontrol edelim
      if (docSnap.data() != null && 
          docSnap.data()!.containsKey('words') && 
          docSnap.data()!['words'] is List) {
        
        final existingWords = (docSnap.data()!['words'] as List)
            .map((w) => w['word']?.toString().toLowerCase() ?? '')
            .where((w) => w.isNotEmpty)
            .toList();
        
        // Eğer kelime zaten listede varsa
        if (existingWords.contains(currentWordLower)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("\"${widget.wordData['word']}\" kelimesi zaten \"$listName\" listesinde mevcut"),
              backgroundColor: Colors.orange.shade700,
            ),
          );
          return;
        }
      }
      
      // Kelimeyi hazırla
      final wordToAdd = {
        'word': widget.wordData['word'].toString(),
        'meaning': widget.wordData['meaning'] is Map 
            ? widget.wordData['meaning']['tr']?.toString() ?? widget.wordData['meaning']['en']?.toString() ?? ''
            : widget.wordData['meaning']?.toString() ?? '',
        'partOfSpeech': widget.wordData['partOfSpeech']?.toString() ?? '',
        'example': widget.wordData['example']?.toString() ?? '',
        'exampleTranslation': widget.wordData['exampleTranslation']?.toString() ?? '',
        'dateAdded': Timestamp.now(),
      };
      
      // Eğer words alanı yoksa, yeni oluşturalım
      if (docSnap.data() != null && !(docSnap.data() as Map).containsKey('words')) {
        await docRef.set({
          'words': [wordToAdd]
        }, SetOptions(merge: true));
      } else {
        // Words alanı varsa, arrayUnion ile ekleyelim
        await docRef.update({
          'words': FieldValue.arrayUnion([wordToAdd])
        });
      }
      
      // Kullanıcıya bildir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("\"${widget.wordData['word']}\" kelimesi \"$listName\" listesine eklendi"),
          backgroundColor: Colors.grey.shade700,
        ),
      );
      
    } catch (e) {
      print('Kelime eklenirken hata: $e');
      String errorMsg = 'Kelime eklenemedi.';
      
      if (e.toString().contains('permission-denied')) {
        errorMsg += ' Yetki hatası.';
      } else if (e.toString().contains('not-found')) {
        errorMsg += ' Liste bulunamadı.';
      } else {
        errorMsg += ' Lütfen tekrar deneyin.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
  
  // Yeni kelime listesi oluşturma
  Future<void> _createNewList(String listName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Yeni listeyi oluştur
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wordLists')
            .add({
              'name': listName,
              'createdAt': FieldValue.serverTimestamp(),
              'words': [
                {
                  'word': widget.wordData['word'],
                  'meaning': widget.wordData['meaning'],
                  'partOfSpeech': widget.wordData['partOfSpeech'],
                  'example': widget.wordData['example'],
                  'exampleTranslation': widget.wordData['exampleTranslation'],
                  'dateAdded': FieldValue.serverTimestamp(),
                }
              ]
            });
        
        // Listeleri yeniden yükle
        setState(() {
          _userWordLists.add(WordListWithWords(
            id: docRef.id, 
            name: listName, 
            wordCount: 1, 
            words: [widget.wordData['word'].toString().toLowerCase()]
          ));
          _isCreatingNewList = false;
          _newListController.clear();
        });
        
        // Kullanıcıya bildir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("\"$listName\" listesi oluşturuldu ve kelime eklendi"),
            backgroundColor: Colors.grey.shade700,
          ),
        );
        
        // Bottom sheet'i kapat
        Navigator.pop(context);
      }
    } catch (e) {
      print('Liste oluşturulurken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Liste oluşturulamadı. Lütfen tekrar deneyin."),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

// Kelime listesi modelini genişletelim
class WordListWithWords {
  final String id;
  final String name;
  final int wordCount;
  final List<String> words; // Listedeki kelimeler
  
  WordListWithWords({
    required this.id,
    required this.name,
    required this.wordCount,
    required this.words,
  });
}