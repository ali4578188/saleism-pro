import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'saleism_pro.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'staff',
        pin TEXT NOT NULL,
        fingerprint_enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Companies table
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        address TEXT,
        opening_balance REAL DEFAULT 0,
        credit_limit REAL DEFAULT 0,
        current_credit REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        company_id INTEGER,
        category TEXT,
        barcode TEXT UNIQUE,
        mrp REAL DEFAULT 0,
        purchase_rate REAL DEFAULT 0,
        sale_rate REAL DEFAULT 0,
        carton_qty INTEGER DEFAULT 0,
        box_qty INTEGER DEFAULT 0,
        pieces_per_box INTEGER DEFAULT 1,
        min_stock_level INTEGER DEFAULT 10,
        stock_cartons INTEGER DEFAULT 0,
        stock_boxes INTEGER DEFAULT 0,
        stock_pieces INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (company_id) REFERENCES companies(id)
      )
    ''');

    // Purchases table
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        company_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        total_amount REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        payment_status TEXT DEFAULT 'unpaid',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (company_id) REFERENCES companies(id)
      )
    ''');

    // Purchase items table
    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        purchase_rate REAL DEFAULT 0,
        cartons INTEGER DEFAULT 0,
        boxes INTEGER DEFAULT 0,
        pieces INTEGER DEFAULT 0,
        total_pieces INTEGER DEFAULT 0,
        total_amount REAL DEFAULT 0,
        FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        company_id INTEGER,
        date TEXT NOT NULL,
        total_amount REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        final_amount REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (company_id) REFERENCES companies(id)
      )
    ''');

    // Sale items table
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        sale_rate REAL DEFAULT 0,
        purchase_rate REAL DEFAULT 0,
        cartons INTEGER DEFAULT 0,
        boxes INTEGER DEFAULT 0,
        pieces INTEGER DEFAULT 0,
        total_pieces INTEGER DEFAULT 0,
        total_amount REAL DEFAULT 0,
        profit REAL DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Ledger table
    await db.execute('''
      CREATE TABLE ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        reference_id INTEGER,
        reference_type TEXT,
        debit REAL DEFAULT 0,
        credit REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (company_id) REFERENCES companies(id)
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        sale_id INTEGER,
        purchase_id INTEGER,
        date TEXT NOT NULL,
        amount REAL DEFAULT 0,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (company_id) REFERENCES companies(id)
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default admin
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'name': 'Admin',
      'role': 'admin',
      'pin': '1234',
      'fingerprint_enabled': 0,
      'created_at': now,
      'updated_at': now,
    });

    // Insert default settings
    await db.insert('settings', {'key': 'company_name', 'value': 'My Wholesale', 'updated_at': now});
    await db.insert('settings', {'key': 'currency', 'value': 'PKR', 'updated_at': now});
    await db.insert('settings', {'key': 'auto_backup', 'value': 'true', 'updated_at': now});
    await db.insert('settings', {'key': 'dark_mode', 'value': 'true', 'updated_at': now});
  }

  // ─── COMPANIES ───────────────────────────────────────────────────────────────

  Future<int> insertCompany(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    return await db.insert('companies', data);
  }

  Future<List<Map<String, dynamic>>> getCompanies() async {
    final db = await database;
    return await db.query('companies', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getCompany(int id) async {
    final db = await database;
    final rows = await db.query('companies', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> updateCompany(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('companies', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCompany(int id) async {
    final db = await database;
    return await db.delete('companies', where: 'id = ?', whereArgs: [id]);
  }

  // ─── PRODUCTS ────────────────────────────────────────────────────────────────

  Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    return await db.insert('products', data);
  }

  Future<List<Map<String, dynamic>>> getProducts({String? search, int? companyId, String? category}) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      conditions.add('(p.name LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    if (companyId != null) {
      conditions.add('p.company_id = ?');
      args.add(companyId);
    }
    if (category != null && category.isNotEmpty) {
      conditions.add('p.category = ?');
      args.add(category);
    }
    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    return await db.rawQuery('''
      SELECT p.*, c.name as company_name
      FROM products p
      LEFT JOIN companies c ON p.company_id = c.id
      $where
      ORDER BY p.name ASC
    ''', args);
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, c.name as company_name,
        (p.stock_cartons * p.carton_qty + p.stock_boxes * p.pieces_per_box + p.stock_pieces) as total_pieces
      FROM products p
      LEFT JOIN companies c ON p.company_id = c.id
      WHERE (p.stock_cartons * p.carton_qty + p.stock_boxes * p.pieces_per_box + p.stock_pieces) <= p.min_stock_level
      ORDER BY total_pieces ASC
    ''');
  }

  Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('products', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProductStock(int productId, int cartonsDelta, int boxesDelta, int piecesDelta) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE products SET
        stock_cartons = stock_cartons + ?,
        stock_boxes = stock_boxes + ?,
        stock_pieces = stock_pieces + ?,
        updated_at = ?
      WHERE id = ?
    ''', [cartonsDelta, boxesDelta, piecesDelta, DateTime.now().toIso8601String(), productId]);
  }

  // ─── PURCHASES ───────────────────────────────────────────────────────────────

  Future<int> insertPurchase(Map<String, dynamic> purchaseData, List<Map<String, dynamic>> items) async {
    final db = await database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      purchaseData['created_at'] = now;
      purchaseData['updated_at'] = now;
      final purchaseId = await txn.insert('purchases', purchaseData);

      for (final item in items) {
        item['purchase_id'] = purchaseId;
        await txn.insert('purchase_items', item);
        // Update stock
        await txn.rawUpdate('''
          UPDATE products SET
            stock_cartons = stock_cartons + ?,
            stock_boxes = stock_boxes + ?,
            stock_pieces = stock_pieces + ?,
            updated_at = ?
          WHERE id = ?
        ''', [item['cartons'], item['boxes'], item['pieces'], now, item['product_id']]);
      }

      // Update company credit
      await txn.rawUpdate('''
        UPDATE companies SET
          current_credit = current_credit + ?,
          updated_at = ?
        WHERE id = ?
      ''', [purchaseData['total_amount'] - (purchaseData['paid_amount'] ?? 0), now, purchaseData['company_id']]);

      // Add ledger entry
      await txn.insert('ledger', {
        'company_id': purchaseData['company_id'],
        'date': purchaseData['date'],
        'type': 'purchase',
        'reference_id': purchaseId,
        'reference_type': 'purchase',
        'debit': purchaseData['total_amount'],
        'credit': purchaseData['paid_amount'] ?? 0,
        'balance': purchaseData['total_amount'] - (purchaseData['paid_amount'] ?? 0),
        'description': 'Purchase Invoice #${purchaseData['invoice_number']}',
        'created_at': now,
      });

      return purchaseId;
    });
  }

  Future<List<Map<String, dynamic>>> getPurchases({String? dateFrom, String? dateTo, int? companyId}) async {
    final db = await database;
    final conditions = <String>['1=1'];
    final args = <dynamic>[];
    if (dateFrom != null) { conditions.add('p.date >= ?'); args.add(dateFrom); }
    if (dateTo != null) { conditions.add('p.date <= ?'); args.add(dateTo); }
    if (companyId != null) { conditions.add('p.company_id = ?'); args.add(companyId); }
    return await db.rawQuery('''
      SELECT p.*, c.name as company_name
      FROM purchases p
      LEFT JOIN companies c ON p.company_id = c.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY p.date DESC, p.id DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getPurchaseItems(int purchaseId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT pi.*, pr.name as product_name, pr.carton_qty, pr.pieces_per_box
      FROM purchase_items pi
      JOIN products pr ON pi.product_id = pr.id
      WHERE pi.purchase_id = ?
    ''', [purchaseId]);
  }

  // ─── SALES ───────────────────────────────────────────────────────────────────

  Future<int> insertSale(Map<String, dynamic> saleData, List<Map<String, dynamic>> items) async {
    final db = await database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      saleData['created_at'] = now;
      saleData['updated_at'] = now;
      final saleId = await txn.insert('sales', saleData);

      for (final item in items) {
        item['sale_id'] = saleId;
        await txn.insert('sale_items', item);
        // Decrease stock
        await txn.rawUpdate('''
          UPDATE products SET
            stock_cartons = MAX(0, stock_cartons - ?),
            stock_boxes = MAX(0, stock_boxes - ?),
            stock_pieces = MAX(0, stock_pieces - ?),
            updated_at = ?
          WHERE id = ?
        ''', [item['cartons'], item['boxes'], item['pieces'], now, item['product_id']]);
      }

      // Update company credit if credit sale
      if (saleData['payment_method'] == 'credit' && saleData['company_id'] != null) {
        final unpaid = saleData['final_amount'] - (saleData['paid_amount'] ?? 0);
        await txn.rawUpdate('''
          UPDATE companies SET
            current_credit = current_credit + ?,
            updated_at = ?
          WHERE id = ?
        ''', [unpaid, now, saleData['company_id']]);
      }

      return saleId;
    });
  }

  Future<List<Map<String, dynamic>>> getSales({String? dateFrom, String? dateTo, int? companyId, String? customerName}) async {
    final db = await database;
    final conditions = <String>['1=1'];
    final args = <dynamic>[];
    if (dateFrom != null) { conditions.add('s.date >= ?'); args.add(dateFrom); }
    if (dateTo != null) { conditions.add('s.date <= ?'); args.add(dateTo); }
    if (companyId != null) { conditions.add('s.company_id = ?'); args.add(companyId); }
    if (customerName != null && customerName.isNotEmpty) {
      conditions.add('s.customer_name LIKE ?');
      args.add('%$customerName%');
    }
    return await db.rawQuery('''
      SELECT s.*, c.name as company_name
      FROM sales s
      LEFT JOIN companies c ON s.company_id = c.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY s.date DESC, s.id DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT si.*, pr.name as product_name, pr.carton_qty, pr.pieces_per_box
      FROM sale_items si
      JOIN products pr ON si.product_id = pr.id
      WHERE si.sale_id = ?
    ''', [saleId]);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final stockValue = await db.rawQuery('SELECT SUM(stock_cartons * carton_qty * purchase_rate + stock_boxes * pieces_per_box * purchase_rate + stock_pieces * purchase_rate) as val FROM products');
    final totalPurchase = await db.rawQuery('SELECT SUM(total_amount) as val FROM purchases');
    final totalSales = await db.rawQuery('SELECT SUM(final_amount) as val FROM sales');
    final todaySales = await db.rawQuery("SELECT SUM(final_amount) as val FROM sales WHERE date LIKE '$today%'");
    final totalProfit = await db.rawQuery('SELECT SUM(profit) as val FROM sale_items');
    final lowStock = await db.rawQuery('SELECT COUNT(*) as val FROM products WHERE (stock_cartons * carton_qty + stock_boxes * pieces_per_box + stock_pieces) <= min_stock_level');
    final outstandingCredit = await db.rawQuery('SELECT SUM(current_credit) as val FROM companies');
    final totalCompanies = await db.rawQuery('SELECT COUNT(*) as val FROM companies');

    return {
      'stock_value': stockValue.first['val'] ?? 0,
      'total_purchase': totalPurchase.first['val'] ?? 0,
      'total_sales': totalSales.first['val'] ?? 0,
      'today_sales': todaySales.first['val'] ?? 0,
      'total_profit': totalProfit.first['val'] ?? 0,
      'low_stock': lowStock.first['val'] ?? 0,
      'outstanding_credit': outstandingCredit.first['val'] ?? 0,
      'total_companies': totalCompanies.first['val'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getProfitReport({String? dateFrom, String? dateTo, String period = 'daily'}) async {
    final db = await database;
    final conditions = <String>['1=1'];
    final args = <dynamic>[];
    if (dateFrom != null) { conditions.add('s.date >= ?'); args.add(dateFrom); }
    if (dateTo != null) { conditions.add('s.date <= ?'); args.add(dateTo); }
    final groupBy = period == 'monthly' ? "strftime('%Y-%m', s.date)" : "strftime('%Y-%m-%d', s.date)";
    return await db.rawQuery('''
      SELECT $groupBy as period,
        SUM(s.final_amount) as total_sales,
        SUM(si.profit) as total_profit,
        SUM(s.final_amount - si.profit) as total_cost,
        CASE WHEN SUM(s.final_amount) > 0 THEN ROUND(SUM(si.profit) * 100.0 / SUM(s.final_amount), 2) ELSE 0 END as margin_pct
      FROM sales s
      JOIN sale_items si ON si.sale_id = s.id
      WHERE ${conditions.join(' AND ')}
      GROUP BY $groupBy
      ORDER BY period DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getLedger(int companyId) async {
    final db = await database;
    return await db.query('ledger', where: 'company_id = ?', whereArgs: [companyId], orderBy: 'date DESC, id DESC');
  }

  // ─── SETTINGS ────────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── BACKUP ──────────────────────────────────────────────────────────────────

  Future<String> backupDatabase() async {
    final db = await database;
    await db.close();
    _database = null;

    final dbPath = await getDatabasesPath();
    final sourcePath = join(dbPath, 'saleism_pro.db');
    final extDir = await getExternalStorageDirectory();
    final backupDir = Directory('${extDir!.path}/SaleismProBackup');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final backupPath = '${backupDir.path}/backup_$timestamp.db';
    await File(sourcePath).copy(backupPath);

    _database = await _initDatabase();
    return backupPath;
  }

  Future<void> restoreDatabase(String backupPath) async {
    final db = await database;
    await db.close();
    _database = null;

    final dbPath = await getDatabasesPath();
    final targetPath = join(dbPath, 'saleism_pro.db');
    await File(backupPath).copy(targetPath);
    _database = await _initDatabase();
  }

  Future<String> generateInvoiceNumber(String prefix) async {
    final db = await database;
    final count = await db.rawQuery("SELECT COUNT(*) as cnt FROM ${prefix == 'INV' ? 'sales' : 'purchases'}");
    final n = (count.first['cnt'] as int) + 1;
    return '$prefix${n.toString().padLeft(6, '0')}';
  }

  // ─── USERS ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> validateUser(String pin) async {
    final db = await database;
    final rows = await db.query('users', where: 'pin = ?', whereArgs: [pin]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'name ASC');
  }

  Future<int> insertUser(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    return await db.insert('users', data);
  }

  Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
