import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';

class ZamanKapsuluListesiEkrani extends StatefulWidget {
  const ZamanKapsuluListesiEkrani({super.key});

  @override
  State<ZamanKapsuluListesiEkrani> createState() => _ZamanKapsuluListesiEkraniState();
}

class _ZamanKapsuluListesiEkraniState extends State<ZamanKapsuluListesiEkrani> {
  int? _aktifKullaniciId;

  @override
  void initState() {
    super.initState();
    _kullaniciIdYukle();
  }

  Future<void> _kullaniciIdYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aktifKullaniciId = prefs.getInt('aktifKullaniciId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFE),
      appBar: AppBar(
        title: const Text('Zaman Kapsülleri', style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF918EF4)),
      ),
      body: Consumer<GunlukGirisSaglayicisi>(
        builder: (context, saglayici, child) {
          final kilitliAnilar = saglayici.anilar.where((ani) {
            bool kilitliMi = false;
            if (ani.kilitAcilmaTarihi != null) {
              final acilmaTarihi = DateTime.parse(ani.kilitAcilmaTarihi!);
              kilitliMi = acilmaTarihi.isAfter(DateTime.now());
            }
            return ani.kullaniciId == _aktifKullaniciId && kilitliMi;
          }).toList();

          if (kilitliAnilar.isEmpty) {
            return const Center(
              child: Text('Geleceğe kilitlenmiş henüz bir notunuz yok. ✨', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: kilitliAnilar.length,
            itemBuilder: (context, index) {
              final ani = kilitliAnilar[index];
              final String acilisTarihiStr = ani.kilitAcilmaTarihi!.length >= 10
                  ? ani.kilitAcilmaTarihi!.substring(0, 10)
                  : ani.kilitAcilmaTarihi!;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: ListTile(
                  leading: const Icon(Icons.lock_clock_rounded, color: Color(0xFF918EF4)),
                  title: Text("Açılış: $acilisTarihiStr", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Bu kapsül henüz kilitli... 🔒', style: TextStyle(fontStyle: FontStyle.italic)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Bu kapsülün kilidi $acilisTarihiStr tarihinde açılacak!"),
                        backgroundColor: const Color(0xFF918EF4),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}