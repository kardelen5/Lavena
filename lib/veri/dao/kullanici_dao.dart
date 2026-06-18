import '../modeller/kullanici_modeli.dart';
import '../veritabani/veritabani_yardimcisi.dart';

class KullaniciDao {
  Future<bool> kullaniciVarMi(String kullaniciAdi, String eposta) async {
    final db = await VeritabaniYardimcisi.instance.database;
    final sonuc = await db.query(
      'kullanicilar',
      where: 'kullanici_adi = ? OR eposta = ?',
      whereArgs: [kullaniciAdi, eposta],
    );
    return sonuc.isNotEmpty;
  }

  Future<int> kullaniciKaydet(KullaniciModeli kullanici) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.insert('kullanicilar', kullanici.toMap());
  }

  Future<KullaniciModeli?> kullaniciyiGetir(int id) async {
    final db = await VeritabaniYardimcisi.instance.database;
    final sonuclar = await db.query('kullanicilar', where: 'id = ?', whereArgs: [id]);
    if (sonuclar.isNotEmpty) return KullaniciModeli.fromMap(sonuclar.first);
    return null;
  }

  Future<KullaniciModeli?> kullaniciKontrol(String ad, String sifre) async {
    final db = await VeritabaniYardimcisi.instance.database;
    final sonuclar = await db.query(
      'kullanicilar',
      where: 'kullanici_adi = ? AND sifre = ?',
      whereArgs: [ad, sifre],
    );

    if (sonuclar.isNotEmpty) {
      return KullaniciModeli.fromMap(sonuclar.first);
    }
    return null;
  }
}