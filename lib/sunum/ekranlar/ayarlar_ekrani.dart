import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';
import '../../cekirdek/yonlendirme/rota_isimleri.dart';
import '../../veri/depolar/kullanici_repository.dart';
import '../../veri/modeller/gunluk_giris_modeli.dart';

class AyarlarEkran extends StatefulWidget {
  const AyarlarEkran({super.key});

  @override
  State<AyarlarEkran> createState() => _AyarlarEkranState();
}

class _AyarlarEkranState extends State<AyarlarEkran> {
  final KullaniciRepository _kullaniciRepo = KullaniciRepository();
  final FlutterLocalNotificationsPlugin _bildirimEklentisi = FlutterLocalNotificationsPlugin();

  String _kullaniciAdi = "Yükleniyor...";
  String? _profilResmiYolu;
  int? _aktifKullaniciId;
  bool _hatirlaticiAcik = false;
  TimeOfDay _hatirlaticiSaati = const TimeOfDay(hour: 20, minute: 30);

  @override
  void initState() {
    super.initState();
    _bilgileriYukle();
    _bildirimSisteminiBaslat();
  }

  Future<void> _bildirimSisteminiBaslat() async {
    tz.initializeTimeZones(); // Saat dilimlerini başlat
    const AndroidInitializationSettings androidAyarlari = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings ayarlar = InitializationSettings(android: androidAyarlari);
    await _bildirimEklentisi.initialize(ayarlar);
  }

  Future<void> _gunlukBildirimiAyarla(bool aktif, TimeOfDay saat) async {
    if (!aktif) {
      await _bildirimEklentisi.cancelAll();
      return;
    }

    // Android için bildirim kanalı
    const AndroidNotificationDetails androidDetay = AndroidNotificationDetails(
      'lavena_gunluk_kanal',
      'Lavena Günlük Hatırlatıcı',
      channelDescription: 'Her akşam günlük yazmanız için hatırlatma yapar.',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF918EF4),
    );
    const NotificationDetails bildirimDetaylari = NotificationDetails(android: androidDetay);

    final simdi = tz.TZDateTime.now(tz.local);
    tz.TZDateTime planlananZaman = tz.TZDateTime(tz.local, simdi.year, simdi.month, simdi.day, saat.hour, saat.minute);

    if (planlananZaman.isBefore(simdi)) {
      planlananZaman = planlananZaman.add(const Duration(days: 1));
    }

    await _bildirimEklentisi.zonedSchedule(
      0,
      'Günlük Vakti! ✨',
      'Günün nasıl geçti? Gökyüzüne yeni bir yıldız ekleme zamanı...',
      planlananZaman,
      bildirimDetaylari,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _bilgileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('aktifKullaniciId');

    if (id != null) {
      final kullanici = await _kullaniciRepo.kullaniciyiGetir(id);

      if (kullanici != null) {
        setState(() {
          _aktifKullaniciId = id;
          _kullaniciAdi = kullanici.kullaniciAdi;
          _profilResmiYolu = null;
          _hatirlaticiAcik = prefs.getBool('hatirlaticiAcik') ?? false;

          final saatStr = prefs.getString('hatirlaticiSaati');
          if (saatStr != null) {
            final parcalar = saatStr.split(':');
            _hatirlaticiSaati = TimeOfDay(hour: int.parse(parcalar[0]), minute: int.parse(parcalar[1]));
          }
        });
      }
    }
  }

  Future<void> _profilResmiSec() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? secilenResim = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (secilenResim != null && _aktifKullaniciId != null) {
        bool basarili = await _kullaniciRepo.profilResmiGuncelle(_aktifKullaniciId!, secilenResim.path);
        if (basarili) {
          setState(() {
            _profilResmiYolu = secilenResim.path;
          });
          if (mounted) _ustMesajGoster(context, "Profil resmin başarıyla güncellendi! 📸", hata: false);
        }
      }
    } catch (e) {
      debugPrint("Profil resmi seçilirken hata: $e");
    }
  }

  void _ustMesajGoster(BuildContext ctx, String mesaj, {bool hata = true}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(mesaj, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: hata ? Colors.redAccent : const Color(0xFF80ED99),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).size.height - 120, left: 20, right: 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _gercekPdfOlusturVePaylas(List<GunlukGirisModeli> secilenAnilar) async {
    if (secilenAnilar.isEmpty) return;

    try {
      final pdf = pw.Document();

      for (var ani in secilenAnilar) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "L A V E N A  A N I S I",
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Tarih: ${ani.tarih}",
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                  if (ani.mekanIsmi != null) ...[
                    pw.SizedBox(height: 5),
                    pw.Text("Mekan: ${ani.mekanIsmi}", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                  pw.Divider(color: PdfColors.deepPurple200, thickness: 1.5),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    ani.metin,
                    style: const pw.TextStyle(fontSize: 16, lineSpacing: 1.5),
                  ),
                ],
              );
            },
          ),
        );
      }

      final output = await getTemporaryDirectory();
      final dosyaYolu = "${output.path}/Lavena_Anilarim_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(dosyaYolu);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Lavena Uygulamasından Dışa Aktarılan Anılarım ✨');

      if (mounted) _ustMesajGoster(context, "PDF Başarıyla Oluşturuldu! 📄", hata: false);
    } catch (e) {
      if (mounted) _ustMesajGoster(context, "PDF oluşturulurken bir hata oluştu.");
    }
  }

  void _seciliPdfAktarSheet() {
    final tumAnilar = context.read<GunlukGirisSaglayicisi>().anilar.where((a) => a.kullaniciId == _aktifKullaniciId).toList();
    List<GunlukGirisModeli> seciliAnilar = [];

    if (tumAnilar.isEmpty) {
      _ustMesajGoster(context, "Dışarı aktarılacak hiçbir anınız bulunmuyor.");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Anıları PDF Olarak Aktar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
              const SizedBox(height: 5),
              Text("${seciliAnilar.length} anı seçildi", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: tumAnilar.length,
                  itemBuilder: (context, index) {
                    final ani = tumAnilar[index];
                    final bool seciliMi = seciliAnilar.contains(ani);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: seciliMi ? const Color(0xFF918EF4).withOpacity(0.1) : const Color(0xFFF4F5F9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: seciliMi ? const Color(0xFF918EF4) : Colors.transparent),
                      ),
                      child: CheckboxListTile(
                        activeColor: const Color(0xFF918EF4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        title: Text(ani.tarih.length >= 10 ? ani.tarih.substring(0, 10) : ani.tarih, style: const TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(ani.metin, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        value: seciliMi,
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              seciliAnilar.add(ani);
                            } else {
                              seciliAnilar.remove(ani);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF918EF4),
                      elevation: 5,
                      shadowColor: const Color(0xFF918EF4).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  onPressed: seciliAnilar.isEmpty ? null : () {
                    Navigator.pop(ctx);
                    _gercekPdfOlusturVePaylas(seciliAnilar);
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                  label: const Text("PDF OLUŞTUR VE PAYLAŞ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _kullanimKilavuzuGoster() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Kullanım Kılavuzu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
            const SizedBox(height: 10),
            const Text("Lavena'yı adım adım keşfet", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            const Expanded(
              child: YoutubeOynaticiWidget(
                videoUrl: 'https://youtu.be/vvkLk1huMGo?si=rNik5EvGn43ufBqI',
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("KAPAT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _hakkindaGoster() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(25),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 30, color: Color(0xFF918EF4)),
            SizedBox(width: 10),
            Text("Lavena", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Lavena, anılarınızı gökyüzünde birer yıldız gibi saklayan bir dijital ajandadır.",
              style: TextStyle(height: 1.4, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text("Geliştiriciler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF918EF4))),
            const SizedBox(height: 5),
            const Text("• Kardelen Nur Kargacı\n• Selen Akdik", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF918EF4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF918EF4).withOpacity(0.5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded, color: Color(0xFF918EF4), size: 28),
                  SizedBox(height: 8),
                  Text("Bize Ulaşın", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
                  SizedBox(height: 4),
                  Text("destek@lavena.com", style: TextStyle(color: Color(0xFF918EF4), fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Center(child: Text("Sürüm v1.1.0", style: TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("KAPAT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saatSec() async {
    final TimeOfDay? secilenSaat = await showTimePicker(context: context, initialTime: _hatirlaticiSaati);
    if (secilenSaat != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hatirlaticiSaati', "${secilenSaat.hour}:${secilenSaat.minute}");

      setState(() { _hatirlaticiSaati = secilenSaat; });

      if (_hatirlaticiAcik) {
        _gunlukBildirimiAyarla(true, secilenSaat);
        _ustMesajGoster(context, "Hatırlatıcı saati ${_hatirlaticiSaati.format(context)} olarak güncellendi 🔔", hata: false);
      }
    }
  }

  void _adiDuzenleSheet() {
    final TextEditingController nameCtrl = TextEditingController(text: _kullaniciAdi);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(30, 20, 30, MediaQuery.of(ctx).viewInsets.bottom + 30),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Karşılama Adını Değiştir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Yeni Kullanıcı Adınız",
                prefixIcon: const Icon(Icons.face_retouching_natural, color: Color(0xFF918EF4)),
                filled: true, fillColor: const Color(0xFFF4F5F9),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF918EF4))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF918EF4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: () async {
                  String ad = nameCtrl.text.trim();
                  if (ad.isEmpty || ad.length < 3) return;
                  bool basariliMi = await _kullaniciRepo.kullaniciAdiGuncelle(_aktifKullaniciId ?? 0, ad);
                  if (basariliMi) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('aktifKullaniciAdi', ad);
                    setState(() { _kullaniciAdi = ad; });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) _ustMesajGoster(context, "Kullanıcı adın başarıyla güncellendi ✨", hata: false);
                  }
                },
                child: const Text("KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sifreDegistirSheet() {
    final TextEditingController eskiSifreCtrl = TextEditingController();
    final TextEditingController yeniSifreCtrl = TextEditingController();
    bool eskiGizli = true, yeniGizli = true;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(30, 20, 30, MediaQuery.of(ctx).viewInsets.bottom + 30),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Güvenli Şifre Değiştirme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
              const SizedBox(height: 20),
              TextField(
                controller: eskiSifreCtrl, obscureText: eskiGizli,
                decoration: InputDecoration(
                  labelText: "Mevcut Eski Şifreniz", prefixIcon: const Icon(Icons.lock_open_rounded, color: Colors.grey),
                  filled: true, fillColor: const Color(0xFFF4F5F9),
                  suffixIcon: IconButton(icon: Icon(eskiGizli ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setModalState(() => eskiGizli = !eskiGizli)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: yeniSifreCtrl, obscureText: yeniGizli,
                decoration: InputDecoration(
                  labelText: "Yeni Şifre (En az 6 Karakter)", prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF918EF4)),
                  filled: true, fillColor: const Color(0xFFF4F5F9),
                  suffixIcon: IconButton(icon: Icon(yeniGizli ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setModalState(() => yeniGizli = !yeniGizli)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF918EF4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: () async {
                    String eski = eskiSifreCtrl.text.trim(), yeni = yeniSifreCtrl.text.trim();
                    if (eski.isEmpty || yeni.length < 6) return;
                    bool eskiDogruMu = await _kullaniciRepo.sifreDogrula(_aktifKullaniciId ?? 0, eski);
                    if (!eskiDogruMu) { _ustMesajGoster(ctx, "Mevcut şifrenizi yanlış girdiniz! ❌"); return; }
                    bool guncellendi = await _kullaniciRepo.sifreGuncelle(_aktifKullaniciId ?? 0, yeni);
                    if (guncellendi) { if (ctx.mounted) Navigator.pop(ctx); if (context.mounted) _ustMesajGoster(context, "Şifreniz başarıyla değiştirildi 🔒", hata: false); }
                  },
                  child: const Text("ŞİFREYİ GÜNCELLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Color(0xFF918EF4)),
              title: const Text("Ayarlar", style: TextStyle(color: Color(0xFF4A4A4A), letterSpacing: 2, fontWeight: FontWeight.w300)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAyarKarti(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: _profilResmiSec,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF918EF4).withOpacity(0.2),
                                backgroundImage: _profilResmiYolu != null ? FileImage(File(_profilResmiYolu!)) : null,
                                child: _profilResmiYolu == null ? const Icon(Icons.person_rounded, color: Color(0xFF918EF4), size: 30) : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: const Color(0xFF918EF4), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                              )
                            ],
                          ),
                        ),
                        title: Text("Merhaba $_kullaniciAdi ✨", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A), fontSize: 16)),
                        subtitle: const Text("İsmini değiştirmek için dokun", style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                        onTap: _adiDuzenleSheet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildSectionTitle("Güvenlik Merkezim"),
                  _buildAyarKarti(
                    child: ListTile(
                      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_outline_rounded, color: Colors.redAccent)),
                      title: const Text("Şifre Değiştir", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                      subtitle: const Text("Eski şifre doğrulamalı koruma", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      onTap: _sifreDegistirSheet,
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildSectionTitle("Etkileşim Ayarları"),
                  _buildAyarKarti(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.notifications_active_outlined, color: Colors.orangeAccent)),
                          title: const Text("Günlük Hatırlatıcı", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                          subtitle: const Text("Bana günlük yazmayı hatırlat", style: TextStyle(fontSize: 12)),
                          trailing: Switch(
                            activeColor: const Color(0xFF918EF4),
                            activeTrackColor: const Color(0xFF918EF4).withOpacity(0.3),
                            value: _hatirlaticiAcik,
                            onChanged: (val) async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('hatirlaticiAcik', val);
                              setState(() { _hatirlaticiAcik = val; });
                              _gunlukBildirimiAyarla(val, _hatirlaticiSaati); // Bildirimi ayarla veya iptal et
                            },
                          ),
                        ),
                        if (_hatirlaticiAcik) ...[
                          const Divider(height: 1, indent: 60),
                          ListTile(
                            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.access_time_rounded, color: Colors.blueAccent)),
                            title: const Text("Hatırlatma Saati", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                            subtitle: Text('Her gün ${_hatirlaticiSaati.format(context)}', style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                            onTap: _saatSec,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildSectionTitle("Uygulama Araçları"),
                  _buildAyarKarti(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF80ED99).withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF5DD978))),
                          title: const Text("Anıları Aktar", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                          subtitle: const Text("Seçtiğin anıları PDF formatına dönüştür", style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          onTap: _seciliPdfAktarSheet,
                        ),
                        const Divider(height: 1, indent: 60),

                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF918EF4).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF918EF4))),
                          title: const Text("Kullanım Kılavuzu", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                          subtitle: const Text("Lavena nasıl kullanılır? (Video)", style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          onTap: _kullanimKilavuzuGoster,
                        ),
                        const Divider(height: 1, indent: 60),

                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.info_outline_rounded, color: Colors.blueGrey)),
                          title: const Text("Hakkında", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                          subtitle: const Text("Sürüm bilgisi ve geliştirici", style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          onTap: _hakkindaGoster,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Oturumu kapat butonu
                  GestureDetector(
                    onTap: () async {
                      final saglayici = context.read<GunlukGirisSaglayicisi>();
                      await saglayici.oturumuKapat();
                      if (context.mounted) Navigator.pushReplacementNamed(context, RotaIsimleri.acilisEkrani);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text("Oturumu Kapat", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
    );
  }

  Widget _buildAyarKarti({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: child,
      ),
    );
  }
}
class YoutubeOynaticiWidget extends StatefulWidget {
  final String videoUrl;
  const YoutubeOynaticiWidget({super.key, required this.videoUrl});

  @override
  State<YoutubeOynaticiWidget> createState() => _YoutubeOynaticiWidgetState();
}

class _YoutubeOynaticiWidgetState extends State<YoutubeOynaticiWidget> {
  late YoutubePlayerController _kontrolcu;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';

    _kontrolcu = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: false,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _kontrolcu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: YoutubePlayer(
        controller: _kontrolcu,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF918EF4),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF918EF4),
          handleColor: Color(0xFF918EF4),
          backgroundColor: Colors.white24,
        ),
      ),
    );
  }
}