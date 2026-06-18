import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YaziStiliSecici extends StatelessWidget {
  final String mevcutFont;
  final Color mevcutRenk;
  final Function(String) onFontSecildi;
  final Function(Color) onRenkSecildi;

  const YaziStiliSecici({
    super.key,
    required this.mevcutFont,
    required this.mevcutRenk,
    required this.onFontSecildi,
    required this.onRenkSecildi,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> fontlar = [
      'Roboto', 'Caveat', 'Dancing Script', 'Special Elite', 'Indie Flower'
    ];


    final List<Color> yaziRenkleri = [
      const Color(0xFF2D2D2D),
      const Color(0xFF4E342E),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFC62828),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
      const Color(0xFF006064),
      const Color(0xFFBF360C),
      const Color(0xFF880E4F),
      const Color(0xFF1A237E),
      const Color(0xFF004D40),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Yazı Tipi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: fontlar.map((font) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(font, style: GoogleFonts.getFont(font, fontSize: 15)),
                  selected: mevcutFont == font,
                  selectedColor: Colors.blue.shade100,
                  onSelected: (_) => onFontSecildi(font),
                ),
              )).toList(),
            ),
          ),

          const Divider(height: 30),

          const Text("Mürekkep Rengi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 15),

          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: yaziRenkleri.map((renk) => GestureDetector(
              onTap: () => onRenkSecildi(renk),
              child: Container(
                width: 45, height: 45,
                decoration: BoxDecoration(
                  color: renk, shape: BoxShape.circle,
                  border: mevcutRenk == renk
                      ? Border.all(color: Colors.blueAccent, width: 3)
                      : Border.all(color: Colors.black12, width: 1),
                ),
                child: mevcutRenk == renk ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}