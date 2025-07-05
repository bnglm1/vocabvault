import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabvault2/models/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocabvault2/screens/home_screen.dart';
import '../services/translation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false; // Başlangıçta false olarak değiştirdim
  final String _selectedLanguage = 'Türkçe';
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _checkNotificationPermission(); // İzin durumunu kontrol et
  }

  Future<void> _initializeNotifications() async {
    // Android için bildirim kanalı detayları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS için bildirim ayarları
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Tüm platformlar için ayarları birleştir
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Bildirimleri başlat
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında burası çalışır
        print('Notification clicked: ${response.payload}');
      },
    );
  }

  // İzin durumunu kontrol eden yeni metot
  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  // Bildirim izni isteyen yeni metot
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationsEnabled = status.isGranted;
    });

    if (status.isGranted) {
      _toggleNotifications(true);
    } else {
      _showPermissionDeniedDialog();
    }
  }

  // İzin reddedildiğinde gösterilecek dialog
  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Bildirim İzni Reddedildi',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Bildirimleri alabilmek için uygulama ayarlarından bildirim iznini etkinleştirmeniz gerekmektedir.',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              child: Text(
                'Kapat',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Ayarlara Git',
                style: TextStyle(color: Colors.amber.shade700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleNotifications(bool isEnabled) async {
    // İzin kontrolü yapıyoruz
    if (isEnabled) {
      // İzin durumunu kontrol et
      final status = await Permission.notification.status;
      
      // İzin yoksa, izin iste
      if (!status.isGranted) {
        await _requestNotificationPermission();
        return; // İzin isteği sonucuna göre _notificationsEnabled zaten güncelleniyor
      }
      
      // İzin varsa bildirimi göster
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Bildirimler Etkinleştirildi',
        'Bildirimler artık etkin.',
        platformChannelSpecifics,
      );
    } else {
      // Bildirimleri kapat
      await flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: TranslationService.translate('settings'),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? 'Ayarlar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        backgroundColor: Colors.grey.shade800,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAF8F0), Colors.grey.shade200],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          children: [
            _buildSettingsCategory('Görünüm Ayarları', Icons.palette_outlined),
            SizedBox(height: 8),
            _buildSettingCard(
              SwitchListTile(
                title: Text(
                  'Karanlık Tema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Aktif' : 'Kapalı',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: Colors.amber.shade700,
                activeTrackColor: Colors.amber.shade200,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade300,
                secondary: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            _buildSettingsCategory('Bildirim Ayarları', Icons.notifications_none),
            SizedBox(height: 8),
            _buildSettingCard(
              SwitchListTile(
                title: Text(
                  'Bildirimler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  _notificationsEnabled ? 'Bildirimler açık' : 'Bildirimler kapalı',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  if (value && !_notificationsEnabled) {
                    _requestNotificationPermission();
                  } else {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _toggleNotifications(value);
                  }
                },
                activeColor: Colors.amber.shade700,
                activeTrackColor: Colors.amber.shade200,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade300,
                secondary: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            FutureBuilder<String>(
              future: TranslationService.translate('language_settings'),
              builder: (context, snapshot) {
                return _buildSettingsCategory(
                  snapshot.data ?? 'Dil Ayarları', 
                  Icons.language
                );
              },
            ),
            SizedBox(height: 8),
            _buildSettingCard(
              ListTile(
                title: FutureBuilder<String>(
                  future: TranslationService.translate('language'),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Dil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    );
                  },
                ),
                subtitle: Text(
                  TranslationService.getLanguageName(),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.translate, color: Colors.amber.shade700),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                onTap: () => _showLanguageDialog(context),
              ),
            ),
            
            SizedBox(height: 24),
            _buildSettingsCategory('Uygulama Bilgileri', Icons.info_outline),
            SizedBox(height: 8),
            _buildSettingCard(
              ListTile(
                title: Text(
                  'Hakkında',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'VocabVault 2.0',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info, color: Colors.amber.shade700),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                onTap: () {
                  // Hakkında sayfasını aç
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AI
  Widget _buildSettingsCategory(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.amber.shade700),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Ayarlar kartı widgeti
  Widget _buildSettingCard(Widget child) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.yellow.shade50],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) async {
    final String turkish = await TranslationService.translate('turkish');
    final String english = await TranslationService.translate('english');
    final String currentLang = TranslationService.getCurrentLanguage();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: FutureBuilder<String>(
            future: TranslationService.translate('language'),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Dil',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context, 
                'tr', 
                turkish,
                currentLang == 'tr'
              ),
              SizedBox(height: 8),
              _buildLanguageOption(
                context, 
                'en', 
                english,
                currentLang == 'en'
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String code, String name, bool isSelected) {
    return InkWell(
      onTap: () async {
        await TranslationService.changeLanguage(code);
        Navigator.of(context).pop();
        
        // Ayarları yenilemek için ekranı yeniden yükleyelim
        setState(() {});
        
        // Önemli: Değişiklik ana uygulamaya yansısın diye anasayfaya yönlendirelim
        if (code != TranslationService.getCurrentLanguage()) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.amber.shade600 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.amber.shade600 : Colors.grey.shade500,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}