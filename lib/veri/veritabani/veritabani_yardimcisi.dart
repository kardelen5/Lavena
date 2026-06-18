import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VeritabaniYardimcisi {
  static final VeritabaniYardimcisi instance = VeritabaniYardimcisi._init();
  static Database? _database;

  VeritabaniYardimcisi._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lavena_veritabani.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE kullanicilar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_adi TEXT NOT NULL UNIQUE,
        eposta TEXT NOT NULL UNIQUE,
        sifre TEXT NOT NULL,
        profil_resmi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE gunluk_girisleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_id INTEGER NOT NULL,
        metin TEXT NOT NULL,
        tarih TEXT NOT NULL,
        kilitAcilmaTarihi TEXT,
        duygu TEXT,
        arkaPlanKodu INTEGER,
        gorselYolu TEXT,
        sesYolu TEXT,
        enlem REAL,
        boylam REAL,
        mekanIsmi TEXT,
        kagitTuru TEXT,
        yaziRengi INTEGER,
        yaziTipi TEXT,
        gorselBoyutu REAL,
        stickerYolu TEXT, 
        FOREIGN KEY (kullanici_id) REFERENCES kullanicilar (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE planlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_id INTEGER NOT NULL,
        baslik TEXT NOT NULL,
        aciklama TEXT,
        tarih TEXT NOT NULL,
        saat TEXT NOT NULL,
        FOREIGN KEY (kullanici_id) REFERENCES kullanicilar (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE aliskanliklar (
        id TEXT PRIMARY KEY,
        kullanici_id INTEGER NOT NULL,
        baslik TEXT NOT NULL,
        tamamlandi INTEGER NOT NULL DEFAULT 0, -- 0: false, 1: true
        fosforlu_renk INTEGER NOT NULL,
        kategori TEXT NOT NULL,                -- Rutin, Kitaplar, Filmler, Mekanlar
        tarih TEXT NOT NULL,                   -- yyyy-MM-dd formatında tarihsel geçmiş analizi için
        FOREIGN KEY (kullanici_id) REFERENCES kullanicilar (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_kullanici_adi ON kullanicilar (kullanici_adi)');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_eposta ON kullanicilar (eposta)');
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE gunluk_girisleri ADD COLUMN stickerYolu TEXT');
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE kullanicilar ADD COLUMN profil_resmi TEXT');
      } catch (_) {}
    }

    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS planlar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kullanici_id INTEGER NOT NULL,
            baslik TEXT NOT NULL,
            aciklama TEXT,
            tarih TEXT NOT NULL,
            saat TEXT NOT NULL,
            FOREIGN KEY (kullanici_id) REFERENCES kullanicilar (id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS aliskanliklar (
            id TEXT PRIMARY KEY,
            kullanici_id INTEGER NOT NULL,
            baslik TEXT NOT NULL,
            tamamlandi INTEGER NOT NULL DEFAULT 0,
            fosforlu_renk INTEGER NOT NULL,
            kategori TEXT NOT NULL,
            tarih TEXT NOT NULL,
            FOREIGN KEY (kullanici_id) REFERENCES kullanicilar (id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {
      }
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}