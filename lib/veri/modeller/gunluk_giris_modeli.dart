class GunlukGirisModeli {
  final int? id;
  final int? kullaniciId;
  String metin;
  final String tarih;
  String? kilitAcilmaTarihi;
  final String? duygu;
  final int? arkaPlanKodu;
  final String? gorselYolu;
  final String? sesYolu;
  final double? enlem;
  final double? boylam;
  final String? mekanIsmi;
  final String? kagitTuru;
  final int? yaziRengi;
  final String? yaziTipi;
  final double? gorselBoyutu;
  final String? stickerYolu;

  GunlukGirisModeli({
    this.id,
    this.kullaniciId,
    required this.metin,
    required this.tarih,
    this.kilitAcilmaTarihi,
    this.duygu,
    this.arkaPlanKodu,
    this.gorselYolu,
    this.sesYolu,
    this.enlem,
    this.boylam,
    this.mekanIsmi,
    this.kagitTuru,
    this.yaziRengi,
    this.yaziTipi,
    this.gorselBoyutu,
    this.stickerYolu,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kullanici_id': kullaniciId,
      'metin': metin,
      'tarih': tarih,
      'kilitAcilmaTarihi': kilitAcilmaTarihi,
      'duygu': duygu,
      'arkaPlanKodu': arkaPlanKodu,
      'gorselYolu': gorselYolu,
      'sesYolu': sesYolu,
      'enlem': enlem,
      'boylam': boylam,
      'mekanIsmi': mekanIsmi,
      'kagitTuru': kagitTuru,
      'yaziRengi': yaziRengi,
      'yaziTipi': yaziTipi,
      'gorselBoyutu': gorselBoyutu,
      'stickerYolu': stickerYolu,

    };
  }

  factory GunlukGirisModeli.fromMap(Map<String, dynamic> map) {
    return GunlukGirisModeli(
      id: map['id'],
      kullaniciId: map['kullanici_id'],
      metin: map['metin'] ?? '',
      tarih: map['tarih'] ?? '',
      kilitAcilmaTarihi: map['kilitAcilmaTarihi'],
      duygu: map['duygu'],
      arkaPlanKodu: map['arkaPlanKodu'],
      gorselYolu: map['gorselYolu'],
      sesYolu: map['sesYolu'],
      enlem: map['enlem'],
      boylam: map['boylam'],
      mekanIsmi: map['mekanIsmi'],
      kagitTuru: map['kagitTuru'],
      yaziRengi: map['yaziRengi'],
      yaziTipi: map['yaziTipi'],
      gorselBoyutu: map['gorselBoyutu'],
      stickerYolu: map['stickerYolu'],
    );
  }
}