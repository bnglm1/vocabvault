import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScannedWordsScreen extends StatefulWidget {
  final List<String> words;

  const ScannedWordsScreen({super.key, required this.words});

  @override
  _ScannedWordsScreenState createState() => _ScannedWordsScreenState();
}

class _ScannedWordsScreenState extends State<ScannedWordsScreen> {
  final translator = GoogleTranslator();
  final Map<String, String> translations = {};
  final Map<String, TextEditingController> translationControllers = {};
  final TextEditingController _listNameController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool isTranslating = true;
  List<String> selectedWords = [];
  
  // Kelimelerin benzersiz listesi için yeni değişken
  late List<String> uniqueWords;

  // Sınıf değişkenleri arasına ekleyin
  bool _hasShownTips = false;

  @override
  void initState() {
    super.initState();
    
    // Tekrar eden kelimeleri kaldır ve benzersiz kelime listesi oluştur
    uniqueWords = _removeDuplicateWords(widget.words);
    
    _initializeControllers();
    _translateWords();

    // Ekran yüklendikten sonra kullanım ipuçları göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUsageTips();
    });
  }

  // Tekrarlanan kelimeleri kaldırmak için metodu güncelle
  List<String> _removeDuplicateWords(List<String> wordList) {
    // Aynı kelimenin farklı büyük/küçük harf versiyonlarını birleştirmek için harita
    final Map<String, String> uniqueWordsMap = {};
    
    for (String word in wordList) {
      // Temizlenmiş kelime
      String trimmedWord = word.trim();
      
      // Boş kelimeyi atla
      if (trimmedWord.isEmpty) continue;
      
      // Küçük harfli versiyonu anahtar olarak kullan
      String lowerCaseWord = trimmedWord.toLowerCase();
      
      // Daha uygun format seçimi
      if (!uniqueWordsMap.containsKey(lowerCaseWord)) {
        uniqueWordsMap[lowerCaseWord] = trimmedWord;
      } else {
        // İlk harfi büyük olan versiyonu tercih et
        String existingWord = uniqueWordsMap[lowerCaseWord]!;
        
        // İlk harf büyükse ve diğeri tamamen büyük değilse, ilk harfi büyük olanı seç
        if (trimmedWord.isNotEmpty && 
            trimmedWord[0].toUpperCase() == trimmedWord[0] && 
            existingWord.toUpperCase() == existingWord) {
          uniqueWordsMap[lowerCaseWord] = trimmedWord;
        }
      }
    }
    
    // Haritadan değerleri al
    return uniqueWordsMap.values.toList();
  }

  void _initializeControllers() {
    // widget.words yerine uniqueWords kullan
    for (String word in uniqueWords) {
      translationControllers[word] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _listNameController.dispose();
    for (var controller in translationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _translateWords() async {
    setState(() {
      isTranslating = true;
    });

    // widget.words yerine uniqueWords kullan
    for (String word in uniqueWords) {
      try {
        final translation = await translator.translate(word, from: 'en', to: 'tr');
        if (mounted) {
          setState(() {
            translations[word] = translation.text;
            translationControllers[word]?.text = translation.text;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            translations[word] = "Çeviri hatası";
            translationControllers[word]?.text = "Çeviri hatası";
          });
        }
        print('Translation error for $word: $e');
      }
    }

    // Burada mounted kontrolü ekleyin
    if (mounted) {  // Widget hala görüntüleniyorsa
      setState(() {
        isTranslating = false;
      });
    }
  }

  Future<void> _saveWordList() async {
    final listName = _listNameController.text.trim();
    if (listName.isEmpty) {
      _showSnackBar('Lütfen bir liste ismi girin');
      return;
    }

    // Tüm kelimeler veya sadece seçili olanlar
    final List<String> wordsToSave = selectedWords.isEmpty ? 
        [...uniqueWords] : selectedWords;  // widget.words yerine uniqueWords

    final wordList = wordsToSave.map((word) => {
      'word': word,
      'meaning': translationControllers[word]?.text ?? translations[word] ?? 'Çeviri bulunamadı',
      'exampleSentence': '',
    }).toList();

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('wordLists')
            .add({
          'name': listName,
          'words': wordList,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar('Kelime listesi başarıyla kaydedildi');
        Navigator.pop(context, true); // Başarılı olduğunu belirtmek için true döndür
      } catch (e) {
        _showSnackBar('Kaydetme hatası: ${e.toString()}');
      }
    } else {
      _showSnackBar('Kullanıcı oturumu açık değil');
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
        duration: Duration(milliseconds: 1500),
      )
    );
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık ikonu
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.save_alt,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                
                // Başlık
                Text(
                  'Kelime Listesini Kaydet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 20),
                
                // Liste ismi
                TextField(
                  controller: _listNameController,
                  decoration: InputDecoration(
                    labelText: 'Liste İsmi',
                    hintText: 'Anlamlı bir isim girin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                    prefixIcon: Icon(Icons.list_alt, color: Colors.amber.shade700),
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 16),
                
                // Bilgi metni
                Text(
                  selectedWords.isEmpty 
                      ? 'Tüm kelimeler kaydedilecek (${widget.words.length} kelime)' 
                      : 'Seçilen kelimeler kaydedilecek (${selectedWords.length} kelime)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 24),
                
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveWordList();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        'Kaydet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleWordSelection(String word) {
    setState(() {
      if (selectedWords.contains(word)) {
        selectedWords.remove(word);
      } else {
        selectedWords.add(word);
      }
    });
  }

  Future<void> _showUsageTips() async {
    if (_hasShownTips) return;
    _hasShownTips = true;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20.0),
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.tips_and_updates,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                
                Text(
                  'Kelime Listesi İpuçları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                SizedBox(height: 20),
                
                // İpuçları - renkleri uygulama temasına uygun olarak değiştirildi
                _buildTipItem(
                  icon: Icons.swipe,
                  text: 'Kelimeyi silmek için sola kaydırın',
                  color: Colors.amber.shade600,
                ),
                SizedBox(height: 12),
                
                _buildTipItem(
                  icon: Icons.save,
                  text: 'İşlem tamamlandığında "Kaydet" butonuna tıklayın',
                  color: Colors.amber.shade600,
                ),
                
                SizedBox(height: 24),
                
                // Kapat butonu - daha belirgin hale getirildi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'Anladım',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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

  // Yardımcı metot
  Widget _buildTipItem({
    required IconData icon, 
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final translatedCount = translations.length;
    final totalCount = uniqueWords.length;  // widget.words yerine uniqueWords

    return Scaffold(
      appBar: AppBar(
        title: Text('Taranan Kelimeler', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber.shade700,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          if (isTranslating)
            LinearProgressIndicator(
              value: translatedCount / totalCount,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700), // Mavi yerine amber
            ),

          // Info bar - Taşma sorunu çözümü
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Icon(
                  isTranslating ? Icons.translate : Icons.check_circle,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded( // Expanded widget ile metin taşması önlenir
                  child: Text(
                    isTranslating
                        ? 'Çeviri yapılıyor: $translatedCount / $totalCount'
                        : 'Çeviri tamamlandı. Silmek istediğiniz kelimeyi sola kaydırın.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.shade800,
                    ),
                    // Gerekirse çok satırlı metin olarak göster
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),

          // Word list - Basitleştirilmiş
          Expanded(
            child: uniqueWords.isEmpty  // widget.words yerine uniqueWords
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt, size: 48, color: Colors.grey.shade400),
                        SizedBox(height: 12),
                        Text(
                          'Taranmış kelime bulunamadı.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 80),
                    itemCount: uniqueWords.length,  // widget.words yerine uniqueWords
                    itemBuilder: (context, index) {
                      final word = uniqueWords[index];  // widget.words yerine uniqueWords
                      final translation = translations[word] ?? 'Çeviriliyor...';

                      return Dismissible(
                        key: Key(word),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                          color: Colors.red.shade400,
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // İkon
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.delete_forever,
                                          color: Colors.red.shade500,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      
                                      // Başlık
                                      Text(
                                        'Kelimeyi Sil',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      
                                      // İçerik
                                      Text(
                                        'Bu kelimeyi silmek istediğinize emin misiniz?',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      
                                      // Butonlar
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // İptal butonu
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: Colors.grey.shade400),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: Text(
                                                'Vazgeç',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          
                                          // Sil butonu
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red.shade500,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              icon: Icon(Icons.delete_outline, size: 18),
                                              label: Text(
                                                'Sil',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          setState(() {
                            uniqueWords.remove(word); // widget.words.removeAt(index) yerine
                            // Eğer kelime seçili ise seçilenleri de güncelle
                            if (selectedWords.contains(word)) {
                              selectedWords.remove(word);
                            }
                          });
                          _showSnackBar('Kelime silindi');
                        },
                        // Basitleştirilmiş kart tasarımı
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // İngilizce kelime
                                Text(
                                  word,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                
                                SizedBox(height: 4),
                                
                                // Türkçe çeviri - artık düzenlenemez
                                Row(
                                  children: [
                                    Icon(
                                      Icons.translate, 
                                      size: 14, 
                                      color: Colors.grey.shade500
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        translation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    // Yükleme göstergesi
                                    if (isTranslating && !translations.containsKey(word))
                                      SizedBox(
                                        height: 12,
                                        width: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700), // Mavi yerine amber
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: !isTranslating ? _showSaveDialog : null,
        backgroundColor: Colors.amber.shade700, // Mavi yerine amber
        foregroundColor: Colors.white,
        icon: Icon(Icons.save),
        label: Text(
          'Listeyi Kaydet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}