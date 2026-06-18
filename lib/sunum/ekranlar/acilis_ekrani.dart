import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cekirdek/yonlendirme/rota_isimleri.dart';
import '../../veri/depolar/kullanici_repository.dart';

class AcilisEkrani extends StatefulWidget {
  const AcilisEkrani({super.key});

  @override
  State<AcilisEkrani> createState() => _AcilisEkraniState();
}

class _AcilisEkraniState extends State<AcilisEkrani> with TickerProviderStateMixin {
  late AnimationController _logoKontrolcusu;

  final TextEditingController _adController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final KullaniciRepository _kullaniciRepo = KullaniciRepository();

  bool _beniHatirla = false;
  bool _sifreGizli = true;

  @override
  void initState() {
    super.initState();
    _oturumKontrol();
    _logoKontrolcusu = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoKontrolcusu.dispose();
    _adController.dispose();
    _sifreController.dispose();
    _mailController.dispose();
    super.dispose();
  }

  Future<void> _oturumKontrol() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('oturumAcik') ?? false) {
      if (mounted) Navigator.pushReplacementNamed(context, RotaIsimleri.anaEkran);
    }
  }

  bool _emailGecerliMi(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  bool _karakterlerGecerliMi(String text) {
    return RegExp(r'^[a-zA-Z0-9_ğüşıöçĞÜŞİÖÇ]+$').hasMatch(text);
  }

  void _mesajGoster(String mesaj, {bool hata = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mesaj,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: hata ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _authSheet(bool girisModu) {
    _adController.clear();
    _sifreController.clear();
    _mailController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(30, 20, 30, MediaQuery.of(context).viewInsets.bottom + 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(girisModu ? "Giriş Yap" : "Kayıt Ol",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
              const SizedBox(height: 25),

              _buildTextField(hint: "Kullanıcı Adı", icon: Icons.person_outline, controller: _adController),
              if (!girisModu) _buildTextField(hint: "E-posta", icon: Icons.mail_outline, controller: _mailController),

              // Şifre Alanı
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: const Color(0xFFF4F5F9), borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: _sifreController,
                  obscureText: _sifreGizli,
                  decoration: InputDecoration(
                    hintText: "Şifre",
                    icon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_sifreGizli ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setModalState(() => _sifreGizli = !_sifreGizli),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              if (girisModu) Row(
                children: [
                  Checkbox(
                    value: _beniHatirla,
                    activeColor: const Color(0xFF918EF4),
                    onChanged: (val) => setModalState(() => _beniHatirla = val!),
                  ),
                  const Text("Beni Hatırla", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF918EF4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    String ad = _adController.text.trim();
                    String sifre = _sifreController.text.trim();
                    String mail = _mailController.text.trim();

                    if (ad.isEmpty || sifre.isEmpty || (!girisModu && mail.isEmpty)) {
                      _mesajGoster("Lütfen tüm alanları doldurun!");
                      return;
                    }

                    try {
                      if (girisModu) {
                        final kullanici = await _kullaniciRepo.girisYap(ad, sifre);

                        if (kullanici != null) {
                          final prefs = await SharedPreferences.getInstance();

                          await prefs.setInt('aktifKullaniciId', kullanici.id!);
                          print("Oturum Açıldı! Aktif Kullanıcı ID Hafızaya Yazıldı: ${kullanici.id}");

                          if (_beniHatirla) {
                            await prefs.setBool('oturumAcik', true);
                          } else {
                            await prefs.setBool('oturumAcik', false);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, RotaIsimleri.anaEkran); // Ana ekrana geç
                          }
                        } else {
                          _mesajGoster("Hatalı kullanıcı adı veya şifre!");
                        }
                      } else {

                        if (ad.length < 3 || !_karakterlerGecerliMi(ad)) {
                          _mesajGoster("Geçersiz kullanıcı adı! (En az 3 karakter, boşluksuz)");
                          return;
                        }
                        if (!_emailGecerliMi(mail)) {
                          _mesajGoster("Lütfen geçerli bir e-posta girin!");
                          return;
                        }
                        if (sifre.length < 6) {
                          _mesajGoster("Şifre en az 6 karakter olmalıdır!");
                          return;
                        }

                        bool basarili = await _kullaniciRepo.kayitOl(ad, mail, sifre);

                        if (basarili) {
                          if (mounted) {
                            Navigator.pop(context);
                            _mesajGoster("Kayıt başarılı! Şimdi giriş yapabilirsin.", hata: false);
                          }
                        } else {
                          _mesajGoster("Bu kullanıcı adı veya e-posta adresi zaten kullanımda!");
                        }
                      }
                    } catch (e) {
                      print("Giriş/Kayıt Hatası: $e");
                      _mesajGoster("Bir hata oluştu, lütfen tekrar dene.");
                    }
                  },
                  child: Text(girisModu ? "GİRİŞ" : "KAYIT OL", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0EAFC), Color(0xFFFDFCFE)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF918EF4)),
            const SizedBox(height: 20),
            const Text('L A V E N A', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w200, letterSpacing: 8, color: Color(0xFF4A4A4A))),
            const SizedBox(height: 60),
            _buildMainButton("GİRİŞ YAP", const Color(0xFF918EF4), Colors.white, () => _authSheet(true)),
            const SizedBox(height: 15),
            _buildMainButton("KAYIT OL", Colors.white, const Color(0xFF918EF4), () => _authSheet(false), border: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(String text, Color bg, Color txt, VoidCallback onTap, {bool border = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250, padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(40),
          border: border ? Border.all(color: const Color(0xFF918EF4), width: 1.5) : null,
          boxShadow: bg != Colors.white ? [BoxShadow(color: const Color(0xFF918EF4).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))] : null,
        ),
        child: Center(child: Text(text, style: TextStyle(color: txt, fontWeight: FontWeight.bold, letterSpacing: 2))),
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, required TextEditingController controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: const Color(0xFFF4F5F9), borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hint, icon: Icon(icon, size: 20, color: Colors.blueGrey.shade300), border: InputBorder.none),
      ),
    );
  }
}