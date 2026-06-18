import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';

class GaleriEkran extends StatefulWidget {
  const GaleriEkran({super.key});

  @override
  State<GaleriEkran> createState() => _GaleriEkranState();
}

class _GaleriEkranState extends State<GaleriEkran> {
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
            SliverAppBar(
              expandedHeight: 80.0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
              title: const Text(
                'A N I  G A L E R İ S İ',
                style: TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                  fontSize: 18,
                ),
              ),
            ),

            Consumer<GunlukGirisSaglayicisi>(
              builder: (context, saglayici, child) {
                final kullaniciGorselliAnilari = saglayici.anilar.where((ani) {
                  return ani.kullaniciId == _aktifKullaniciId && ani.gorselYolu != null && ani.gorselYolu!.isNotEmpty;
                }).toList();

                List<Map<String, dynamic>> gorselOgeleri = [];
                for (var ani in kullaniciGorselliAnilari) {
                  List<String> yollar = ani.gorselYolu!.split('||').where((s) => s.isNotEmpty).toList();
                  for (var yol in yollar) {
                    gorselOgeleri.add({
                      'yol': yol,
                      'tarih': ani.tarih.length >= 10 ? ani.tarih.substring(0, 10).replaceAll('-', '.') : ani.tarih,
                      'ani': ani,
                    });
                  }
                }

                if (gorselOgeleri.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_back_rounded, size: 60, color: const Color(0xFF918EF4).withOpacity(0.5)),
                          const SizedBox(height: 15),
                          const Text(
                            "Gökyüzünde henüz hiç fotoğrafın yok...",
                            style: TextStyle(color: Colors.grey, fontSize: 16, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Anılarına görsel ekleyerek burayı canlandırabilirsin ✨",
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Yan yana 3 fotoğraf
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final oge = gorselOgeleri[index];
                        final String yol = oge['yol'];
                        final String tarih = oge['tarih'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                transitionDuration: const Duration(milliseconds: 400),
                                pageBuilder: (context, animation, secondaryAnimation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: TamEkranGorselGoruntuleyici(yol: yol, tarih: tarih, etiket: 'gorsel_$index'),
                                  );
                                },
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'gorsel_$index',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(yol),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 30),
                                      ),
                                    ),

                                    Positioned(
                                      bottom: 0, left: 0, right: 0,
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.8),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        alignment: Alignment.bottomCenter,
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          tarih,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: gorselOgeleri.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }
}

class TamEkranGorselGoruntuleyici extends StatelessWidget {
  final String yol;
  final String tarih;
  final String etiket;

  const TamEkranGorselGoruntuleyici({
    super.key,
    required this.yol,
    required this.tarih,
    required this.etiket,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(tarih, style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Center(
        child: Hero(
          tag: etiket,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              File(yol),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}