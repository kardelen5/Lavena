import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../veri/modeller/aliskanlik_modeli.dart';
import '../durum_yonetimi/aliskanlik_saglayicisi.dart';

class AliskanlikAjandaEkrani extends StatefulWidget {
  const AliskanlikAjandaEkrani({super.key});

  @override
  State<AliskanlikAjandaEkrani> createState() => _AliskanlikAjandaEkraniState();
}

class _AliskanlikAjandaEkraniState extends State<AliskanlikAjandaEkrani> {
  final TextEditingController _ajandaBaslikController = TextEditingController();
  Color _secilenKalemRengi = const Color(0xFFFFF59D);
  int? _aktifKullaniciId;

  List<String> _kategoriler = ['Rutin', 'Kitaplar', 'Filmler', 'Mekanlar'];
  String _seciliKategori = 'Rutin';

  @override
  void initState() {
    super.initState();
    _ajandaVerileriniYukle();
  }

  @override
  void dispose() {
    _ajandaBaslikController.dispose();
    super.dispose();
  }

  Future<void> _kategorileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lavena_kategoriler', jsonEncode(_kategoriler));
  }

  Future<void> _kararlilikKaydet(List<AliskanlikModeli> aliskanliklar) async {
    final prefs = await SharedPreferences.getInstance();

    final rutinler = aliskanliklar.where((a) => a.kategori == 'Rutin').toList();
    double ilerleme = 0.0;
    if (rutinler.isNotEmpty) {
      int tamamlanan = rutinler.where((a) => a.tamamlandi).length;
      ilerleme = tamamlanan / rutinler.length;
    }

    final String bugun = DateTime.now().toIso8601String().substring(0, 10);
    final String? historyJson = prefs.getString('lavena_rutin_history');

    Map<String, dynamic> historyMap = historyJson != null ? jsonDecode(historyJson) : {};
    historyMap[bugun] = ilerleme;

    await prefs.setString('lavena_rutin_history', jsonEncode(historyMap));
  }

  Future<void> _ajandaVerileriniYukle() async {
    final prefs = await SharedPreferences.getInstance();
    _aktifKullaniciId = prefs.getInt('aktifKullaniciId');

    final String? kaydedilenKategoriler = prefs.getString('lavena_kategoriler');
    if (kaydedilenKategoriler != null) {
      _kategoriler = List<String>.from(jsonDecode(kaydedilenKategoriler));
    }

    _ajandaBaslikController.text = "ALIŞKANLIKLAR";

    if (_aktifKullaniciId != null && mounted) {
      context.read<AliskanlikSaglayicisi>().aliskanliklariYukle(_aktifKullaniciId!);
    }
  }

  void _yeniKategoriEkle() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text("Yeni Kategori Oluştur", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF4A4A4A)),
          decoration: InputDecoration(
            hintText: "Örn: Denenecek Tarifler",
            filled: true,
            fillColor: const Color(0xFFF4F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF918EF4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () {
              final yeniKat = textCtrl.text.trim();
              if (yeniKat.isNotEmpty && !_kategoriler.contains(yeniKat)) {
                setState(() { _kategoriler.add(yeniKat); _seciliKategori = yeniKat; });
                _kategorileriKaydet();
              }
              Navigator.pop(ctx);
            },
            child: const Text("Ekle", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _yeniAliskanlikEkle() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Text("$_seciliKategori Ekle", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Görev adını girin...",
                  filled: true, fillColor: const Color(0xFFF4F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              const Align(alignment: Alignment.centerLeft, child: Text("Fosforlu Kalem Rengi:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12, runSpacing: 10, alignment: WrapAlignment.center,
                children: [
                  const Color(0xFFFFF59D), const Color(0xFFB2EBF2), const Color(0xFFE1BEE7),
                  const Color(0xFFC8E6C9), const Color(0xFFFFCCBC), const Color(0xFFF8BBD0),
                ].map((renk) {
                  final bool seciliMi = _secilenKalemRengi == renk;
                  return GestureDetector(
                    onTap: () { setDialogState(() => _secilenKalemRengi = renk); setState(() => _secilenKalemRengi = renk); },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: renk, shape: BoxShape.circle,
                        border: Border.all(color: seciliMi ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: seciliMi ? [BoxShadow(color: renk.withOpacity(0.8), blurRadius: 10)] : null,
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF918EF4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                if (textCtrl.text.trim().isEmpty || _aktifKullaniciId == null) return;

                final yeniMadde = AliskanlikModeli(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  kullaniciId: _aktifKullaniciId!,
                  baslik: textCtrl.text.trim(),
                  fosforluRenk: _secilenKalemRengi.value,
                  kategori: _seciliKategori,
                  tarih: DateTime.now().toIso8601String().substring(0, 10),
                );

                await context.read<AliskanlikSaglayicisi>().aliskanlikEkle(yeniMadde);

                final guncelListe = context.read<AliskanlikSaglayicisi>().aliskanliklar;
                _kararlilikKaydet(guncelListe);

                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("İşle", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildKararlilikSayaci(List<AliskanlikModeli> guncelListe) {
    if (_seciliKategori != 'Rutin' || guncelListe.isEmpty) return const SizedBox.shrink();

    int tamamlanan = guncelListe.where((a) => a.tamamlandi).length;
    int toplam = guncelListe.length;
    double ilerleme = tamamlanan / toplam;
    bool hepsiTamam = ilerleme == 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hepsiTamam ? "Harikasın! Tüm rutinler tamam 🌟" : "Kararlılık Sayacı 🎯",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: hepsiTamam ? const Color(0xFF918EF4) : const Color(0xFF4A4A4A))),
              Text("%${(ilerleme * 100).toInt()}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: hepsiTamam ? const Color(0xFF80ED99) : const Color(0xFF918EF4))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ilerleme, minHeight: 8,
              backgroundColor: const Color(0xFFF4F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(hepsiTamam ? const Color(0xFF80ED99) : const Color(0xFF918EF4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriSecici() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _kategoriler.length + 1,
        itemBuilder: (context, index) {
          if (index == _kategoriler.length) {
            return GestureDetector(
              onTap: _yeniKategoriEkle,
              child: Container(
                margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF4F5F9), borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF918EF4).withOpacity(0.5))),
                child: const Center(child: Row(children: [Icon(Icons.add_rounded, size: 16, color: Color(0xFF918EF4)),
                    SizedBox(width: 4), Text("Ekle", style: TextStyle(color: Color(0xFF918EF4), fontWeight: FontWeight.bold, fontSize: 13))])),
              ),
            );
          }
          final kategori = _kategoriler[index];
          final seciliMi = _seciliKategori == kategori;

          return GestureDetector(
            onTap: () => setState(() => _seciliKategori = kategori),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250), margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: seciliMi ? const Color(0xFF918EF4) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: seciliMi ? Colors.transparent : Colors.grey.shade200)),
              child: Center(child: Text(kategori, style: TextStyle(color: seciliMi ? Colors.white : Colors.grey.shade600, fontWeight: seciliMi ? FontWeight.bold : FontWeight.w500, fontSize: 13))),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFE),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF918EF4),
        onPressed: _yeniAliskanlikEkle,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 22),
        label: const Text("Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AliskanlikSaglayicisi>(
        builder: (context, saglayici, child) {
          if (saglayici.yukleniyor) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF918EF4)));
          }

          final gosterilecekListe = saglayici.aliskanliklar.where((a) => a.kategori == _seciliKategori).toList();

          return Container(
            width: double.infinity, height: double.infinity,
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE0EAFC), Color(0xFFFDFCFE)])),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF918EF4), size: 22), onPressed: () => Navigator.pop(context)),
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child:
                        TextField(controller: _ajandaBaslikController, textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 5),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true)))),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  _buildKategoriSecici(),
                  _buildKararlilikSayaci(gosterilecekListe),

                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned(left: 55, top: 0, bottom: 0, child: Container(width: 2, color: const Color(0xFF918EF4).withOpacity(0.2))),
                            GestureDetector(
                              onTap: () => FocusScope.of(context).unfocus(),
                              child: gosterilecekListe.isEmpty
                                  ? const Center(child: Text("Bu liste henüz boş...", style: TextStyle(color: Colors.grey)))
                                  : ListView.builder(
                                padding: const EdgeInsets.only(left: 15, right: 20, top: 30, bottom: 100),
                                physics: const BouncingScrollPhysics(),
                                itemCount: gosterilecekListe.length,
                                itemBuilder: (context, index) {
                                  final aliskanlik = gosterilecekListe[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6), constraints: const BoxConstraints(minHeight: 55),
                                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.5))),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          child: Center(
                                            child: GestureDetector(
                                              onTap: () async {
                                                await saglayici.aliskanlikDurumGuncelle(aliskanlik.id, !aliskanlik.tamamlandi);
                                                _kararlilikKaydet(saglayici.aliskanliklar);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 300), width: 24, height: 24,
                                                decoration: BoxDecoration(
                                                  color: aliskanlik.tamamlandi ? const Color(0xFF918EF4) : Colors.transparent, shape: BoxShape.circle,
                                                  border: Border.all(color: aliskanlik.tamamlandi ? const Color(0xFF918EF4) : Colors.grey.shade300, width: 2),
                                                ),
                                                child: aliskanlik.tamamlandi ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 250), padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                                                  color: aliskanlik.tamamlandi ? Color(aliskanlik.fosforluRenk).withOpacity(0.9) : Colors.transparent),
                                              child: Text(
                                                aliskanlik.baslik,
                                                style: TextStyle(
                                                  fontSize: 16, fontWeight: aliskanlik.tamamlandi ? FontWeight.w600 : FontWeight.w400,
                                                  color: aliskanlik.tamamlandi ? const Color(0xFF4A4A4A) : Colors.black87,
                                                  decoration: aliskanlik.tamamlandi ? TextDecoration.lineThrough : TextDecoration.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Colors.black26, size: 20),
                                          onPressed: () async {
                                            await saglayici.aliskanlikSil(aliskanlik.id);
                                            _kararlilikKaydet(saglayici.aliskanliklar);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}