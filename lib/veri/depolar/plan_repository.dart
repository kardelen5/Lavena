import '../dao/plan_dao.dart';
import '../modeller/plan_modeli.dart';

class PlanRepository {
  final PlanDao _dao = PlanDao();

  Future<bool> planEkle(PlanModeli plan) async {
    final id = await _dao.planEkle(plan);
    return id > 0;
  }

  Future<List<PlanModeli>> planlariGetir(int kullaniciId) async {
    return await _dao.kullaniciPlanlariniGetir(kullaniciId);
  }

  Future<bool> planSil(int id) async {
    final sonuc = await _dao.planSil(id);
    return sonuc > 0;
  }
}