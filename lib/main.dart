import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cekirdek/yonlendirme/rota_isimleri.dart';
import 'cekirdek/yonlendirme/rota_olusturucu.dart';
import 'sunum/durum_yonetimi/gunluk_giris_saglayicisi.dart';
import 'veri/veritabani/veritabani_yardimcisi.dart';
import 'cekirdek/servisler/bildirim_yardimcisi.dart';
import 'sunum/durum_yonetimi/aliskanlik_saglayicisi.dart';
import 'sunum/durum_yonetimi/plan_saglayicisi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BildirimYardimcisi.baslat();
  await BildirimYardimcisi.hatirlaticiOlustur();
  await VeritabaniYardimcisi.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GunlukGirisSaglayicisi()),
        ChangeNotifierProvider(create: (context) => AliskanlikSaglayicisi()),
        ChangeNotifierProvider(create: (context) => PlanSaglayicisi()),
      ],
      child: const LavenaUygulamasi(),
    ),
  );
}

class LavenaUygulamasi extends StatelessWidget {
  const LavenaUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lavena Dijital Ajanda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF918EF4)), // Lavena Moru teması
        useMaterial3: true,
      ),
      initialRoute: RotaIsimleri.acilisEkrani,
      onGenerateRoute: RotaOlusturucu.rotaUret,
    );
  }
}