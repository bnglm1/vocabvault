import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'word_list_detail_screen.dart';
import 'package:vocabvault2/models/word_list.dart';

class WordListGroupsScreen extends StatefulWidget {
  const WordListGroupsScreen({super.key});

  @override
  _WordListGroupsScreenState createState() => _WordListGroupsScreenState();
}

class _WordListGroupsScreenState extends State<WordListGroupsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  List<WordList> wordLists = [];
  bool isLoading = true;

  // Mevcut değişkenlere ekle
  bool _hasShownInfoCard = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadWordLists();
    
    // Ekran ilk yüklendiğinde bilgilendirme kartını göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownInfoCard) {
        _showInfoCard();
        _hasShownInfoCard = true;
      }
    });
  }

  Future<void> _loadWordLists() async {
    if (_user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid) // Kullanıcı UID'si ile belgeye erişim
          .collection('wordLists')
          .get();
      if (mounted) {
        setState(() {
          wordLists = querySnapshot.docs
              .map((doc) => WordList.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          isLoading = false;
        });
      }
    } else {
      print('Error: user is not logged in');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addWordList(String listName) async {
    if (_user != null) {
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(_user!.uid) // Kullanıcı UID'si ile belgeye erişim
          .collection('wordLists')
          .add({
        'name': listName,
        'words': [],
      });
      if (mounted) {
        setState(() {
          wordLists.add(WordList(id: docRef.id, name: listName, words: []));
        });
      }
    } else {
      print('Error: user is not logged in');
    }
  }

  Future<void> _deleteWordList(String docId) async {
    if (_user != null) {
      await _firestore
          .collection('users')
          .doc(_user!.uid) // Kullanıcı UID'si ile belgeye erişim
          .collection('wordLists')
          .doc(docId)
          .delete();
      _loadWordLists();
    } else {
      print('Error: user is not logged in');
    }
  }

  // AppBar'ı güncelle - bilgi butonu ekle
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelime Listeleri', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey.shade800,
        elevation: 2,
        actions: [
          // Bilgi butonu ekle
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoCard,
            tooltip: 'Bilgi',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWordLists,
            tooltip: 'Listeleri Yenile',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber.shade700))
          : wordLists.isEmpty 
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ListView.builder(
                    itemCount: wordLists.length,
                    itemBuilder: (context, index) {
                      return _buildWordListCard(context, wordLists[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          String? newListName = await _showAddListDialog(context);
          if (newListName != null && newListName.isNotEmpty) {
            await _addWordList(newListName);
            _loadWordLists();
          }
        },
        backgroundColor: Colors.amber.shade700,
        label: Text('Yeni Liste', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.add, color: Colors.white),
        elevation: 4,
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
              Icons.featured_play_list_outlined,
              size: 60,
              color: Colors.amber.shade300,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Henüz kelime listeniz bulunmuyor',
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
              'Ekranın altındaki "Yeni Liste" butonuna tıklayarak kelime listesi oluşturabilirsiniz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              String? newListName = await _showAddListDialog(context);
              if (newListName != null && newListName.isNotEmpty) {
                await _addWordList(newListName);
                _loadWordLists();
              }
            },
            icon: Icon(Icons.add),
            label: Text('Yeni Liste Oluştur'),
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
  
  // Liste kartı widgeti
  Widget _buildWordListCard(BuildContext context, WordList wordList) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.amber.shade50],
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WordListDetailScreen(
                  wordList: wordList,
                  username: _user!.uid,
                ),
              ),
            ).then((_) => _loadWordLists());
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Sol taraf: ikon ve kelime sayısı
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, color: Colors.amber.shade700, size: 22),
                      SizedBox(height: 2),
                      Text(
                        '${wordList.words.length}',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
              
                // Orta: Başlık
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wordList.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        wordList.words.isEmpty 
                            ? 'Henüz kelime eklenmemiş'
                            : '${wordList.words.length} kelime',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              
                // Sağ: Düzenleme ve silme butonları
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => _showDeleteConfirmationDialog(context, wordList.id, wordList.name),
                  tooltip: 'Listeyi Sil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Silme onayı dialog'u
  Future<void> _showDeleteConfirmationDialog(BuildContext context, String docId, String listName) async {
    return showDialog(
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
                  'Listeyi Sil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                
                // İçerik
                Text(
                  '"$listName" listesini silmek istediğinize emin misiniz?',
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
                          _deleteWordList(docId);
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
        );
      },
    );
  }

  // Yeni liste oluşturma dialog'u
  Future<String?> _showAddListDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
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
                    Icons.playlist_add,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                
                // Başlık
                Text(
                  'Yeni Liste Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 20),
                
                // Liste ismi giriş alanı
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Liste İsmi',
                    hintText: 'Örn: İngilizce Fiiller',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(controller.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Ekle'),
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

  // Bilgilendirme kartı metodu
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
                    'Kelime Listeleri Hakkında',
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
                    title: 'Liste Oluşturma',
                    description: 'Sağ alt köşedeki "Yeni Liste" butonuna tıklayarak yeni kelime listesi oluşturabilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildInfoItem(
                    icon: Icons.tap_and_play,
                    title: 'Liste Açma',
                    description: 'Bir listeye tıklayarak içindeki kelimeleri görüntüleyebilir ve düzenleyebilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildInfoItem(
                    icon: Icons.delete_outline,
                    title: 'Liste Silme',
                    description: 'Bir listenin sağındaki çöp kutusu ikonuna tıklayarak listeyi silebilirsiniz.',
                  ),
                  SizedBox(height: 16),
                  
                  _buildInfoItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Metin Tarama',
                    description: 'Ana ekranda kamera simgesine tıklayarak İngilizce metinleri tarayabilir ve kelime listesi oluşturabilirsiniz.',
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
}