import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Modelo de Entidad para las lecturas del sensor
class SensorReading {
  final int? id;
  final String sensorType; // Ej: 'temperature', 'humidity'
  final double value;
  final String timestamp;

  SensorReading({
    this.id,
    required this.sensorType,
    required this.value,
    required this.timestamp,
  });

  // Mapeo para convertir un objeto SensorReading en un Map compatible con SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensorType': sensorType,
      'value': value,
      'timestamp': timestamp,
    };
  }
}

// Helper para Base de Datos Relacional Local (Patrón Singleton)
class DatabaseHelper {
  // Única instancia de la clase
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter asíncrono para obtener o inicializar la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iot_local.db');
    return _database!;
  }

  // Inicialización de la base de datos local
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Habilitar integridad referencial (Claves Foráneas)
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  // Creación del esquema de la tabla 'readings'
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensorType TEXT NOT NULL,
        value REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // Inserción parametrizada para prevenir inyección SQL
  Future<int> insertReading(SensorReading reading) async {
    final db = await instance.database;
    return await db.insert('readings', reading.toMap());
  }

  // Inserción masiva/lote mediante una Transacción ACID (Rendimiento optimizado)
  Future<void> insertBatchReadings(List<SensorReading> readings) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      var batch = txn.batch();
      for (var reading in readings) {
        batch.insert('readings', reading.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  // Consulta parametrizada (Segura utilizando 'whereArgs')
  Future<List<SensorReading>> getReadingsByType(String type) async {
    final db = await instance.database;
    final result = await db.query(
      'readings',
      where: 'sensorType = ?',
      whereArgs: [type], // Evita ataques de inyección SQL
      orderBy: 'id DESC',
    );

    return result
        .map((json) => SensorReading(
              id: json['id'] as int?,
              sensorType: json['sensorType'] as String,
              value: json['value'] as double,
              timestamp: json['timestamp'] as String,
            ))
        .toList();
  }
}