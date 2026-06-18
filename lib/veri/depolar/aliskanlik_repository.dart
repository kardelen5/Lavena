import '../dao/aliskanlik_dao.dart';
import '../modeller/aliskanlik_modeli.dart';

class AliskanlikRepository {
  final AliskanlikDao _dao = AliskanlikDao();

  Future<bool> aliskanlikEkle(AliskanlikModeli aliskanlik) async {
    final id = await _dao.aliskanlikEkle(aliskanlik);
    return id > 0;
  }

  Future<List<AliskanlikModeli>> aliskanliklariGetir(int kullaniciId) async {
    return await _dao.kullaniciAliskanliklariniGetir(kullaniciId);
  }

  Future<bool> aliskanlikGuncelle(String id, bool tamamlandi) async {
    final sonuc = await _dao.aliskanlikGuncelle(id, tamamlandi);
    return sonuc > 0;
  }

  Future<bool> aliskanlikSil(String id) async {
    final sonuc = await _dao.aliskanlikSil(id);
    return sonuc > 0;
  }
}