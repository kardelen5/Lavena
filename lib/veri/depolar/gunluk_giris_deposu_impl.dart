import '../dao/gunluk_giris_dao.dart';
import '../modeller/gunluk_giris_modeli.dart';

class GunlukGirisDeposuImpl {
  final GunlukGirisDao _gunlukGirisDao = GunlukGirisDao();

  Future<bool> aniKaydet(GunlukGirisModeli ani) async {
    final id = await _gunlukGirisDao.aniEkle(ani);
    return id > 0;
  }

  Future<bool> aniGuncelle(GunlukGirisModeli ani) async {
    final guncellenenSatir = await _gunlukGirisDao.aniGuncelle(ani);
    return guncellenenSatir > 0;
  }

  Future<List<GunlukGirisModeli>> anilariListele(int kullaniciId) async {
    return await _gunlukGirisDao.kullaniciAnilariniGetir(kullaniciId);
  }

  Future<int> aniSil(int id) async {
    return await _gunlukGirisDao.aniSil(id);
  }
}