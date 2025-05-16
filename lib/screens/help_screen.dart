import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yardım',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey.shade800, // Mavi -> Koyu Gri
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFFAF8F0), Colors.grey.shade200],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildHelpCard(
              title: 'Uygulama Hakkında',
              subtitle:
                  'Bu uygulama, kelime öğrenme sürecinizi kolaylaştırmak için tasarlanmıştır.',
              icon: Icons.info,
              context: context,
              onTap: () {
                // Uygulama hakkında detaylı bilgi sayfasına yönlendirme yapılabilir
              },
            ),
            SizedBox(height: 16),
            _buildHelpCard(
              title: 'Nasıl Kullanılır?',
              subtitle: 'Uygulamanın nasıl kullanılacağı hakkında bilgi edinin.',
              icon: Icons.help_outline,
              context: context,
              onTap: () {
                // Kullanım kılavuzu sayfasına yönlendirme yapılabilir
              },
            ),
            SizedBox(height: 16),
            _buildHelpCard(
              title: 'Sıkça Sorulan Sorular',
              subtitle: 'Sıkça sorulan soruların cevaplarını bulun.',
              icon: Icons.question_answer,
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQScreen()),
                );
              },
            ),
            SizedBox(height: 16),
            _buildHelpCard(
              title: 'İletişim',
              subtitle: 'Bizimle iletişime geçin.',
              icon: Icons.contact_mail,
              context: context,
              onTap: () {
                _sendEmail(context); // E-posta gönderme fonksiyonunu çağır
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey.shade800,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.amber.shade700,
              size: 30,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.amber.shade700,
            size: 16,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    // Konu satırını doğru şekilde URL kodlaması ile kodla
    final String encodedSubject = Uri.encodeComponent('VocabVault Uygulaması Hakkında');
    final String encodedBody = Uri.encodeComponent('Merhaba,\n\n');
    
    // Manuel olarak URL oluşturuyoruz
    final Uri emailUri = Uri.parse(
      'mailto:vavocab@gmail.com?subject=$encodedSubject&body=$encodedBody'
    );
 
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // E-posta uygulaması açılamadıysa bir hata diyalogu göster
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'E-posta Uygulaması Bulunamadı',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Cihazınızda yapılandırılmış bir e-posta uygulaması bulunamadı. Lütfen bir e-posta uygulaması kurun ve tekrar deneyin.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              actions: [
                TextButton(
                  child: Text(
                    'Tamam',
                    style: TextStyle(color: Colors.amber.shade700),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Hata kodu değişmedi
      print('E-posta gönderirken hata oluştu: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-posta gönderilirken bir sorun oluştu.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sıkça Sorulan Sorular',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey.shade800,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFFAF8F0), Colors.grey.shade200],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildFAQCard(
              question: 'Kelime listesi nasıl oluşturabilirim?',
              answer:
                  'Ana ekrandan "Yeni Liste" butonuna tıklayarak istediğiniz isimle bir kelime listesi oluşturabilirsiniz.',
              context: context,
            ),
            SizedBox(height: 12),
            _buildFAQCard(
              question: 'Liste içine kelime nasıl eklerim?',
              answer:
                  'Kelime listesine tıkladıktan sonra açılan ekranda sağ alt köşedeki "+" butonuna tıklayarak yeni kelime ekleyebilirsiniz.',
              context: context,
            ),
            SizedBox(height: 12),
            _buildFAQCard(
              question: 'Kelimeleri nasıl test edebilirim?',
              answer:
                  'Her kelime listesinde "Test Et" butonuna tıklayarak çeşitli test modlarında kendinizi sınayabilirsiniz.',
              context: context,
            ),
            SizedBox(height: 12),
            _buildFAQCard(
              question: 'İnternet bağlantısı olmadan kullanabilir miyim?',
              answer:
                  'Evet, uygulamanın temel özellikleri çevrimdışı olarak da çalışır. Ancak kelime çevirisi gibi bazı özellikler internet bağlantısı gerektirebilir.',
              context: context,
            ),
            SizedBox(height: 12),
            _buildFAQCard(
              question: 'Kelime listelerimi nasıl paylaşabilirim?',
              answer:
                  'Kelime listesi sayfasında üç nokta menüsüne tıklayarak "Paylaş" seçeneğini kullanabilirsiniz.',
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard({
    required String question,
    required String answer,
    required BuildContext context,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: EdgeInsets.all(16),
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          iconColor: Colors.amber.shade700,
          collapsedIconColor: Colors.amber.shade700,
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}