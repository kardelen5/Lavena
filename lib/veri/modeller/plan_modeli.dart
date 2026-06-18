class PlanModeli {
  final int? id;
  final int kullaniciId;
  final String baslik;
  final String? aciklama;
  final String tarih;
  final String saat;

  PlanModeli({
    this.id,
    required this.kullaniciId,
    required this.baslik,
    this.aciklama,
    required this.tarih,
    required this.saat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kullanici_id': kullaniciId,
      'baslik': baslik,
      'aciklama': aciklama,
      'tarih': tarih,
      'saat': saat,
    };
  }

  factory PlanModeli.fromMap(Map<String, dynamic> map) {
    return PlanModeli(
      id: map['id'],
      kullaniciId: map['kullanici_id'],
      baslik: map['baslik'],
      aciklama: map['aciklama'],
      tarih: map['tarih'],
      saat: map['saat'],
    );
  }
}