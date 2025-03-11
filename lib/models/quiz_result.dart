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
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Sonuçları', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue.shade200, Colors.blue.shade50],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Quiz Tamamlandı!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Doğru Cevaplar: $correctAnswers',
                style: TextStyle(fontSize: 18, color: Colors.green.shade800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Yanlış Cevaplar: $incorrectAnswers',
                style: TextStyle(fontSize: 18, color: Colors.red.shade800),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: words.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    child: ListTile(
                      leading: Icon(
                        answers[index] ? Icons.check_circle : Icons.cancel,
                        color: answers[index] ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        'Türkçe: ${words[index].meaning}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      subtitle: Text(
                        'İngilizce: ${words[index].word}',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}