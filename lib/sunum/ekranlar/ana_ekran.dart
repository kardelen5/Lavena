import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../veri/modeller/gunluk_giris_modeli.dart';
import '../../cekirdek/yonlendirme/rota_isimleri.dart';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';
import '../durum_yonetimi/plan_saglayicisi.dart';
import 'kilitli_notlar_ekrani.dart';
import 'harita_ekrani.dart';
import 'galeri_ekrani.dart';
import 'haftalik_ozet_ekrani.dart';
import 'ayarlar_ekrani.dart';
import 'takvim_ekrani.dart';
import 'vision_board_ekrani.dart';
import 'aliskanlik_ajanda_ekrani.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int? _aktifKullaniciId;

  final TextEditingController _aramaKontrolcusu = TextEditingController();
  String _aramaMetni = "";

  @override
  void dispose() {
    _aramaKontrolcusu.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final int? aktifKullaniciId = prefs.getInt('aktifKullaniciId');

      if (mounted) {
        setState(() {
          _aktifKullaniciId = aktifKullaniciId;
        });
      }

      if (aktifKullaniciId != null && mounted) {
        Provider.of<GunlukGirisSaglayicisi>(context, listen: false).anilariYukle(aktifKullaniciId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFE),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0EAFC), Color(0xFFFDFCFE)],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),

            SliverToBoxAdapter(child: _buildZamanKapsuluKarti()),
            SliverToBoxAdapter(child: _buildPlanHatirlaticiKarti()),
            SliverToBoxAdapter(child: _buildHatirlaticiKarti()),
            SliverToBoxAdapter(child: _buildAramaCubugu()),

            Consumer<GunlukGirisSaglayicisi>(
              builder: (context, saglayici, child) {
                final acikAnilar = saglayici.anilar.where((ani) {
                  bool kilitliMi = false;
                  if (ani.kilitAcilmaTarihi != null) {
                    final acilmaTarihi = DateTime.parse(ani.kilitAcilmaTarihi!);
                    kilitliMi = acilmaTarihi.isAfter(DateTime.now());
                  }

                  bool sartlariSagliyor = (ani.kullaniciId == _aktifKullaniciId && !kilitliMi);

                  if (_aramaMetni.isNotEmpty) {
                    String aranan = _aramaMetni.toLowerCase();
                    String gorunurTarih = ani.tarih.length >= 10 ? ani.tarih.substring(5, 10).replaceAll('-', '/') : ani.tarih;
                    bool gorunurTarihIceriyor = gorunurTarih.contains(aranan);
                    bool metinIceriyor = ani.metin.toLowerCase().contains(aranan);
                    bool mekanIceriyor = ani.mekanIsmi != null && ani.mekanIsmi!.toLowerCase().contains(aranan);
                    bool orjinalTarihIceriyor = ani.tarih.contains(aranan);

                    if (!(gorunurTarihIceriyor || metinIceriyor || mekanIceriyor || orjinalTarihIceriyor)) {
                      return false;
                    }
                  }

                  return sartlariSagliyor;
                }).toList();

                if (acikAnilar.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _aramaMetni.isNotEmpty
                            ? 'Gökyüzünde bu aramaya uygun yıldız bulunamadı...'
                            : 'Gökyüzü şu an boş, bir yıldız ekle...',
                        style: const TextStyle(color: Colors.grey, letterSpacing: 1.2),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 30,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final ani = acikAnilar[index];
                        return _buildYildizIkonu(ani, context);
                      },
                      childCount: acikAnilar.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,

      leading: IconButton(
        icon: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF918EF4), size: 26),
        tooltip: 'Vision Board',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VisionBoardEkran()),
          );
        },
      ),

      title: const Text(
        'L A V E N A',
        style: TextStyle(
          color: Color(0xFF4A4A4A),
          fontWeight: FontWeight.w300,
          letterSpacing: 8,
        ),
      ),

      actions: [
        IconButton(
          icon: const Icon(
            Icons.insights_rounded,
            color: Color(0xFF918EF4),
            size: 28,
          ),
          tooltip: 'Haftalık Analiz',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HaftalikOzetEkrani())),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildAramaCubugu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 5, 25, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF918EF4).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: const Color(0xFF918EF4).withOpacity(0.3), width: 1.5),
      ),
      child: TextField(
        controller: _aramaKontrolcusu,
        style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 15),
        decoration: InputDecoration(
          hintText: "Tarih, mekan veya kelime ara...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, letterSpacing: 0.5),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF918EF4)),
          suffixIcon: _aramaMetni.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
            onPressed: () {
              _aramaKontrolcusu.clear();
              setState(() { _aramaMetni = ""; });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (val) {
          setState(() {
            _aramaMetni = val;
          });
        },
      ),
    );
  }

  Widget _buildPlanHatirlaticiKarti() {
    if (_aktifKullaniciId == null) return const SizedBox.shrink();

    return Consumer<PlanSaglayicisi>(
      builder: (context, planSaglayicisi, child) {
        if (planSaglayicisi.yukleniyor) return const SizedBox.shrink();

        String bugun = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

        final bugununPlanlari = planSaglayicisi.getGunlukPlanlar(bugun);
        int planSayisi = bugununPlanlari.length;

        String kartBasligi = planSayisi > 0 ? " Plan Hatırlatıcısı 🔔" : "Zaman Çizelgesi Sakin ✨";
        String kartIcerigi = planSayisi > 0
            ? "Bugün ilgilenmen gereken $planSayisi planın var! Detayları görmek için takvime göz atabilirsin."
            : "Bugün için planlanmış bir akış yok. Zihnini dinlendirebilir veya yeni hedefler ekleyebilirsin.";
        IconData kartIkonu = planSayisi > 0 ? Icons.bolt_rounded : Icons.wb_sunny_rounded;

        return Container(
          margin: const EdgeInsets.fromLTRB(25, 0, 25, 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A93CB), Color(0xFF8176AF), Color(0xFF918EF4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: const Color(0xFF8176AF).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(kartIkonu, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kartBasligi, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(kartIcerigi, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.3, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZamanKapsuluKarti() {
    return Consumer<GunlukGirisSaglayicisi>(
        builder: (context, saglayici, child) {
          final kilitliAnilar = saglayici.anilar.where((ani) => ani.kullaniciId == _aktifKullaniciId && ani.kilitAcilmaTarihi != null).toList();

          int hazirOlanlar = 0;
          int bekleyenler = 0;

          for (var ani in kilitliAnilar) {
            final acilmaTarihi = DateTime.parse(ani.kilitAcilmaTarihi!);
            if (acilmaTarihi.isAfter(DateTime.now())) {
              bekleyenler++;
            } else {
              hazirOlanlar++;
            }
          }

          String altMetin;
          IconData kartIkonu;
          Color ikonRengi = Colors.white;

          if (hazirOlanlar > 0) {
            altMetin = "Zamanı gelen $hazirOlanlar anın var! Aç ve gör ✨";
            if (bekleyenler > 0) altMetin += "\n(Geleceği bekleyen $bekleyenler not daha var)";
            kartIkonu = Icons.lock_open_rounded;
            ikonRengi = const Color(0xFFFFD700);
          } else if (bekleyenler > 0) {
            altMetin = "Gelecekte açılmayı bekleyen $bekleyenler anın var.";
            kartIkonu = Icons.lock_clock_rounded;
          } else {
            altMetin = "Gelecekteki sana bir not bırak...";
            kartIkonu = Icons.lock_outline_rounded;
          }

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KilitliNotlarEkrani())),
            child: Container(
              margin: const EdgeInsets.fromLTRB(25, 0, 25, 15),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF918EF4), Color(0xFFB5A8F9)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFF918EF4).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                    child: Icon(kartIkonu, color: ikonRengi, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Zaman Kapsülü", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(altMetin, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 18),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildHatirlaticiKarti() {
    return Consumer<GunlukGirisSaglayicisi>(
      builder: (context, saglayici, child) {
        final birHaftaOnce = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);
        GunlukGirisModeli? eskiAni;
        try {
          eskiAni = saglayici.anilar.firstWhere(
                  (ani) => ani.kullaniciId == _aktifKullaniciId && ani.tarih.startsWith(birHaftaOnce)
          );
        } catch (_) {
          eskiAni = null;
        }

        if (eskiAni == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, RotaIsimleri.aniOkumaEkrani, arguments: eskiAni),
          child: Container(
            margin: const EdgeInsets.fromLTRB(25, 0, 25, 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF5F7), Color(0xFFFCE4EC)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEAAFC8).withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Text("🌸", style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          "1 Hafta Önce Bugün",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9E5C6C),
                            letterSpacing: 0.5,
                            fontSize: 14,
                          )
                      ),
                      const SizedBox(height: 4),
                      Text(
                          eskiAni.metin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8D737A),
                          )
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9E5C6C), size: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYildizIkonu(GunlukGirisModeli ani, BuildContext context) {
    final Color yildizRengi = ani.arkaPlanKodu != null ? Color(ani.arkaPlanKodu!) : const Color(0xFF918EF4);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RotaIsimleri.aniOkumaEkrani, arguments: ani),
      onLongPress: () => _silmeOnayiGoster(context, ani),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'ani_kart_${ani.id}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF918EF4).withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF918EF4).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                Icons.star_rounded,
                size: 65,
                color: yildizRengi,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ani.tarih.length >= 10 ? ani.tarih.substring(5, 10).replaceAll('-', '/') : ani.tarih,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
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
        title: const Text("Yıldızı Kaydır"),
        content: const Text("Bu anıyı gökyüzünden silmek istediğine emin misin?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              if (ani.id != null) {
                await context.read<GunlukGirisSaglayicisi>().aniSil(ani.id!);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yıldız gökyüzünden kaydı...'), backgroundColor: Colors.deepPurple));
                }
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return SpeedDial(
      icon: Icons.add_rounded,
      activeIcon: Icons.close_rounded,
      backgroundColor: const Color(0xFF918EF4),
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
      spacing: 15,

      direction: SpeedDialDirection.up,
      switchLabelPosition: true,

      children: [
        SpeedDialChild(
          child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF918EF4)),
          backgroundColor: const Color(0xFFEFF1FE),
          label: 'Anı Girişi',
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4A4A4A)),
          onTap: () {
            Navigator.pushNamed(context, RotaIsimleri.gunlukGirisEkrani);
          },
        ),

        SpeedDialChild(
          child: const Icon(Icons.border_color_rounded, color: Color(0xFF6A93CB)),
          backgroundColor: const Color(0xFFE8F0FE),
          label: 'Alışkanlık',
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4A4A4A)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AliskanlikAjandaEkrani()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Color(0xFF918EF4), size: 26),
              tooltip: 'Konum Geçmişi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HaritaEkran()),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF918EF4), size: 26),
              tooltip: 'Anı Galerisi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GaleriEkran()),
                );
              },
            ),

            const SizedBox(width: 48),

            IconButton(
              icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF918EF4), size: 26),
              tooltip: 'Planlarım & Takvim',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TakvimEkran()),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF918EF4), size: 26),
              tooltip: 'Ayarlar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AyarlarEkran()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void showDallananAuraMenusu(BuildContext context, Offset baslangicNoktasi, Widget icerik) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 550),
      barrierColor: Colors.black26,
      pageBuilder: (context, animation, secondaryAnimation) => icerik,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          alignment: Alignment(
            (baslangicNoktasi.dx / MediaQuery.of(context).size.width) * 2 - 1,
            (baslangicNoktasi.dy / MediaQuery.of(context).size.height) * 2 - 1,
          ),
          scale: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 1.0, curve: Curves.fastLinearToSlowEaseIn),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    ),
  );
}