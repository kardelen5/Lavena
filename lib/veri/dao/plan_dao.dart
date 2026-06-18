import '../modeller/plan_modeli.dart';
import '../veritabani/veritabani_yardimcisi.dart';

class PlanDao {
  Future<int> planEkle(PlanModeli plan) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.insert('planlar', plan.toMap());
  }

  Future<List<PlanModeli>> kullaniciPlanlariniGetir(int kullaniciId) async {
    final db = await VeritabaniYardimcisi.instance.database;
    final maps = await db.query(
      'planlar',
      where: 'kullanici_id = ?',
      whereArgs: [kullaniciId],
      orderBy: 'saat ASC',
    );
    return List.generate(maps.length, (i) => PlanModeli.fromMap(maps[i]));
  }

  Future<int> planSil(int id) async {
    final db = await VeritabaniYardimcisi.instance.database;
    return await db.delete(
      'planlar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}