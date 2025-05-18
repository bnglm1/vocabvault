import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/dictionary_service.dart';
import '../models/dictionary_entry.dart';

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryService _dictionaryService = DictionaryService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = false;
  bool _hasShownInfo = false;
  String? _errorMessage;
  List<DictionaryEntry> _searchResults = [];

  // Çeviri durumu için yeni durum değişkeni ekleyin
  bool _isTranslating = false;

  // Öneriler için değişkenler
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Ekran yüklendikten sonra bilgilendirme göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownInfo) {
        _showInfoDialog();
        _hasShownInfo = true;
      }
    });
    
    // Arama metin kontrolcüsü için listener ekle
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChange);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  // Focus değişimini takip et
  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }
  
  // Arama metni değiştiğinde çağrılır
  void _onSearchChanged() {
    // Debounce tekniği - kullanıcı yazımı tamamlayana kadar bekle
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      if (_searchController.text.length > 1) {
        _fetchSuggestions();
      } else {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    });
  }
  
  // API'den öneriler getir
  Future<void> _fetchSuggestions() async {
    if (!mounted) return; // Erken kontrol ekleyin
    
    final query = _searchController.text.trim();
    if (query.length < 2) return;
    
    try {
      final suggestions = await _dictionaryService.getSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      print('Öneri getirme hatası: $e');
    }
  }
  
  // Önerilen kelimeyi seç
  void _selectSuggestion(String word) {
    _searchController.text = word;
    setState(() {
      _showSuggestions = false;
    });
    _searchWord();
  }
  
  // Bilgilendirme kartı diyaloğu
  Future<void> _showInfoDialog() async {
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
                    Icons.menu_book,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                
                Text(
                  'Sözlük Kullanımı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                SizedBox(height: 20),
                
                // Bilgi öğeleri
                _buildInfoItem(
                  icon: Icons.search,
                  title: 'Kelime Arama',
                  description: 'İngilizce bir kelime yazıp aratarak detaylı bilgisine ulaşabilirsiniz.',
                ),
                SizedBox(height: 16),
                
                _buildInfoItem(
                  icon: Icons.volume_up,
                  title: 'Telaffuz Dinleme',
                  description: 'Kelimenin yanındaki ses ikonuna tıklayarak telaffuzunu dinleyebilirsiniz.',
                ),
                SizedBox(height: 16),
                
                _buildInfoItem(
                  icon: Icons.format_quote,
                  title: 'Örnekler',
                  description: 'Kelimenin kullanıldığı örnek cümleler, eş ve zıt anlamlıları görebilirsiniz.',
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

  Future<void> _searchWord() async {
    final word = _searchController.text.trim();
    if (word.isEmpty) return;

    if (!mounted) return; // Widget hala var mı kontrol et
  
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final results = await _dictionaryService.searchWord(word);
      if (mounted) { // Widget hala ekranda mı kontrol et
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { // Widget hala ekranda mı kontrol et
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    if (audioUrl.isNotEmpty) {
      await _audioPlayer.play(UrlSource(audioUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sözlük', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey.shade800,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoDialog,
            tooltip: 'Bilgi',
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
        child: Column(
          children: [
            // Arama alanı
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'İngilizce kelime ara...',
                        prefixIcon: Icon(Icons.search, color: Colors.amber.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey.shade500),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _suggestions = [];
                                  _showSuggestions = false;
                                });
                              },
                            )
                          : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.amber.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.amber.shade200),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        setState(() {
                          _showSuggestions = false;
                        });
                        _searchWord();
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showSuggestions = false;
                      });
                      _searchWord();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Icon(Icons.search),
                  ),
                ],
              ),
            ),
            
            // Öneri listesi
            _buildSuggestionsList(),
            
            // Sonuçlar alanı
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Kelime aranıyor ve çevriliyor...',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Bu işlem biraz zaman alabilir',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorMessage()
                      : _searchResults.isEmpty
                          ? _buildEmptyState()
                          : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40), // Üstte boşluk ekle
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book,
                  size: 60,
                  color: Colors.amber.shade300,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Kelime Ara',
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
                  'İngilizce bir kelime aratarak anlamını, örnekleri ve daha fazlasını öğrenin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: 40), // Altta boşluk ekle
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40), // Üstte boşluk ekle
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red.shade300,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Bir Hata Oluştu',
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
                  _errorMessage?.contains('Kelime bulunamadı') == true
                      ? 'Aradığınız kelime bulunamadı. Yazımınızı kontrol edip tekrar deneyin.'
                      : 'Arama sırasında bir hata oluştu. Lütfen tekrar deneyin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _searchWord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Tekrar Dene'),
              ),
              SizedBox(height: 40), // Altta boşluk ekle
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _searchResults.map((entry) {
          return _buildDictionaryEntry(entry);
        }).toList(),
      ),
    );
  }

  Widget _buildDictionaryEntry(DictionaryEntry entry) {
    // Telaffuz ses URL'i bul
    String? audioUrl;
    for (var phonetic in entry.phonetics) {
      if (phonetic.audio != null && phonetic.audio!.isNotEmpty) {
        audioUrl = phonetic.audio;
        break;
      }
    }
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.amber.shade50],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kelime başlığı ve ses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.word,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  if (audioUrl != null && audioUrl.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.volume_up, color: Colors.amber.shade700),
                      onPressed: () => _playAudio(audioUrl!),
                      tooltip: 'Telaffuzu dinle',
                    ),
                ],
              ),

              // Not alanı - Eğer not varsa göster
              if (entry.note != null && entry.note!.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 4, bottom: 10),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, 
                          size: 16, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.note!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Fonetik
              if (entry.phonetic != null && entry.phonetic!.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    entry.phonetic!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Anlamlar
              ...entry.meanings.map((meaning) => _buildMeaning(meaning)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeaning(Meaning meaning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.amber.shade200),
        
        // Sözcük türü (isim, fiil vb.)
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            meaning.partOfSpeech,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ),
        
        // Tanımlar
        ...meaning.definitions.asMap().entries.map((entry) {
          int index = entry.key;
          Definition def = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanım numarası ve metin
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8, top: 2),
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        def.definition,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),

                // Örnek
                if (def.example != null && def.example!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İngilizce örnek
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.format_quote,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                def.example!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Türkçe örnek
                        if (def.translatedExample != null && def.translatedExample!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.translate,
                                    size: 14,
                                    color: Colors.amber.shade600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    def.translatedExample!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),

        // Eş anlamlılar
        if (meaning.synonyms != null && meaning.synonyms!.isNotEmpty)
          _buildWordChips('Eş Anlamlılar', meaning.synonyms!, Colors.green.shade100, Colors.green.shade700),
          
        // Zıt anlamlılar
        if (meaning.antonyms != null && meaning.antonyms!.isNotEmpty)
          _buildWordChips('Zıt Anlamlılar', meaning.antonyms!, Colors.red.shade100, Colors.red.shade700),

        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildWordChips(String title, List<String> words, Color bgColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: words.map((word) {
            return InkWell(
              onTap: () {
                // Tıklanan kelimeyi arama kutusuna yaz
                _searchController.text = word;
                
                // Widget hala ekranda mı kontrol et
                if (!mounted) return;
                
                // Arama işlemini başlat
                _searchWord();
                
                // Sayfayı en üste kaydır
                if (mounted) { // Ekstra kontrol
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return; // İlave kontrol
                    Scrollable.ensureVisible(context, 
                      duration: Duration(milliseconds: 300), 
                      curve: Curves.easeInOut);
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.search,
                            size: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Öneri listesini oluştur
  Widget _buildSuggestionsList() {
    // Önerilerin listesinin görünür olmaması durumunda hiçbir şey gösterme
    if (!_showSuggestions || _suggestions.isEmpty) {
      return SizedBox.shrink();
    }

    // Maksimum öneri sayısını sınırla (performans için)
    final limitedSuggestions = _suggestions.take(5).toList();
    
    // Overlay ile gösterme yerine, fixed height Container içinde göster
    return Material(
      elevation: 4,
      shadowColor: Colors.amber.shade200.withOpacity(0.5),
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 200,
          minHeight: 0,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: limitedSuggestions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.amber.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = limitedSuggestions[index];
                    return InkWell(
                      onTap: () => _selectSuggestion(suggestion),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.search, 
                              color: Colors.amber.shade600, 
                              size: 18
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: TextStyle(color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
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