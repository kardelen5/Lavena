import 'package:flutter/material.dart';
import '../../veri/depolar/gunluk_giris_deposu_impl.dart';
import '../../veri/modeller/gunluk_giris_modeli.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GunlukGirisSaglayicisi with ChangeNotifier {
  final GunlukGirisDeposuImpl _depo = GunlukGirisDeposuImpl();

  List<GunlukGirisModeli> _anilar = [];
  List<GunlukGirisModeli> get anilar => _anilar;

  bool _yukleniyor = false;
  bool get yukleniyor => _yukleniyor;

  // Sadece giriş yapan kullanıcının anılarını veritabanından yükleyen fonksiyon
  Future<void> anilariYukle(int kullaniciId) async {
    _yukleniyor = true;
    notifyListeners();

    _anilar = await _depo.anilariListele(kullaniciId);

    _yukleniyor = false;
    notifyListeners();
  }

  Future<void> aniEkle(GunlukGirisModeli yeniAni) async {
    try {
      bool basarili = await _depo.aniKaydet(yeniAni);

      if (basarili) {
        if (yeniAni.kullaniciId != null) {
          await anilariYukle(yeniAni.kullaniciId!);
        }
      } else {
        throw Exception("Veritabanına kayıt işlemi başarısız.");
      }
    } catch (e) {
      print("Provider aniEkle Hatası: $e");
      rethrow;
    }
  }

  Future<void> aniGuncelle(GunlukGirisModeli guncelAni) async {
    try {
      bool basarili = await _depo.aniGuncelle(guncelAni);

      if (basarili) {
        if (guncelAni.kullaniciId != null) {
          await anilariYukle(guncelAni.kullaniciId!);
        }
      } else {
        throw Exception("Veritabanında güncelleme işlemi başarısız.");
      }
    } catch (e) {
      print(" aniGuncelle Hatası: $e");
      rethrow;
    }
  }

  Future<void> aniSil(int id) async {
    try {
      final dbSonuc = await _depo.aniSil(id);

      if (dbSonuc > 0) {
        _anilar.removeWhere((ani) => ani.id == id);
        notifyListeners();
      } else {
        throw Exception("Veritabanından silme işlemi başarısız.");
      }
    } catch (e) {
      print(" aniSil Hatası: $e");
      rethrow;
    }
  }

  Map<String, dynamic> haftalikAnalizHesapla(int kullaniciId) {
    final kullaniciAnilari = _anilar.where((ani) => ani.kullaniciId == kullaniciId).toList();

    if (kullaniciAnilari.isEmpty) {
      return {};
    }

    int toplamYildiz = kullaniciAnilari.length;

    Map<int, String> gunIsimleri = {
      1: "Pazartesi", 2: "Salı", 3: "Çarşamba", 4: "Perşembe",
      5: "Cuma", 6: "Cumartesi", 7: "Pazar"
    };
    Map<String, int> gunSayaclari = {};
    Map<String, int> sehirSayaclari = {};
    Map<int, int> renkSayaclari = {};

    double toplamAura = 0;
    int auraSayac = 0;

    for (var ani in kullaniciAnilari) {
      try {
        DateTime tarihObjesi = DateTime.parse(ani.tarih);
        String gunAdi = gunIsimleri[tarihObjesi.weekday] ?? "Bilinmiyor";
        gunSayaclari[gunAdi] = (gunSayaclari[gunAdi] ?? 0) + 1;
      } catch (_) {}

      if (ani.mekanIsmi != null && ani.mekanIsmi!.trim().isNotEmpty) {
        String sehir = ani.mekanIsmi!.split(',').last.trim();
        sehirSayaclari[sehir] = (sehirSayaclari[sehir] ?? 0) + 1;
      }

      if (ani.duygu != null) {
        double? auraDeger = double.tryParse(ani.duygu!);
        if (auraDeger != null) {
          toplamAura += auraDeger;
          auraSayac++;
        }
      }

      if (ani.arkaPlanKodu != null) {
        renkSayaclari[ani.arkaPlanKodu!] = (renkSayaclari[ani.arkaPlanKodu!] ?? 0) + 1;
      }
    }

    String enAktifGun = "Belirsiz";
    if (gunSayaclari.isNotEmpty) {
      enAktifGun = gunSayaclari.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    String favoriYer = "Veri Yok";
    if (sehirSayaclari.isNotEmpty) {
      favoriYer = sehirSayaclari.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    double ortalamaAura = auraSayac > 0 ? (toplamAura / auraSayac) : 50.0;

    int enSikRenk = renkSayaclari.isNotEmpty
        ? renkSayaclari.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 0xFF918EF4;

    return {
      'toplam': toplamYildiz,
      'enAktifGun': enAktifGun,
      'favoriYer': favoriYer,
      'ortalamaAura': ortalamaAura,
      'enSikRenk': enSikRenk,
    };
  }

  Future<void> oturumuKapat() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('oturumAcik');
    await prefs.remove('aktifKullaniciId');

    _anilar = [];
    notifyListeners();
  }
}