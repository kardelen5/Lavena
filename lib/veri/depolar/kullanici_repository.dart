import '../dao/kullanici_dao.dart';
import '../modeller/kullanici_modeli.dart';
import '../veritabani/veritabani_yardimcisi.dart';

class KullaniciRepository {
  final KullaniciDao _kullaniciDao = KullaniciDao();

  Future<bool> kayitOl(String ad, String eposta, String sifre) async {
    bool zatenVar = await _kullaniciDao.kullaniciVarMi(ad, eposta);
    if (zatenVar) {
      return false;
    }

    final yeniKullanici = KullaniciModeli(kullaniciAdi: ad, eposta: eposta, sifre: sifre);
    final sonuc = await _kullaniciDao.kullaniciKaydet(yeniKullanici);
    return sonuc > 0;
  }

  Future<KullaniciModeli?> girisYap(String ad, String sifre) async {
    return await _kullaniciDao.kullaniciKontrol(ad, sifre);
  }

  Future<bool> kullaniciGuncelle(int id, String yeniAd, String yeniSifre) async {
    try {
      final db = await VeritabaniYardimcisi.instance.database;
      int sonuc = await db.update(
        'kullanicilar',
        {'kullaniciAdi': yeniAd, 'sifre': yeniSifre},
        where: 'id = ?',
        whereArgs: [id],
      );
      return sonuc > 0;
    } catch (e) {
      print("Kullanıcı güncelleme hatası: $e");
      return false;
    }
  }

  Future<bool> sifreDogrula(int kullaniciId, String eskiSifre) async {
    try {
      final db = await VeritabaniYardimcisi.instance.database;
      final List<Map<String, dynamic>> sonuc = await db.query(
        'kullanicilar',
        where: 'id = ? AND sifre = ?',
        whereArgs: [kullaniciId, eskiSifre],
      );
      return sonuc.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sifreGuncelle(int kullaniciId, String yeniSifre) async {
    try {
      final db = await VeritabaniYardimcisi.instance.database;
      int sonuc = await db.update(
        'kullanicilar',
        {'sifre': yeniSifre},
        where: 'id = ?',
        whereArgs: [kullaniciId],
      );
      return sonuc > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> kullaniciAdiGuncelle(int kullaniciId, String yeniAd) async {
    final db = await VeritabaniYardimcisi.instance.database;

    try {
      final check = await db.query(
        'kullanicilar',
        where: 'kullanici_adi = ? AND id != ?',
        whereArgs: [yeniAd, kullaniciId],
      );

      if (check.isNotEmpty) {
        return false;
      }

      int etkilenenSatir = await db.update(
        'kullanicilar',
        {'kullanici_adi': yeniAd},
        where: 'id = ?',
        whereArgs: [kullaniciId],
      );

      return etkilenenSatir > 0;
    } catch (e) {
      print("Kullanıcı adı güncellenirken SQL hatası: $e");
      return false;
    }
  }

  Future<bool> profilResmiGuncelle(int kullaniciId, String resimYolu) async {
    final db = await VeritabaniYardimcisi.instance.database;
    try {
      int etkilenenSatir = await db.update(
        'kullanicilar',
        {'profil_resmi': resimYolu},
        where: 'id = ?',
        whereArgs: [kullaniciId],
      );
      return etkilenenSatir > 0;
    } catch (e) {
      print("Profil resmi güncellenirken SQL hatası: $e");
      return false;
    }
  }

  Future<KullaniciModeli?> kullaniciyiGetir(int id) async {
    return await _kullaniciDao.kullaniciyiGetir(id);
  }

}