import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KonumOnizlemeWidget extends StatefulWidget {
  final double enlem;
  final double boylam;
  final String? mekanIsmi;
  final VoidCallback? silmeIslemi;

  const KonumOnizlemeWidget({
    super.key,
    required this.enlem,
    required this.boylam,
    this.mekanIsmi,
    this.silmeIslemi,
  });

  @override
  State<KonumOnizlemeWidget> createState() => _KonumOnizlemeWidgetState();
}

class _KonumOnizlemeWidgetState extends State<KonumOnizlemeWidget> {
  Offset _pozisyon = const Offset(15, 20);
  double _genislik = 330.0;
  double _yukseklik = 180.0;
  bool _haritaModu = true;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pozisyon.dx,
      top: _pozisyon.dy,
      child: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            if (details.pointerCount == 1) {
              _pozisyon += details.focalPointDelta;
            } else {
              _genislik = (_genislik * details.scale).clamp(100.0, 400.0);
              _yukseklik = (_yukseklik * details.scale).clamp(80.0, 350.0);
            }
          });
        },
        child: _haritaModu ? _buildTamHarita() : _buildKonumButonu(),
      ),
    );
  }

  Widget _buildTamHarita() {
    return Container(
      width: _genislik,
      height: _yukseklik,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(widget.enlem, widget.boylam),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(widget.enlem, widget.boylam),
                    child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                  ),
                ]),
              ],
            ),
          ),

          Positioned(
            bottom: 5, left: 5,
            child: _kontrolButonu(Icons.close_fullscreen, () => setState(() => _haritaModu = false)),
          ),

          if (widget.silmeIslemi != null)
            Positioned(
              top: 5, right: 5,
              child: _kontrolButonu(Icons.close, widget.silmeIslemi!, rengi: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildKonumButonu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _haritaModu = true),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Icon(Icons.location_on, color: Colors.blue.shade700, size: 30),
          ),
        ),

        if (widget.mekanIsmi != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.mekanIsmi!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),


        if (widget.silmeIslemi != null)
          GestureDetector(
            onTap: widget.silmeIslemi,
            child: const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.cancel, size: 18, color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _kontrolButonu(IconData icon, VoidCallback onTap, {Color rengi = Colors.black54}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Colors.white.withOpacity(0.8),
        child: Icon(icon, size: 14, color: rengi),
      ),
    );
  }
}