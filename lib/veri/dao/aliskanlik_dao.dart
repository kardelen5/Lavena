import '../modeller/aliskanlik_modeli.dart';
import '../veritabani/veritabani_yardimcisi.dart';

class AliskanlikDao {

  Future<int> aliskanlikEkle(AliskanlikModeli aliskanlik) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.insert('aliskanliklar', aliskanlik.toMap());
  }

  Future<List<AliskanlikModeli>> kullaniciAliskanliklariniGetir(int kullaniciId) async {
    final db = await VeritabaniYardimcisi.instance.database;
    final maps = await db.query(
      'aliskanliklar',
      where: 'kullanici_id = ?',
      whereArgs: [kullaniciId],
    );
    return List.generate(maps.length, (i) => AliskanlikModeli.fromMap(maps[i]));
  }

  Future<int> aliskanlikGuncelle(String id, bool tamamlandi) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.update(
      'aliskanliklar',
      {'tamamlandi': tamamlandi ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> aliskanlikSil(String id) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.delete(
      'aliskanliklar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}