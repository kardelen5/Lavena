class AliskanlikModeli {
  final String id;
  final int kullaniciId;
  final String baslik;
  bool tamamlandi;
  final int fosforluRenk;
  final String kategori;
  final String tarih;

  AliskanlikModeli({
    required this.id,
    required this.kullaniciId,
    required this.baslik,
    this.tamamlandi = false,
    required this.fosforluRenk,
    required this.kategori,
    required this.tarih,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kullanici_id': kullaniciId,
      'baslik': baslik,
      'tamamlandi': tamamlandi ? 1 : 0,
      'fosforlu_renk': fosforluRenk,
      'kategori': kategori,
      'tarih': tarih,
    };
  }

  factory AliskanlikModeli.fromMap(Map<String, dynamic> map) {
    return AliskanlikModeli(
      id: map['id'],
      kullaniciId: map['kullanici_id'],
      baslik: map['baslik'],
      tamamlandi: map['tamamlandi'] == 1,
      fosforluRenk: map['fosforlu_renk'],
      kategori: map['kategori'],
      tarih: map['tarih'],
    );
  }
}