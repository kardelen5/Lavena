import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';

class HaftalikOzetEkrani extends StatefulWidget {
  const HaftalikOzetEkrani({super.key});

  @override
  State<HaftalikOzetEkrani> createState() => _HaftalikOzetEkraniState();
}

class _HaftalikOzetEkraniState extends State<HaftalikOzetEkrani> {
  int? _aktifKullaniciId;
  bool _oturumYuklendi = false;

  double _gunlukRutin = 0.0;
  double _haftalikRutin = 0.0;

  @override
  void initState() {
    super.initState();
    _aktifKullaniciyiYukle();
  }

  Future<void> _aktifKullaniciyiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _aktifKullaniciId = prefs.getInt('aktifKullaniciId');

        final String bugun = DateTime.now().toIso8601String().substring(0, 10);
        final String? historyJson = prefs.getString('lavena_rutin_history');

        if (historyJson != null) {
          Map<String, dynamic> historyMap = jsonDecode(historyJson);

          _gunlukRutin = (historyMap[bugun] ?? 0.0).toDouble();

          double toplam = 0.0;
          int sayac = 0;
          for (int i = 0; i < 7; i++) {
            String tarih = DateTime.now().subtract(Duration(days: i)).toIso8601String().substring(0, 10);
            if (historyMap.containsKey(tarih)) {
              toplam += (historyMap[tarih] as num).toDouble();
              sayac++;
            }
          }
          _haftalikRutin = sayac > 0 ? (toplam / sayac) : 0.0;
        }

        _oturumYuklendi = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_oturumYuklendi) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF918EF4))),
      );
    }

    final analiz = context.watch<GunlukGirisSaglayicisi>().haftalikAnalizHesapla(_aktifKullaniciId ?? 0);
    final bool analizMevcutDegil = analiz.isEmpty || analiz['toplam'] == 0 || analiz['toplam'] == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          "Lavena Panorama",
          style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.w300, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF918EF4)),
      ),
      body: analizMevcutDegil
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Analiz için henüz yeterli veri yok ✨\nBirkaç anı ekledikten sonra burayı tekrar kontrol et.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildHeroStats(analiz['toplam'].toString()),

            const SizedBox(height: 20),
            _buildRutinAnalysisCard(),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    "En Aktif Gün",
                    analiz['enAktifGun'] ?? "Veri Yok",
                    Icons.bolt_rounded,
                    Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInfoCard(
                    "Favori Yer",
                    analiz['favoriYer'] ?? "Veri Yok",
                    Icons.location_on_rounded,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildAuraCircle((analiz['ortalamaAura'] as num?)?.toDouble() ?? 50.0),

            const SizedBox(height: 20),

            _buildThemeAnalysis(analiz['enSikRenk'] as int? ?? Colors.white.value),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStats(String count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF918EF4), Color(0xFFB5A8F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF918EF4).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Text("Toplam Biriktirilen Yıldız", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 55, fontWeight: FontWeight.bold)),
          const Text("Anıların gökyüzünde parlıyor! ✨", style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRutinAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.query_stats_rounded, color: Color(0xFF918EF4)),
              SizedBox(width: 10),
              Text("Kararlılık ve Rutin Analizi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A4A4A))),
            ],
          ),
          const SizedBox(height: 20),

          _buildProgressRow("Bugünkü Başarın", _gunlukRutin, _gunlukRutin == 1.0 ? const Color(0xFF80ED99) : const Color(0xFF918EF4)),

          const SizedBox(height: 18),

          _buildProgressRow("Haftalık Kararlılık", _haftalikRutin, const Color(0xFF6A93CB)),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
            Text("%${(value * 100).toInt()}", style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4A4A4A))),
        ],
      ),
    );
  }

  Widget _buildAuraCircle(double aura) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: aura / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade100,
                  color: const Color(0xFF918EF4),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text("%${aura.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 25),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Duygusal Aura", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 5),
                Text(
                  "Bu hafta genel olarak dengeli ve huzurlu bir enerjiye sahipsin.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeAnalysis(int colorCode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.palette_rounded, color: Colors.blueGrey),
          const SizedBox(width: 15),
          const Text("En Sık Tercih Ettiğin Tema", style: TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Color(colorCode),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
          ),
        ],
      ),
    );
  }
}