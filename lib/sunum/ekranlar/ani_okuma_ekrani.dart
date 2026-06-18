import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../veri/modeller/gunluk_giris_modeli.dart';
import '../bilesenler/ses_widget.dart';
import '../bilesenler/konum_onizleme_widget.dart';
import 'gunluk_giris_ekrani.dart';

class AniOkumaEkrani extends StatelessWidget {
  final GunlukGirisModeli ani;
  const AniOkumaEkrani({super.key, required this.ani});

  String _getAuraMetni(double deger) {
    if (deger < 15) return "Sinirli";
    if (deger < 35) return "Hüzünlü";
    if (deger < 50) return "Stresli";
    if (deger < 65) return "Sakin";
    if (deger < 85) return "Umutlu";
    return "Mutlu";
  }

  Color _getAuraRengi(double deger) {
    if (deger < 15) return const Color(0xFFD90429);
    if (deger < 35) return const Color(0xFF5D7B9D);
    if (deger < 50) return const Color(0xFFFB8500);
    if (deger < 65) return const Color(0xFF918EF4);
    if (deger < 85) return const Color(0xFF80ED99);
    return const Color(0xFFFFD700);
  }

  @override
  Widget build(BuildContext context) {
    double auraDegeri = double.tryParse(ani.duygu ?? "50") ?? 50.0;

    List<String> gorselListesi = (ani.gorselYolu ?? "").split('||').where((s) => s.isNotEmpty).toList();
    List<String> sesListesi = (ani.sesYolu ?? "").split('||').where((s) => s.isNotEmpty).toList();

    List<Map<String, dynamic>> okunanEmojiler = [];
    if (ani.stickerYolu != null && ani.stickerYolu!.isNotEmpty) {
      List<String> parcalar = ani.stickerYolu!.split('||');
      for (var parca in parcalar) {
        if (parca.contains(',')) {
          List<String> detay = parca.split(',');
          okunanEmojiler.add({
            'icerik': detay[0],
            'dx': detay.length > 2 ? double.tryParse(detay[2]) ?? 100.0 : 100.0,
            'dy': detay.length > 3 ? double.tryParse(detay[3]) ?? 100.0 : 100.0,
            'scale': detay.length > 4 ? double.tryParse(detay[4]) ?? 1.0 : 1.0,
            'rotation': detay.length > 5 ? double.tryParse(detay[5]) ?? 0.0 : 0.0,
          });
        }
      }
    }

    final String secilenFont = ani.yaziTipi ?? 'Roboto';
    final Color yaziRengi = ani.yaziRengi != null ? Color(ani.yaziRengi!) : const Color(0xFF2D2D2D);
    final String kaydedilenKagit = ani.kagitTuru ?? 'bos';

    return Scaffold(
      backgroundColor: Color(ani.arkaPlanKodu ?? 0xFFF4F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF918EF4),
        elevation: 4,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text("Düzenle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GunlukGirisEkrani(mevcutAni: ani),
            ),
          );
        },
      ),
      body: Hero(
        tag: 'ani_kart_${ani.id}',
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: CustomPaint(
              painter: OkumaDefterDeseniCizici(kagitTuruStr: kaydedilenKagit),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ani.tarih.length >= 10 ? ani.tarih.substring(0, 10) : ani.tarih,
                              style: const TextStyle(
                                color: Color(0xFF918EF4),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getAuraRengi(auraDegeri).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: _getAuraRengi(auraDegeri).withOpacity(0.5)),
                              ),
                              child: Text(
                                _getAuraMetni(auraDegeri),
                                style: TextStyle(color: _getAuraRengi(auraDegeri), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Text(
                          ani.metin,
                          style: GoogleFonts.getFont(
                            secilenFont,
                            fontSize: 18,
                            height: kaydedilenKagit == 'cizgili' ? 2.22 : 1.5,
                            letterSpacing: 0.5,
                            color: yaziRengi,
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (ani.enlem != null && ani.boylam != null) ...[
                          const Divider(color: Colors.black12),
                          const SizedBox(height: 10),
                          const Text("Anının Konumu", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          KonumOnizlemeWidget(
                            enlem: ani.enlem!,
                            boylam: ani.boylam!,
                            mekanIsmi: ani.mekanIsmi,
                            silmeIslemi: null,
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (sesListesi.isNotEmpty) ...[
                          const Divider(color: Colors.black12),
                          const SizedBox(height: 10),
                          const Text("Sesli Notlar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          ...sesListesi.map((ses) => Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: SesWidget(
                              sesYolu: ses,
                              temaRengi: Color(ani.arkaPlanKodu ?? 0xFFF4F5F9),
                              silmeIslemi: null,
                            ),
                          )),
                          const SizedBox(height: 20),
                        ],

                        if (gorselListesi.isNotEmpty) ...[
                          const Divider(color: Colors.black12),
                          const SizedBox(height: 10),
                          const Text("Anı Kareleri", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          ...gorselListesi.map((gorsel) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(gorsel),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),

                  ...okunanEmojiler.map((emoji) => Positioned(
                    left: emoji['dx'],
                    top: emoji['dy'],
                    child: Transform.rotate(
                      angle: emoji['rotation'] ?? 0.0,
                      child: Transform.scale(
                        scale: emoji['scale'] ?? 1.0,
                        child: Text(emoji['icerik'], style: const TextStyle(fontSize: 45)),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OkumaDefterDeseniCizici extends CustomPainter {
  final String kagitTuruStr;
  OkumaDefterDeseniCizici({required this.kagitTuruStr});

  @override
  void paint(Canvas canvas, Size size) {
    if (kagitTuruStr == 'bos' || kagitTuruStr == 'KagitTuru.bos') return;
    final paint = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth = 1.0;
    if (kagitTuruStr == 'cizgili' || kagitTuruStr == 'KagitTuru.cizgili') {
      for (double i = 60; i < size.height; i += 40.0) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    } else if (kagitTuruStr == 'kareli' || kagitTuruStr == 'KagitTuru.kareli') {
      const step = 25.0;
      for (double i = 0; i < size.width; i += step) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      for (double i = 0; i < size.height; i += step) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}