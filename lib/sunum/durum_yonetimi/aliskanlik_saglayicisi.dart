import 'package:flutter/material.dart';
import '../../veri/depolar/aliskanlik_repository.dart';
import '../../veri/modeller/aliskanlik_modeli.dart';

class AliskanlikSaglayicisi with ChangeNotifier {
  final AliskanlikRepository _repo = AliskanlikRepository();

  List<AliskanlikModeli> _aliskanliklar = [];
  List<AliskanlikModeli> get aliskanliklar => _aliskanliklar;

  bool _yukleniyor = false;
  bool get yukleniyor => _yukleniyor;

  Future<void> aliskanliklariYukle(int kullaniciId) async {
    _yukleniyor = true;
    notifyListeners();

    _aliskanliklar = await _repo.aliskanliklariGetir(kullaniciId);

    _yukleniyor = false;
    notifyListeners();
  }

  Future<void> aliskanlikEkle(AliskanlikModeli aliskanlik) async {
    bool basarili = await _repo.aliskanlikEkle(aliskanlik);
    if (basarili) {
      _aliskanliklar.add(aliskanlik);
      notifyListeners();
    }
  }

  Future<void> aliskanlikDurumGuncelle(String id, bool tamamlandi) async {
    bool basarili = await _repo.aliskanlikGuncelle(id, tamamlandi);
    if (basarili) {
      final index = _aliskanliklar.indexWhere((a) => a.id == id);
      if (index != -1) {
        _aliskanliklar[index].tamamlandi = tamamlandi;
        notifyListeners();
      }
    }
  }

  Future<void> aliskanlikSil(String id) async {
    bool basarili = await _repo.aliskanlikSil(id);
    if (basarili) {
      _aliskanliklar.removeWhere((a) => a.id == id);
      notifyListeners();
    }
  }
}