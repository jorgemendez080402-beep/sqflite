import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de SQLite para plataformas de escritorio (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SQLiteTestScreen(),
    );
  }
}

class SQLiteTestScreen extends StatefulWidget {
  const SQLiteTestScreen({super.key});

  @override
  State<SQLiteTestScreen> createState() => _SQLiteTestScreenState();
}

class _SQLiteTestScreenState extends State<SQLiteTestScreen> {
  List<SensorReading> _tempReadings = [];

  // Recargar lecturas guardadas
  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getReadingsByType('temperature');
    setState(() {
      _tempReadings = data;
    });
  }

  // Agregar una lectura individual
  Future<void> _addSingleReading() async {
    final reading = SensorReading(
      sensorType: 'temperature',
      value: 24.5 + (_tempReadings.length),
      timestamp: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.insertReading(reading);
    _refreshData();
  }

  // Agregar un lote de lecturas dentro de una Transacción
  Future<void> _addBatchReadings() async {
    final batch = [
      SensorReading(
        sensorType: 'temperature',
        value: 28.0,
        timestamp: DateTime.now().toIso8601String(),
      ),
      SensorReading(
        sensorType: 'temperature',
        value: 29.3,
        timestamp: DateTime.now().toIso8601String(),
      ),
      SensorReading(
        sensorType: 'humidity', // Esta no se mostrará al filtrar por 'temperature'
        value: 65.0,
        timestamp: DateTime.now().toIso8601String(),
      ),
    ];
    await DatabaseHelper.instance.insertBatchReadings(batch);
    _refreshData();
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba SQLite Local'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addSingleReading,
                  child: const Text('Insertar 1'),
                ),
                ElevatedButton(
                  onPressed: _addBatchReadings,
                  child: const Text('Insertar Lote'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tempReadings.isEmpty
                ? const Center(child: Text('No hay lecturas registradas.'))
                : ListView.builder(
                    itemCount: _tempReadings.length,
                    itemBuilder: (context, index) {
                      final item = _tempReadings[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${item.id}')),
                        title: Text('${item.sensorType}: ${item.value} °C'),
                        subtitle: Text(item.timestamp),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}