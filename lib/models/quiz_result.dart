import 'package:flutter/material.dart';
import '../models/word.dart';

class QuizResultScreen extends StatelessWidget {
  final int correctAnswers;
  final int incorrectAnswers;
  final List<Word> words;
  final List<bool> answers;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.words,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = correctAnswers / (correctAnswers + incorrectAnswers) * 100;
    final String grade = _determineGrade(percentage);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Sonuçları', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey.shade800, // Amber'dan mavi renge değiştirildi
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(  // SafeArea ekleyerek güvenli alan içinde kalmasını sağlayın
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.amber.shade50, Colors.grey.shade100],
            ),
          ),
          child: Column(
            children: [
              // Sonuç özeti kartı
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.amber.shade50],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Sonuçlarınız',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Yüzde daire göstergesi
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.amber.shade300, Colors.amber.shade700],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                Text(
                                  grade,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Doğru ve yanlış sayıları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResultItem(
                          icon: Icons.check_circle,
                          label: 'Doğru',
                          value: '$correctAnswers',
                          color: Colors.green.shade700,
                          bgColor: Colors.green.shade50,
                        ),
                        _buildResultItem(
                          icon: Icons.cancel,
                          label: 'Yanlış',
                          value: '$incorrectAnswers',
                          color: Colors.red.shade700,
                          bgColor: Colors.red.shade50,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Konu başlığı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Cevap Detayları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Soru ve cevap listesi
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: answers[index] ? Colors.green.shade200 : Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      color: answers[index] ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: answers[index] 
                                        ? Colors.green.shade100 
                                        : Colors.red.shade100,
                                  ),
                                  child: Icon(
                                    answers[index] ? Icons.check : Icons.close,
                                    color: answers[index] 
                                        ? Colors.green.shade700 
                                        : Colors.red.shade700,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Soru ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: answers[index] 
                                        ? Colors.green.shade700 
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 16),
                            _buildWordItem('İngilizce', words[index].word),
                            SizedBox(height: 8),
                            _buildWordItem('Türkçe', words[index].meaning),
                            if (words[index].exampleSentence.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: _buildWordItem('Örnek Cümle', words[index].exampleSentence),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Ana sayfaya dönüş butonu - margin'i değiştirerek yukarı taşıyın
              Container(
                // 16 yerine alt kısımda 32 piksel boşluk bırak
                margin: EdgeInsets.fromLTRB(16, 16, 16, 32), 
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Tüm ekranları temizleyip ana sayfaya dönme işlemi
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    
                    // Alternatif olarak aşağıdaki yöntemlerden birini de kullanabilirsiniz:
                    // Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    // Navigator.pushReplacementNamed(context, '/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Ana Sayfaya Dön',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWordItem(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _determineGrade(double percentage) {
    if (percentage >= 90) return "Mükemmel";
    if (percentage >= 80) return "Çok İyi";
    if (percentage >= 70) return "İyi";
    if (percentage >= 60) return "Orta";
    return "Geliştirilmeli";
  }
}