import 'package:flutter/material.dart';
import 'rota_isimleri.dart';
import '../../veri/modeller/gunluk_giris_modeli.dart';
import '../../sunum/ekranlar/acilis_ekrani.dart';
import '../../sunum/ekranlar/ana_ekran.dart';
import '../../sunum/ekranlar/gunluk_giris_ekrani.dart';
import '../../sunum/ekranlar/harita_ekrani.dart';
import '../../sunum/ekranlar/zaman_kapsulu_listesi_ekrani.dart';
import '../../sunum/ekranlar/ani_okuma_ekrani.dart';
import '../../sunum/ekranlar/haftalik_ozet_ekrani.dart';
import '../../sunum/ekranlar/ayarlar_ekrani.dart';

class RotaOlusturucu {
  static Route<dynamic> rotaUret(RouteSettings ayarlar) {
    switch (ayarlar.name) {
      case RotaIsimleri.acilisEkrani:
        return MaterialPageRoute(builder: (_) => const AcilisEkrani());

      case RotaIsimleri.anaEkran:
        return MaterialPageRoute(builder: (_) => const AnaEkran());

      case RotaIsimleri.gunlukGirisEkrani:
        final mevcutAni = ayarlar.arguments as GunlukGirisModeli?;
        return MaterialPageRoute(
            builder: (_) => GunlukGirisEkrani(mevcutAni: mevcutAni));

      case RotaIsimleri.haritaEkrani:
        return MaterialPageRoute(builder: (_) => const HaritaEkran());

      case RotaIsimleri.zamanKapsuluListesiEkrani:
        return MaterialPageRoute(
            builder: (_) => const ZamanKapsuluListesiEkrani());

      case RotaIsimleri.haftalikOzetEkrani:
        return MaterialPageRoute(builder: (_) => const HaftalikOzetEkrani());

      case RotaIsimleri.ayarlarEkrani:
        return MaterialPageRoute(builder: (_) => const AyarlarEkran());

      case RotaIsimleri.aniOkumaEkrani:
        final ani = ayarlar.arguments as GunlukGirisModeli;
        return MaterialPageRoute(builder: (_) => AniOkumaEkrani(ani: ani));

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Hata: Rota bulunamadı!')),
          ),
        );
    }
  }
}