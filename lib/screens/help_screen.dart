import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yardım'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text('Uygulama Hakkında'),
            subtitle: Text('Bu uygulama, kelime öğrenme sürecinizi kolaylaştırmak için tasarlanmıştır.'),
            leading: Icon(Icons.info, color: Colors.blue.shade700),
          ),
          ListTile(
            title: Text('Nasıl Kullanılır?'),
            subtitle: Text('Uygulamanın nasıl kullanılacağı hakkında bilgi edinin.'),
            leading: Icon(Icons.help, color: Colors.blue.shade700),
          ),
          ListTile(
            title: Text('Sıkça Sorulan Sorular'),
            subtitle: Text('Sıkça sorulan soruların cevaplarını bulun.'),
            leading: Icon(Icons.question_answer, color: Colors.blue.shade700),
          ),
          ListTile(
            title: Text('İletişim'),
            subtitle: Text('Bizimle iletişime geçin.'),
            leading: Icon(Icons.contact_mail, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sıkça Sorulan Sorular'),
      ),
      body: Center(
        child: Text('Sıkça Sorulan Sorular Sayfası'),
      ),
    );
  }
}