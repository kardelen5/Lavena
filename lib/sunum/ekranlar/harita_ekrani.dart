import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../durum_yonetimi/gunluk_giris_saglayicisi.dart';
import '../../cekirdek/yonlendirme/rota_isimleri.dart';

class HaritaEkran extends StatefulWidget {
  const HaritaEkran({super.key});

  @override
  State<HaritaEkran> createState() => _HaritaEkranState();
}

class _HaritaEkranState extends State<HaritaEkran> {
  final MapController _mapController = MapController();
  int? _aktifKullaniciId;

  @override
  void initState() {
    super.initState();
    _kullaniciIdYukle();
  }

  Future<void> _kullaniciIdYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aktifKullaniciId = prefs.getInt('aktifKullaniciId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konum Geçmişi", style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.w300, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF918EF4)),
      ),
      body: Consumer<GunlukGirisSaglayicisi>(
        builder: (context, saglayici, child) {
          final konumluAnilar = saglayici.anilar.where((ani) {
            return ani.kullaniciId == _aktifKullaniciId && ani.enlem != null && ani.boylam != null;
          }).toList();

          return Stack(
            children: [
              // etkileşimli harita
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: konumluAnilar.isNotEmpty
                      ? LatLng(konumluAnilar.first.enlem!, konumluAnilar.first.boylam!)
                      : const LatLng(41.0082, 28.9784),
                  initialZoom: 12.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mobiluygulama.lavena',
                  ),
                  MarkerLayer(
                    markers: konumluAnilar.map((ani) {
                      return Marker(
                        point: LatLng(ani.enlem!, ani.boylam!),
                        width: 60, height: 60,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, RotaIsimleri.aniOkumaEkrani, arguments: ani),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                child: Text(ani.mekanIsmi ?? "Konum", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                              const Icon(Icons.location_on, color: Color(0xFF918EF4), size: 35),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),


              DraggableScrollableSheet(
                initialChildSize: 0.15,
                minChildSize: 0.15,
                maxChildSize: 0.7,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)],
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: konumluAnilar.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) return const _PanelBasligi();
                        if (konumluAnilar.isEmpty) return const Center(child: Text("Henüz anın yok."));
                        if (index > konumluAnilar.length) return const SizedBox(height: 50);

                        final ani = konumluAnilar[index - 1];
                        return ListTile(
                          onTap: () => Navigator.pushNamed(context, RotaIsimleri.aniOkumaEkrani, arguments: ani),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF918EF4).withOpacity(0.1),
                            child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF918EF4)),
                          ),
                          title: Text(
                              ani.mekanIsmi ?? "Bilinmeyen Mekan",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          subtitle: Text(
                              "Gidiş Tarihi: ${ani.tarih.substring(0, 10)}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.my_location, color: Color(0xFF918EF4)),
                            onPressed: () {
                              _mapController.move(LatLng(ani.enlem!, ani.boylam!), 15.0);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PanelBasligi extends StatelessWidget {
  const _PanelBasligi();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.explore_rounded, color: Color(0xFF918EF4)),
              SizedBox(width: 10),
              Text("Bulunduğun Konumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}