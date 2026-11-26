import 'package:sqflite/sqflite.dart';
import '../database/balanco_database.dart';
import '../models/entidade.dart';

class EntidadeRepository {
  final BalancoDatabase _dbProvider;

  EntidadeRepository({BalancoDatabase? dbProvider})
      : _dbProvider = dbProvider ?? BalancoDatabase.instance;

  Future<List<Entidade>> getAll() async {
    final db = await _dbProvider.database;
    final res = await db.query('entidades', orderBy: 'nome ASC');
    return res.map((m) => Entidade.fromMap(m)).toList();
  }

  Future<Entidade?> getById(int id) async {
    final db = await _dbProvider.database;
    final res = await db.query('entidades', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return Entidade.fromMap(res.first);
  }

  Future<int> insert(Entidade entidade) async {
    final db = await _dbProvider.database;
    return await db.insert(
      'entidades',
      entidade.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> update(Entidade entidade) async {
    final db = await _dbProvider.database;
    return await db.update(
      'entidades',
      entidade.toMap(),
      where: 'id = ?',
      whereArgs: [entidade.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbProvider.database;
    return await db.delete('entidades', where: 'id = ?', whereArgs: [id]);
  }
}
