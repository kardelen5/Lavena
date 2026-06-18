class KullaniciModeli {
  final int? id;
  final String kullaniciAdi;
  final String eposta;
  final String sifre;

  KullaniciModeli({
    this.id,
    required this.kullaniciAdi, // Başına 'this.' ekleyerek hatayı düzelttik
    required this.eposta,
    required this.sifre
  });

  // Veritabanına kaydetmek için Map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kullanici_adi': kullaniciAdi,
      'eposta': eposta,
      'sifre': sifre,
    };
  }

  // Veritabanından gelen veriyi nesneye dönüştürür
  factory KullaniciModeli.fromMap(Map<String, dynamic> map) {
    return KullaniciModeli(
      id: map['id'],
      kullaniciAdi: map['kullanici_adi'],
      eposta: map['eposta'],
      sifre: map['sifre'],
    );
  }
}