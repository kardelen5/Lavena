import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class KonumSeciciWidget extends StatefulWidget {
  final LatLng baslangicKonumu;
  const KonumSeciciWidget({super.key, required this.baslangicKonumu});

  @override
  State<KonumSeciciWidget> createState() => _KonumSeciciWidgetState();
}

class _KonumSeciciWidgetState extends State<KonumSeciciWidget> {
  late LatLng _secilenKonum;
  final MapController _mapController = MapController();
  final TextEditingController _aramaKontrolcusu = TextEditingController();
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _secilenKonum = widget.baslangicKonumu;
  }

  Future<void> _konumAra() async {
    if (_aramaKontrolcusu.text.isEmpty) return;

    setState(() => _yukleniyor = true);

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${_aramaKontrolcusu.text}&format=json&limit=1');

      final response = await http.get(url, headers: {
        'User-Agent': 'Memoire_App_Student_Project'
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lon = double.parse(data[0]['lon']);
          final String tamAdres = data[0]['display_name'];
          final String kisaIsim = tamAdres.split(',')[0];

    setState(() {
    _secilenKonum = LatLng(lat, lon);

    _aramaKontrolcusu.text = kisaIsim;
    _mapController.move(_secilenKonum, 15.0);
    });
    } else {
    _mesajGoster("Mekan bulunamadı.");
    }
    }
    } catch (e) {
    _mesajGoster("Arama sırasında bir hata oluştu.");
    } finally {
    setState(() => _yukleniyor = false);
    }
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konum Seç", style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'konum': _secilenKonum,
              'isim': _aramaKontrolcusu.text.isEmpty ? "Seçilen Konum" : _aramaKontrolcusu.text,
            }),
            child: const Text("Tamam"),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _secilenKonum,
              initialZoom: 15.0,
              onTap: (tapPosition, point) => setState(() => _secilenKonum = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mobiluygulama.memoire',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _secilenKonum,
                  width: 40, height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ]),
            ],
          ),

          Positioned(
            top: 10, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: TextField(
                controller: _aramaKontrolcusu,
                decoration: InputDecoration(
                  hintText: "Şehir veya mekan ara...",
                  border: InputBorder.none,
                  suffixIcon: _yukleniyor
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(icon: const Icon(Icons.search), onPressed: _konumAra),
                ),
                onSubmitted: (_) => _konumAra(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}