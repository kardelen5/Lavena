import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SesWidget extends StatefulWidget {
  final String sesYolu;
  final VoidCallback? silmeIslemi;
  final Color temaRengi;

  const SesWidget({
    super.key,
    required this.sesYolu,
    this.silmeIslemi,
    required this.temaRengi,
  });

  @override
  State<SesWidget> createState() => _SesWidgetState();
}

class _SesWidgetState extends State<SesWidget> {

  Offset _pozisyon = Offset(80 + (DateTime.now().second % 5) * 10, 200 + (DateTime.now().second % 5) * 20);
  bool _oynuyorMu = false;

  final AudioPlayer _sesOynatici = AudioPlayer();

  Duration _toplamSure = Duration.zero;
  Duration _gecenZaman = Duration.zero;

  @override
  void initState() {
    super.initState();
    _kaynagiHazirla();


    _sesOynatici.onPlayerComplete.listen((event) {
      if (mounted) setState(() {
        _oynuyorMu = false;
        _gecenZaman = Duration.zero;
      });
    });

    // Toplam süreyi hesapla
    _sesOynatici.onDurationChanged.listen((sure) {
      if (mounted) setState(() => _toplamSure = sure);
    });

    // Saniye saniye ilerlemeyi takip et
    _sesOynatici.onPositionChanged.listen((zaman) {
      if (mounted) setState(() => _gecenZaman = zaman);
    });
  }


  Future<void> _kaynagiHazirla() async {
    if (kIsWeb) {
      await _sesOynatici.setSource(UrlSource(widget.sesYolu));
    } else {
      await _sesOynatici.setSource(DeviceFileSource(widget.sesYolu));
    }
  }

  @override
  void dispose() {
    _sesOynatici.dispose();
    super.dispose();
  }

  void _oynatVeyaDurdur() async {
    if (_oynuyorMu) {
      await _sesOynatici.pause();
    } else {
      await _sesOynatici.resume();
    }
    setState(() => _oynuyorMu = !_oynuyorMu);
  }

  String _sureFormatla(Duration d) {
    String dakika = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String saniye = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$dakika:$saniye";
  }

  @override
  Widget build(BuildContext context) {
    Color cerceveRengi = widget.temaRengi == Colors.white ? Colors.grey.shade300 : widget.temaRengi;
    Color vurguRengi = widget.temaRengi == Colors.white
        ? Colors.blue.shade100
        : HSLColor.fromColor(widget.temaRengi).withLightness((HSLColor.fromColor(widget.temaRengi).lightness - 0.08).clamp(0.0, 1.0)).toColor();


    double hesaplananGenislik = (180.0 + (_toplamSure.inSeconds * 3.0)).clamp(180.0, 320.0);


    double ilerlemeYuzdesi = _toplamSure.inSeconds > 0
        ? _gecenZaman.inMilliseconds / _toplamSure.inMilliseconds
        : 0.0;

    return Positioned(
      left: _pozisyon.dx,
      top: _pozisyon.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _pozisyon += details.delta);
        },
        child: Container(
          width: hesaplananGenislik,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cerceveRengi, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _oynatVeyaDurdur,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: _oynuyorMu ? vurguRengi : cerceveRengi,
                  child: Icon(
                    _oynuyorMu ? Icons.pause : Icons.play_arrow,
                    color: widget.temaRengi == Colors.white ? Colors.blue.shade700 : Colors.black87,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // İlerleme çubuğu ve süre bilgisi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: ilerlemeYuzdesi,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(vurguRengi),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_sureFormatla(_gecenZaman), style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        Text(_sureFormatla(_toplamSure), style: const TextStyle(fontSize: 10, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),


              const SizedBox(width: 10),

              if (widget.silmeIslemi != null)
                GestureDetector(
                  onTap: widget.silmeIslemi,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}