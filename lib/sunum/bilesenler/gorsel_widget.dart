import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GorselWidget extends StatefulWidget {
  final String resimYolu;
  final VoidCallback? silmeIslemi;

  const GorselWidget({
    super.key,
    required this.resimYolu,
    this.silmeIslemi,
  });

  @override
  State<GorselWidget> createState() => _GorselWidgetState();
}

class _GorselWidgetState extends State<GorselWidget> {
  late Offset _pozisyon;
  double _genislik = 150.0;
  double _baslangicGenisligi = 150.0;

  @override
  void initState() {
    super.initState();
    _pozisyon = Offset(50 + (DateTime.now().second % 5) * 15, 150 + (DateTime.now().second % 5) * 15);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pozisyon.dx,
      top: _pozisyon.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          _baslangicGenisligi = _genislik;
        },
        onScaleUpdate: (details) {
          setState(() {
            _pozisyon += details.focalPointDelta;
            _genislik = (_baslangicGenisligi * details.scale).clamp(80.0, 400.0);
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _genislik,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1, offset: Offset(2, 4))
                ],
              ),
              child: kIsWeb
                  ? Image.network(widget.resimYolu, fit: BoxFit.cover, errorBuilder: (c, e, s) => _hataGosterici())
                  : Image.file(File(widget.resimYolu), fit: BoxFit.cover, errorBuilder: (c, e, s) => _hataGosterici()),
            ),

            if (widget.silmeIslemi != null)
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: widget.silmeIslemi,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            Positioned(
              top: -10,
              right: -10,
              child: GestureDetector(
                onTap: widget.silmeIslemi,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hataGosterici() {
    return Container(
      height: _genislik, color: Colors.grey,
      child: const Icon(Icons.broken_image, color: Colors.white, size: 40),
    );
  }
}