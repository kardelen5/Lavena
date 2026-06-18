import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:latlong2/latlong.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobil_uygulamam/sunum/bilesenler/konum_secici_widget.dart';
import '../../veri/modeller/gunluk_giris_modeli.dart';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';
import '../bilesenler/yazi_stili_secici.dart';
import '../bilesenler/gorsel_widget.dart';
import '../bilesenler/ses_widget.dart';
import '../bilesenler/konum_onizleme_widget.dart';
import '../bilesenler/sticker_widget.dart';

enum KagitTuru { bos, cizgili, kareli }

class GunlukGirisEkrani extends StatefulWidget {
  final GunlukGirisModeli? mevcutAni;
  const GunlukGirisEkrani({super.key, this.mevcutAni});

  @override
  State<GunlukGirisEkrani> createState() => _GunlukGirisEkraniState();
}

class _GunlukGirisEkraniState extends State<GunlukGirisEkrani> {
  final TextEditingController _metinKontrolcusu = TextEditingController();

  Color _defterRengi = Colors.white;
  Color _yaziRengi = const Color(0xFF2D2D2D);
  Color _disArkaPlanRengi = const Color(0xFFE0E0E0);
  KagitTuru _secilenKagit = KagitTuru.kareli;
  String _secilenFont = "Roboto";
  final AudioRecorder _sesKaydedici = AudioRecorder();
  bool _kayitYapiliyorMu = false;

  List<Map<String, dynamic>> _eklenenStickerlar = [];
  List<String> _gorselYollari = [];
  List<String> _sesYollari = [];
  double? _enlem;
  double? _boylam;
  String? _konumIsmi;
  DateTime? _secilenKilitTarihi;
  double _auraSeviyesi = 50.0;

  final List<Color> _renkPaleti = [
    Colors.white, const Color(0xFFFDEBF1), const Color(0xFFEBF4FD),
    const Color(0xFFE8F5E9), const Color(0xFFFFF3E0), const Color(0xFFF3E5F5),
    const Color(0xFFFFF9C4), const Color(0xFFD7CCC8), const Color(0xFFCFD8DC),
  ];

  @override
  void initState() {
    super.initState();

    if (widget.mevcutAni != null) {
      _metinKontrolcusu.text = widget.mevcutAni!.metin;
      _auraSeviyesi = double.tryParse(widget.mevcutAni!.duygu ?? "50") ?? 50.0;
      _defterRengi = Color(widget.mevcutAni!.arkaPlanKodu ?? Colors.white.value);
      _yaziRengi = Color(widget.mevcutAni!.yaziRengi ?? 0xFF2D2D2D);
      _secilenFont = widget.mevcutAni!.yaziTipi ?? "Roboto";
      _enlem = widget.mevcutAni!.enlem;
      _boylam = widget.mevcutAni!.boylam;
      _konumIsmi = widget.mevcutAni!.mekanIsmi;

      if (widget.mevcutAni!.kilitAcilmaTarihi != null) {
        _secilenKilitTarihi = DateTime.tryParse(widget.mevcutAni!.kilitAcilmaTarihi!);
      }

      if (widget.mevcutAni!.kagitTuru != null) {
        _secilenKagit = KagitTuru.values.firstWhere(
              (e) => e.name == widget.mevcutAni!.kagitTuru,
          orElse: () => KagitTuru.kareli,
        );
      }

      if (widget.mevcutAni!.gorselYolu != null && widget.mevcutAni!.gorselYolu!.isNotEmpty) {
        _gorselYollari = widget.mevcutAni!.gorselYolu!.split('||');
      }
      if (widget.mevcutAni!.sesYolu != null && widget.mevcutAni!.sesYolu!.isNotEmpty) {
        _sesYollari = widget.mevcutAni!.sesYolu!.split('||');
      }

      if (widget.mevcutAni!.stickerYolu != null && widget.mevcutAni!.stickerYolu!.isNotEmpty) {
        List<String> parcalar = widget.mevcutAni!.stickerYolu!.split('||');
        for (var parca in parcalar) {
          if (parca.contains(',')) {
            List<String> detay = parca.split(',');
            _eklenenStickerlar.add({
              'icerik': detay[0],
              'emojiMi': detay[1] == 'true',
              'dx': detay.length > 2 ? double.tryParse(detay[2]) ?? 100.0 : 100.0,
              'dy': detay.length > 3 ? double.tryParse(detay[3]) ?? 100.0 : 100.0,
              'scale': detay.length > 4 ? double.tryParse(detay[4]) ?? 1.0 : 1.0,
              'rotation': detay.length > 5 ? double.tryParse(detay[5]) ?? 0.0 : 0.0,
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _metinKontrolcusu.dispose();
    _sesKaydedici.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _disArkaPlanRengi,
      appBar: _buildTopBar(),
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildAuraKaydirici(),
          const SizedBox(height: 10),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 65),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.75),
                decoration: BoxDecoration(
                  color: _defterRengi,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2, offset: Offset(0, 5))],
                ),
                child: CustomPaint(
                  painter: DefterDeseniCizici(kagitTuru: _secilenKagit),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: TextField(
                          controller: _metinKontrolcusu,
                          maxLines: null,
                          style: GoogleFonts.getFont(
                            _secilenFont, fontSize: 18, height: _secilenKagit == KagitTuru.cizgili ? 2.22 : 1.5, color: _yaziRengi,
                          ),
                          decoration: const InputDecoration(hintText: "Hikayene başla...", border: InputBorder.none),
                        ),
                      ),

                      if (_enlem != null && _boylam != null)
                        KonumOnizlemeWidget(
                          enlem: _enlem!, boylam: _boylam!, mekanIsmi: _konumIsmi,
                          silmeIslemi: () {
                            setState(() {
                              _enlem = null;
                              _boylam = null;
                              _konumIsmi = null;
                            });
                          },
                        ),

                      ..._eklenenStickerlar.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> sticker = entry.value;
                        return StickerWidget(
                          key: ValueKey('sticker_${index}_${sticker['icerik']}'),
                          icerik: sticker['icerik'],
                          emojiMi: sticker['emojiMi'],
                          baslangicX: sticker['dx'] ?? 100.0,
                          baslangicY: sticker['dy'] ?? 100.0,
                          baslangicScale: sticker['scale'] ?? 1.0,
                          baslangicRotation: sticker['rotation'] ?? 0.0,
                          onKonumDegisti: (x, y, scale, rotation) {
                            _eklenenStickerlar[index]['dx'] = x;
                            _eklenenStickerlar[index]['dy'] = y;
                            _eklenenStickerlar[index]['scale'] = scale;
                            _eklenenStickerlar[index]['rotation'] = rotation;
                          },
                          silmeIslemi: () {
                            setState(() => _eklenenStickerlar.removeAt(index));
                          },
                        );
                      }),

                      ..._gorselYollari.asMap().entries.map((entry) {
                        int index = entry.key;
                        return GorselWidget(
                          key: ValueKey(entry.value + index.toString()), resimYolu: entry.value,
                          silmeIslemi: () => setState(() => _gorselYollari.removeAt(index)),
                        );
                      }),

                      ..._sesYollari.asMap().entries.map((entry) {
                        int index = entry.key;
                        return SesWidget(
                          key: ValueKey(entry.value), sesYolu: entry.value, temaRengi: _defterRengi,
                          silmeIslemi: () => setState(() => _sesYollari.removeAt(index)),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildAltMenu(),
        ],
      ),
    );
  }

  Widget _buildAltMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _menuButonu(Icons.grid_on, "Kağıt", _kagitSeciciyiAc),
            _menuButonu(Icons.emoji_emotions, "Emoji", _emojiSeciciyiAc),
            _menuButonu(Icons.image, "Görsel", _gorselSec),
            _menuButonu(Icons.palette, "Renk", _renkSeciciyiAc),
            _menuButonu(Icons.location_on, "Konum", _konumSecmeEkraniniAc),
            _menuButonu(Icons.text_format, "Yazı Stili", _yaziStiliMenusuAc),
            InkWell(
              onTap: _sesKaydetVeyaDurdur,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_kayitYapiliyorMu ? Icons.stop_circle : Icons.mic, color: _kayitYapiliyorMu ? Colors.red : Colors.black54, size: _kayitYapiliyorMu ? 30 : 24),
                  Text(_kayitYapiliyorMu ? "Kaydediliyor..." : "Ses", style: TextStyle(fontSize: 10, color: _kayitYapiliyorMu ? Colors.red : Colors.black54))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAuraMetni(double deger) {
    if (deger < 15) return "Sinirli / Öfkeli";
    if (deger < 35) return "Üzgün / Hüzünlü";
    if (deger < 50) return "Stresli / Gergin";
    if (deger < 65) return "Sakin / Nötr";
    if (deger < 85) return "Umutlu / İyi";
    return "Çok Mutlu / Enerjik";
  }

  Color _getAuraRengi(double deger) {
    if (deger < 15) return const Color(0xFFD90429);
    if (deger < 35) return const Color(0xFF5D7B9D);
    if (deger < 50) return const Color(0xFFFB8500);
    if (deger < 65) return const Color(0xFF918EF4);
    if (deger < 85) return const Color(0xFF80ED99);
    return const Color(0xFFFFD700);
  }

  Widget _buildAuraKaydirici() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(color: _getAuraRengi(_auraSeviyesi), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
          child: Text("Bugünkü Auran: ${_getAuraMetni(_auraSeviyesi)}"),
        ),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 25), height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            gradient: const LinearGradient(colors: [Color(0xFFD90429), Color(0xFF5D7B9D), Color(0xFFFB8500), Color(0xFF918EF4), Color(0xFFFFD700)]),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.transparent, inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white, overlayColor: Colors.white.withOpacity(0.3),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 5),
            ),
            child: Slider(value: _auraSeviyesi, min: 0, max: 100, onChanged: (yeniDeger) => setState(() => _auraSeviyesi = yeniDeger)),
          ),
        ),
      ],
    );
  }

  void _renkSeciciyiAc() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20), height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sayfa Rengini Seç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 15, mainAxisSpacing: 15),
                itemCount: _renkPaleti.length,
                itemBuilder: (context, index) {
                  final renk = _renkPaleti[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _defterRengi = renk;
                        _disArkaPlanRengi = HSLColor.fromColor(renk).withLightness((HSLColor.fromColor(renk).lightness - 0.08).clamp(0.0, 1.0)).toColor();
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: renk, shape: BoxShape.circle, border: Border.all(color: Colors.black12, width: 1),
                        boxShadow: _defterRengi == renk ? [const BoxShadow(color: Colors.black26, blurRadius: 5)] : [],
                      ),
                      child: _defterRengi == renk ? const Icon(Icons.check, color: Colors.black54) : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _kagitSeciciyiAc() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _kagitSecButonu(KagitTuru.bos, "Boş"), _kagitSecButonu(KagitTuru.cizgili, "Çizgili"), _kagitSecButonu(KagitTuru.kareli, "Kareli"),
          ],
        ),
      ),
    );
  }

  void _yaziStiliMenusuAc() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => YaziStiliSecici(
        mevcutFont: _secilenFont, mevcutRenk: _yaziRengi,
        onFontSecildi: (font) => setState(() => _secilenFont = font),
        onRenkSecildi: (renk) => setState(() => _yaziRengi = renk),
      ),
    );
  }

  void _emojiSeciciyiAc() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SizedBox(
        height: 400,
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(15.0), child: Text("Emoji Seç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    _eklenenStickerlar.add({
                      'icerik': emoji.emoji,
                      'emojiMi': true,
                      'dx': 100.0,
                      'dy': 100.0,
                      'scale': 1.0,
                      'rotation': 0.0,
                    });
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kagitSecButonu(KagitTuru tur, String etiket) {
    return TextButton(onPressed: () { setState(() => _secilenKagit = tur); Navigator.pop(context); }, child: Text(etiket));
  }

  Widget _menuButonu(IconData i, String l, VoidCallback o) {
    return InkWell(onTap: o, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(i, color: Colors.black54), Text(l, style: const TextStyle(fontSize: 10))]));
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: Colors.transparent, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
      actions: [
        if (widget.mevcutAni != null)
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26), onPressed: _aniSil),
        IconButton(icon: const Icon(Icons.lock_open, color: Colors.orange), onPressed: _kilitTarihiSecici),
        TextButton(onPressed: () => _kaydet(), child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF918EF4), fontSize: 16))),
      ],
    );
  }

  void _aniSil() async {
    if (widget.mevcutAni?.id == null) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Anıyı Sil"), content: const Text("Bu anıyı günlüğünden tamamen silmek istediğine emin misin? Bu işlem geri alınamaz."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true), child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        final saglayici = Provider.of<GunlukGirisSaglayicisi>(context, listen: false);
        await saglayici.aniSil(widget.mevcutAni!.id!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _kilitTarihiSecici() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (picked != null) setState(() => _secilenKilitTarihi = picked);
  }

  Future<void> _gorselSec() async {
    try {
      final ImagePicker p = ImagePicker();
      final List<XFile> secilenler = await p.pickMultiImage();
      if (secilenler.isNotEmpty) setState(() { for (var x in secilenler) _gorselYollari.add(x.path); });
    } catch (e) { debugPrint("Görsel seçerken hata oluştu: $e"); }
  }

  Future<void> _sesKaydetVeyaDurdur() async {
    try {
      if (_kayitYapiliyorMu) {
        final String? yol = await _sesKaydedici.stop();
        if (yol != null) setState(() { _kayitYapiliyorMu = false; _sesYollari.add(yol); });
      } else {
        if (await _sesKaydedici.hasPermission()) {
          String path = '';
          if (!kIsWeb) {
            final dir = await getApplicationDocumentsDirectory();
            path = '${dir.path}/kayit_${DateTime.now().millisecondsSinceEpoch}.m4a';
          }
          await _sesKaydedici.start(const RecordConfig(), path: path);
          setState(() => _kayitYapiliyorMu = true);
        }
      }
    } catch (e) { debugPrint("Ses kaydı hatası: $e"); }
  }

  Future<void> _konumSecmeEkraniniAc() async {
    LatLng baslangic = LatLng(41.0082, 28.9784);
    final Map<String, dynamic>? sonuc = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * 0.85, child: KonumSeciciWidget(baslangicKonumu: baslangic)),
    );
    if (sonuc != null) setState(() { _enlem = sonuc['konum'].latitude; _boylam = sonuc['konum'].longitude; _konumIsmi = sonuc['isim']; });
  }

  void _kaydet() async {
    if (_metinKontrolcusu.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final int? aktifKullaniciId = prefs.getInt('aktifKullaniciId');
    if (aktifKullaniciId == null) return;

    final saglayici = Provider.of<GunlukGirisSaglayicisi>(context, listen: false);

    String? birlestirilmisSesYollari = _sesYollari.isNotEmpty ? _sesYollari.join('||') : null;
    String? birlestirilmisGorselYollari = _gorselYollari.isNotEmpty ? _gorselYollari.join('||') : null;

    String? birlestirilmisStickerlar;
    if (_eklenenStickerlar.isNotEmpty) {
      birlestirilmisStickerlar = _eklenenStickerlar.map((s) =>
      "${s['icerik']},${s['emojiMi']},${s['dx']},${s['dy']},${s['scale']},${s['rotation']}"
      ).join('||');
    }

    final islenecekAni = GunlukGirisModeli(
      id: widget.mevcutAni?.id,
      kullaniciId: aktifKullaniciId,
      metin: _metinKontrolcusu.text,
      tarih: widget.mevcutAni?.tarih ?? DateTime.now().toIso8601String(),
      kilitAcilmaTarihi: _secilenKilitTarihi?.toIso8601String(),
      arkaPlanKodu: _defterRengi.value,
      duygu: _auraSeviyesi.toInt().toString(),
      gorselYolu: birlestirilmisGorselYollari,
      sesYolu: birlestirilmisSesYollari,
      stickerYolu: birlestirilmisStickerlar,
      enlem: _enlem,
      boylam: _boylam,
      mekanIsmi: _konumIsmi,
      kagitTuru: _secilenKagit.name,
      yaziRengi: _yaziRengi.value,
      yaziTipi: _secilenFont,
    );

    try {
      if (widget.mevcutAni != null) {
        await saglayici.aniGuncelle(islenecekAni);
      } else {
        await saglayici.aniEkle(islenecekAni);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.redAccent));
    }
  }
}

class DefterDeseniCizici extends CustomPainter {
  final KagitTuru kagitTuru;
  DefterDeseniCizici({required this.kagitTuru});

  @override
  void paint(Canvas canvas, Size size) {
    if (kagitTuru == KagitTuru.bos) return;
    final paint = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth = 1.0;
    if (kagitTuru == KagitTuru.cizgili) {
      for (double i = 60; i < size.height; i += 40.0) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    } else if (kagitTuru == KagitTuru.kareli) {
      const step = 25.0;
      for (double i = 0; i < size.width; i += step) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      for (double i = 0; i < size.height; i += step) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}