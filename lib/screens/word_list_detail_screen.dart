import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';
import '../models/word_list.dart';
import '../models/word.dart';

class WordListDetailScreen extends StatefulWidget {
  final WordList wordList;
  final String username; // Kullanıcı adı

  const WordListDetailScreen({super.key, required this.wordList, required this.username});

  @override
  _WordListDetailScreenState createState() => _WordListDetailScreenState();
}

class _WordListDetailScreenState extends State<WordListDetailScreen> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _exampleSentenceController = TextEditingController();
  final translator = GoogleTranslator();
  
  // Bilgilendirme kartının gösterilip gösterilmediğini takip eden değişken
  bool _hasShownInfoCard = false;

  @override
  void initState() {
    super.initState();
    
    // Ekran yüklendikten sonra bilgilendirme kartını göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownInfoCard) {
        _showInfoCard();
        _hasShownInfoCard = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wordList.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey.shade800, // Renk amber olarak değiştirildi
        elevation: 2,
        actions: [
          // Bilgilendirme butonu eklendi
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoCard,
            tooltip: 'Bilgi',
          ),
        ],
      ),
      body: widget.wordList.words.isEmpty 
          ? _buildEmptyState() // Boş durum widgeti
          : ListView.builder(
              itemCount: widget.wordList.words.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  color: Colors.amber.shade50, // Kart rengi amber tonu
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Icon(Icons.book, color: Colors.amber.shade700),
                    ),
                    title: Text(
                      widget.wordList.words[index].word, 
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey.shade800)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          widget.wordList.words[index].meaning,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                        if (widget.wordList.words[index].exampleSentence.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              widget.wordList.words[index].exampleSentence,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Colors.amber.shade700),
                          onPressed: () => _showEditWordDialog(context, index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                          onPressed: () => _showDeleteConfirmation(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWordDialog(context),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Kelime Ekle'),
        elevation: 3,
      ),
    );
  }

  // Boş durum widgeti
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wysiwyg,
              size: 60,
              color: Colors.amber.shade300,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Bu listede henüz kelime bulunmuyor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Ekranın altındaki "Kelime Ekle" butonuna tıklayarak kelime ekleyebilirsiniz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showAddWordDialog(context),
            icon: Icon(Icons.add),
            label: Text('Kelime Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Silme onayı sorusu
  Future<void> _showDeleteConfirmation(int index) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
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
                '"${widget.wordList.words[index].word}" kelimesini silmek istediğinize emin misiniz?',
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
                      onPressed: () => Navigator.of(context).pop(),
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
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteWord(index);
                      },
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
      ),
    );
  }

  // Bilgilendirme kartı
  Future<void> _showInfoCard() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık ikonu
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade200.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Başlık
                  Text(
                    'Kelime Listesi Kullanımı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Bilgiler
                  _buildInfoItem(
                    icon: Icons.add_circle_outline,
                    title: 'Kelime Ekleme',
                    description: 'Sağ alt köşedeki "Kelime Ekle" butonuna tıklayarak listeye kelime ekleyebilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildInfoItem(
                    icon: Icons.edit_outlined,
                    title: 'Kelimeyi Düzenleme',
                    description: 'Kelimenin sağındaki kalem ikonuna tıklayarak kelimeyi düzenleyebilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildInfoItem(
                    icon: Icons.delete_outline,
                    title: 'Kelimeyi Silme',
                    description: 'Kelimenin sağındaki çöp kutusu ikonuna tıklayarak kelimeyi silebilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildInfoItem(
                    icon: Icons.translate,
                    title: 'Otomatik Çeviri',
                    description: 'Kelime eklerken veya düzenlerken, İngilizce kelimeyi yazdığınızda Türkçe anlamı otomatik olarak doldurulur.',
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Kapat butonu
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Anladım',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  // Yardımcı widget - bilgi öğesi
  Widget _buildInfoItem({
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
          child: Icon(icon, size: 20, color: Colors.amber.shade700),
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

  // Dialog'ları amber renklerine güncelle
  Future<void> _showAddWordDialog(BuildContext context) async {
    _wordController.clear();
    _meaningController.clear();
    _exampleSentenceController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
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
                    Icons.add_circle_outline,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                
                // Başlık
                Text(
                  'Kelime Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 20),
                
                TextField(
                  controller: _wordController,
                  decoration: InputDecoration(
                    labelText: 'Kelime (İngilizce)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    _fetchTranslation(value);
                  },
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _meaningController,
                  decoration: InputDecoration(
                    labelText: 'Anlamı (Türkçe)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _exampleSentenceController,
                  decoration: InputDecoration(
                    labelText: 'Örnek Cümle',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'İptal',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      child: Text('Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.wordList.words.add(Word(
                            id: UniqueKey().toString(),
                            word: _wordController.text,
                            meaning: _meaningController.text,
                            exampleSentence: _exampleSentenceController.text,
                          ));
                        });
                        _saveWordList();
                        Navigator.of(context).pop();
                      },
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

  Future<void> _showEditWordDialog(BuildContext context, int index) async {
    _wordController.text = widget.wordList.words[index].word;
    _meaningController.text = widget.wordList.words[index].meaning;
    _exampleSentenceController.text = widget.wordList.words[index].exampleSentence;
    
    // Düzenleme diyaloğu da benzer şekilde güncellendi
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
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
                    Icons.edit,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                
                // Başlık
                Text(
                  'Kelimeyi Düzenle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 20),
                
                TextField(
                  controller: _wordController,
                  decoration: InputDecoration(
                    labelText: 'Kelime (İngilizce)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    _fetchTranslation(value);
                  },
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _meaningController,
                  decoration: InputDecoration(
                    labelText: 'Anlamı (Türkçe)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _exampleSentenceController,
                  decoration: InputDecoration(
                    labelText: 'Örnek Cümle',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'İptal',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      child: Text('Kaydet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.wordList.words[index] = Word(
                            id: widget.wordList.words[index].id,
                            word: _wordController.text,
                            meaning: _meaningController.text,
                            exampleSentence: _exampleSentenceController.text,
                          );
                        });
                        _saveWordList();
                        Navigator.of(context).pop();
                      },
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

  void _deleteWord(int index) {
    setState(() {
      widget.wordList.words.removeAt(index);
    });
    _saveWordList();
  }

  void _saveWordList() async {
    if (widget.username.isNotEmpty && widget.wordList.id.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.username) // Kullanıcı adı ile belgeye erişim
          .collection('wordLists')
          .doc(widget.wordList.id)
          .set(widget.wordList.toMap());
    } else {
      print('Error: username or wordList.id is empty');
    }
  }

  Future<void> _fetchTranslation(String word) async {
    final translation = await translator.translate(word, from: 'en', to: 'tr');
    setState(() {
      _meaningController.text = translation.text;
    });
  }
}