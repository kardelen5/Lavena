import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../veri/modeller/gunluk_giris_modeli.dart';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';
import '../../cekirdek/yonlendirme/rota_isimleri.dart';

class KilitliNotlarEkrani extends StatefulWidget {
  const KilitliNotlarEkrani({super.key});

  @override
  State<KilitliNotlarEkrani> createState() => _KilitliNotlarEkraniState();
}

class _KilitliNotlarEkraniState extends State<KilitliNotlarEkrani> {
  int? _aktifKullaniciId;

  @override
  void initState() {
    super.initState();
    _aktifKullaniciyiGetir();
  }
  
  Future<void> _aktifKullaniciyiGetir() async {
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
        title: const Text(
          "Zaman Kapsülü",
          style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.w300, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0EAFC), Color(0xFFFDFCFE)],
          ),
        ),
        child: Consumer<GunlukGirisSaglayicisi>(
          builder: (context, saglayici, child) {
            final kilitliAnilar = saglayici.anilar.where((ani) {
              return ani.kullaniciId == _aktifKullaniciId && ani.kilitAcilmaTarihi != null;
            }).toList();

            if (kilitliAnilar.isEmpty) {
              return const Center(
                child: Text(
                  "Geleceğe henüz bir not bırakmadın...",
                  style: TextStyle(color: Colors.grey, fontSize: 16, letterSpacing: 1.2),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 30,
                childAspectRatio: 0.8,
              ),
              itemCount: kilitliAnilar.length,
              itemBuilder: (context, index) {
                final ani = kilitliAnilar[index];
                return _buildKilitliYildizIkonu(ani, context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildKilitliYildizIkonu(GunlukGirisModeli ani, BuildContext context) {
    bool kilitliMi = false;
    if (ani.kilitAcilmaTarihi != null) {
      final acilmaTarihi = DateTime.parse(ani.kilitAcilmaTarihi!);
      kilitliMi = acilmaTarihi.isAfter(DateTime.now());
    }

    final Color yildizRengi = Color(ani.arkaPlanKodu ?? 0xFF918EF4);

    return GestureDetector(
      onTap: () async {
        if (kilitliMi) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bu anının kilidi henüz açılmadı! (${ani.kilitAcilmaTarihi!.substring(0, 10)})'),
              backgroundColor: const Color(0xFF918EF4),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          String acilmaZamani = ani.kilitAcilmaTarihi!.substring(0, 10);
          if (!ani.metin.contains("Zaman Kapsülünden Çıkarıldı")) {
            ani.metin = "✨ [Zaman Kapsülünden Çıkarıldı - $acilmaZamani]\n\n${ani.metin}";
          }

          ani.kilitAcilmaTarihi = null;
          await Provider.of<GunlukGirisSaglayicisi>(context, listen: false).aniGuncelle(ani);

          if (context.mounted) {
            Navigator.pushNamed(context, RotaIsimleri.aniOkumaEkrani, arguments: ani);
          }
        }
      },
      onLongPress: () {
        _silmeOnayiGoster(context, ani);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'kilitli_ani_kart_${ani.id}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: yildizRengi.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 70,
                    color: yildizRengi,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      kilitliMi ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ani.kilitAcilmaTarihi!.substring(0, 10),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _silmeOnayiGoster(BuildContext context, GunlukGirisModeli ani) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Zaman Kapsülünü İptal Et"),
        content: const Text("Bu kilitli anıyı açılmadan tamamen silmek istediğine emin misin?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (ani.id != null) {
                await context.read<GunlukGirisSaglayicisi>().aniSil(ani.id!);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kilitli anı gökyüzünden silindi.'),
                      backgroundColor: Colors.deepPurple,
                    ),
                  );
                }
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}