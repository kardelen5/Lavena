import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VizyonOgesi {
  String id;
  String icerik;
  String tip;
  Offset konum;
  double boyut;
  double aci;

  VizyonOgesi({
    required this.id,
    required this.icerik,
    required this.tip,
    required this.konum,
    this.boyut = 120.0,
    this.aci = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'icerik': icerik,
    'tip': tip,
    'dx': konum.dx,
    'dy': konum.dy,
    'boyut': boyut,
    'aci': aci,
  };

  factory VizyonOgesi.fromJson(Map<String, dynamic> json) => VizyonOgesi(
    id: json['id'],
    icerik: json['icerik'],
    tip: json['tip'],
    konum: Offset(json['dx'], json['dy']),
    boyut: json['boyut'],
    aci: json['aci'],
  );
}

class VisionBoardEkran extends StatefulWidget {
  const VisionBoardEkran({super.key});

  @override
  State<VisionBoardEkran> createState() => _VisionBoardEkranState();
}

class _VisionBoardEkranState extends State<VisionBoardEkran> {
  List<VizyonOgesi> _panodakiOgeler = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _baslikController = TextEditingController();
  String? _seciliOgeId;
  bool _yukleniyor = true;
  int? _aktifKullaniciId;

  @override
  void initState() {
    super.initState();
    _panoyuYukle();
  }

  @override
  void dispose() {
    _baslikController.dispose();
    super.dispose();
  }

  Future<void> _panoyuKaydet() async {
    if (_aktifKullaniciId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String jsonVerisi = jsonEncode(
      _panodakiOgeler.map((oge) => oge.toJson()).toList(),
    );

    await prefs.setString('lavena_vision_board_data_$_aktifKullaniciId', jsonVerisi);
    await prefs.setString('lavena_vision_board_title_$_aktifKullaniciId', _baslikController.text);
  }

  Future<void> _panoyuYukle() async {
    final prefs = await SharedPreferences.getInstance();
    _aktifKullaniciId = prefs.getInt('aktifKullaniciId');

    if (_aktifKullaniciId == null) {
      setState(() => _yukleniyor = false);
      return;
    }

    final String? jsonVerisi = prefs.getString('lavena_vision_board_data_$_aktifKullaniciId');
    final String? kaydedilenBaslik = prefs.getString('lavena_vision_board_title_$_aktifKullaniciId');

    if (kaydedilenBaslik != null) {
      _baslikController.text = kaydedilenBaslik;
    } else {
      _baslikController.text = "VİZYON PANOSU";
    }

    if (jsonVerisi != null) {
      final List<dynamic> hamListe = jsonDecode(jsonVerisi);
      setState(() {
        _panodakiOgeler = hamListe.map((item) => VizyonOgesi.fromJson(item)).toList();
        _yukleniyor = false;
      });
    } else {
      setState(() => _yukleniyor = false);
    }
  }

  void _hizliMetinEkle(String metin) {
    setState(() {
      _panodakiOgeler.add(VizyonOgesi(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tip: 'soz',
        icerik: metin,
        konum: const Offset(100, 200),
        boyut: 150,
      ));
    });
    _panoyuKaydet();
  }

  Future<void> _galeridenResimSec() async {
    final XFile? secilenResim = await _picker.pickImage(source: ImageSource.gallery);
    if (secilenResim != null) {
      setState(() {
        _panodakiOgeler.add(VizyonOgesi(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tip: 'resim',
          icerik: secilenResim.path,
          konum: const Offset(80, 150),
          boyut: 140,
        ));
      });
      _panoyuKaydet();
    }
  }

  void _metinGirisSheet() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Motivasyon sözünü yaz...", border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFF918EF4)),
                onPressed: () {
                  if (textCtrl.text.trim().isNotEmpty) {
                    _hizliMetinEkle(textCtrl.text.trim());
                    Navigator.pop(ctx);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFE),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A93CB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _galeridenResimSec,
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
                    label: const Text("Galeri", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF918EF4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _metinGirisSheet,
                    icon: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 20),
                    label: const Text("Metin Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF918EF4)))
          : GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _seciliOgeId = null);
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE0EAFC), Color(0xFFFDFCFE)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A4A4A), size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60.0),
                          child: TextField(
                            controller: _baslikController,
                            textAlign: TextAlign.center,
                            onChanged: (_) => _panoyuKaydet(),
                            style: const TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 4,
                            ),
                            decoration: InputDecoration(
                              hintText: "BAŞLIKSIZ PANO",
                              hintStyle: TextStyle(
                                color: const Color(0xFF4A4A4A).withOpacity(0.3),
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 4,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: _panodakiOgeler.isEmpty
                      ? const Center(child: Text("Aşağıdaki araçları kullanarak\nhayallerini panoya iğnele! ✨", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                      : Stack(
                    children: _panodakiOgeler.map((oge) {
                      final bool isSelected = _seciliOgeId == oge.id;

                      return Positioned(
                        left: oge.konum.dx,
                        top: oge.konum.dy,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _seciliOgeId = oge.id;
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  _seciliOgeId = oge.id;
                                  oge.konum = Offset(oge.konum.dx + details.delta.dx, oge.konum.dy + details.delta.dy);
                                });
                              },
                              onPanEnd: (_) => _panoyuKaydet(),
                              child: Transform.rotate(
                                angle: oge.aci,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: isSelected ? Border.all(color: const Color(0xFF918EF4), width: 2) : null,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _buildPanoOgesiTasarimi(oge),
                                ),
                              ),
                            ),

                            if (isSelected) ...[
                              const SizedBox(height: 10),
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(Icons.add, color: Color(0xFF5A5A7A), size: 16),
                                      onPressed: () {
                                        setState(() => oge.boyut = (oge.boyut + 20).clamp(80, 300));
                                        _panoyuKaydet();
                                      },
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(Icons.remove, color: Color(0xFF5A5A7A), size: 16),
                                      onPressed: () {
                                        setState(() => oge.boyut = (oge.boyut - 20).clamp(80, 300));
                                        _panoyuKaydet();
                                      },
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(Icons.rotate_right_rounded, color: Color(0xFF6A93CB), size: 16),
                                      onPressed: () {
                                        setState(() => oge.aci += 0.2617);
                                        _panoyuKaydet();
                                      },
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: VerticalDivider(width: 10, thickness: 1),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _panodakiOgeler.removeWhere((item) => item.id == oge.id);
                                          _seciliOgeId = null;
                                        });
                                        _panoyuKaydet();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanoOgesiTasarimi(VizyonOgesi oge) {
    if (oge.tip == 'resim') {
      return Container(
        width: oge.boyut,
        height: oge.boyut,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(oge.icerik),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: oge.boyut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1FE).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCDFFF), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFF918EF4).withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Text(
          oge.icerik,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A), height: 1.3),
        ),
      );
    }
  }
}