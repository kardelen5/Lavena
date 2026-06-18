import 'package:flutter/material.dart';

class StickerWidget extends StatefulWidget {
  final String icerik;
  final bool emojiMi;
  final double baslangicX;
  final double baslangicY;
  final double baslangicScale;
  final double baslangicRotation;
  final Function(double, double, double, double)? onKonumDegisti;
  final VoidCallback? silmeIslemi;

  const StickerWidget({
    super.key,
    required this.icerik,
    required this.emojiMi,
    this.baslangicX = 100.0,
    this.baslangicY = 100.0,
    this.baslangicScale = 1.0,
    this.baslangicRotation = 0.0,
    this.onKonumDegisti,
    this.silmeIslemi,
  });

  @override
  State<StickerWidget> createState() => _StickerWidgetState();
}

class _StickerWidgetState extends State<StickerWidget> {
  late double xPozisyonu;
  late double yPozisyonu;
  late double olcek;
  late double donusAcisi;


  double _baslangicOlcek = 1.0;
  double _baslangicDonusAcisi = 0.0;

  @override
  void initState() {
    super.initState();
    xPozisyonu = widget.baslangicX;
    yPozisyonu = widget.baslangicY;
    olcek = widget.baslangicScale;
    donusAcisi = widget.baslangicRotation;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: xPozisyonu,
      top: yPozisyonu,
      child: GestureDetector(
        onScaleStart: widget.onKonumDegisti != null
            ? (detay) {

          _baslangicOlcek = olcek;
          _baslangicDonusAcisi = donusAcisi;
        }
            : null,
        onScaleUpdate: widget.onKonumDegisti != null
            ? (detay) {
          setState(() {
            // focalPointDelta ile sürükleme yap
            xPozisyonu += detay.focalPointDelta.dx;
            yPozisyonu += detay.focalPointDelta.dy;
            // scale ve rotation ile parmak hareketleri algılanır
            olcek = _baslangicOlcek * detay.scale;
            donusAcisi = _baslangicDonusAcisi + detay.rotation;
          });

          widget.onKonumDegisti!(xPozisyonu, yPozisyonu, olcek, donusAcisi);
        }
            : null,

        child: Transform.rotate(
          angle: donusAcisi,
          child: Transform.scale(
            scale: olcek,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(widget.icerik, style: const TextStyle(fontSize: 45)),
                if (widget.silmeIslemi != null)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: GestureDetector(
                      onTap: widget.silmeIslemi,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}