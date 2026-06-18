import 'package:sqflite/sqflite.dart';
import '../modeller/gunluk_giris_modeli.dart';
import '../veritabani/veritabani_yardimcisi.dart';

class GunlukGirisDao {
  Future<int> aniEkle(GunlukGirisModeli ani) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.insert('gunluk_girisleri', ani.toMap());
  }

  Future<int> aniGuncelle(GunlukGirisModeli ani) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.update(
      'gunluk_girisleri',
      ani.toMap(),
      where: 'id = ?',
      whereArgs: [ani.id],
    );
  }

  Future<List<GunlukGirisModeli>> kullaniciAnilariniGetir(int kullaniciId) async {
    final db = await VeritabaniYardimcisi.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'gunluk_girisleri',
      where: 'kullanici_id = ?',
      whereArgs: [kullaniciId],
      orderBy: 'tarih DESC',
    );

    return List.generate(maps.length, (i) => GunlukGirisModeli.fromMap(maps[i]));
  }

  Future<int> aniSil(int id) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.delete(
      'gunluk_girisleri',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> tumAnilariSil() async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.delete('gunluk_girisleri');
  }
}