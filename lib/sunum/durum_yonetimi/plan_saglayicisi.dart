import 'package:flutter/material.dart';
import '../../veri/depolar/plan_repository.dart';
import '../../veri/modeller/plan_modeli.dart';

class PlanSaglayicisi with ChangeNotifier {
  final PlanRepository _repo = PlanRepository();

  List<PlanModeli> _tumPlanlar = [];
  Map<String, List<PlanModeli>> _planlarMap = {};

  bool _yukleniyor = false;
  bool get yukleniyor => _yukleniyor;

  Map<String, List<PlanModeli>> get planlarMap => _planlarMap;

  Future<void> planlariYukle(int kullaniciId) async {
    _yukleniyor = true;
    notifyListeners();

    _tumPlanlar = await _repo.planlariGetir(kullaniciId);
    _mapOlustur();

    _yukleniyor = false;
    notifyListeners();
}

// planları tarihe göre gruplama
  void _mapOlustur() {
    _planlarMap.clear();
    for (var plan in _tumPlanlar) {
      if (_planlarMap[plan.tarih] == null) {
        _planlarMap[plan.tarih] = [];
      }
      _planlarMap[plan.tarih]!.add(plan);
    }
  }

  List<PlanModeli> getGunlukPlanlar(String tarih) {
    return _planlarMap[tarih] ?? [];
  }

  Future<void> planEkle(PlanModeli plan) async {
    bool basarili = await _repo.planEkle(plan);
    if (basarili) {
      await planlariYukle(plan.kullaniciId);
    }
  }

  Future<void> planSil(int planId, int kullaniciId) async {
    bool basarili = await _repo.planSil(planId);
    if (basarili) {
      await planlariYukle(kullaniciId);
    }
  }
}