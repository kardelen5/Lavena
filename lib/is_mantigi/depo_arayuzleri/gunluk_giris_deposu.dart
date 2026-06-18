import '../../veri/modeller/gunluk_giris_modeli.dart';

abstract class GunlukGirisDeposu {
  Future<void> aniyiKaydet(GunlukGirisModeli giris);
  Future<List<GunlukGirisModeli>> tumAnilariGetir();
  Future<void> aniyiGuncelle(GunlukGirisModeli giris);
  Future<void> aniyiSil(int id);

  Future<List<GunlukGirisModeli>> kilitliNotlariGetir();
  Future<List<GunlukGirisModeli>> konumluAnilariGetir();
}