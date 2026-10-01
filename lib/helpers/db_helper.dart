import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'toko_digital.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabel Produk Master[cite: 1]
        await db.execute('''
          CREATE TABLE master_products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price REAL
          )
        ''');

        // Tabel Keranjang Belanja[cite: 1]
        await db.execute('''
          CREATE TABLE local_cart (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            name TEXT,
            price REAL,
            quantity INTEGER
          )
        ''');

        // Isi data awal dengan Produk Novel
        await db.insert('master_products', {'name': 'Novel Laskar Pelangi', 'price': 85000});
        await db.insert('master_products', {'name': 'Novel Bumi (Tere Liye)', 'price': 95000});
        await db.insert('master_products', {'name': 'Novel Perahu Kertas', 'price': 78000});
        await db.insert('master_products', {'name': 'Novel Hujan (Tere Liye)', 'price': 88000});
        await db.insert('master_products', {'name': 'Novel Cantik Itu Luka', 'price': 110000});
        await db.insert('master_products', {'name': 'Novel Laut Bercerita', 'price': 105000});
      },
    );
  }
}