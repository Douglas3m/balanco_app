import 'package:sqflite/sqflite.dart';
import '../database/balanco_database.dart';
import '../models/setor.dart';

class SetorRepository {
  final BalancoDatabase _dbProvider;

  SetorRepository({BalancoDatabase? dbProvider})
      : _dbProvider = dbProvider ?? BalancoDatabase.instance;

  Future<List<Setor>> getAll() async {
    final db = await _dbProvider.database;
    final res = await db.rawQuery('''
      SELECT s.*, e.nome AS entidade_nome
      FROM setores s
      JOIN entidades e ON s.entidade_id = e.id
      ORDER BY s.nome ASC
    ''');
    return res.map((m) => Setor.fromMap(m)).toList();
  }

  Future<List<Setor>> getByEntidade(int entidadeId) async {
    final db = await _dbProvider.database;
    final res = await db.rawQuery('''
      SELECT s.*, e.nome AS entidade_nome
      FROM setores s
      JOIN entidades e ON s.entidade_id = e.id
      WHERE s.entidade_id = ?
      ORDER BY s.nome ASC
    ''', [entidadeId]);
    return res.map((m) => Setor.fromMap(m)).toList();
  }

  Future<Setor?> getById(int id) async {
    final db = await _dbProvider.database;
    final res = await db.rawQuery('''
      SELECT s.*, e.nome AS entidade_nome
      FROM setores s
      JOIN entidades e ON s.entidade_id = e.id
      WHERE s.id = ?
    ''', [id]);
    if (res.isEmpty) return null;
    return Setor.fromMap(res.first);
  }

  Future<int> insert(Setor setor) async {
    final db = await _dbProvider.database;
    return await db.insert(
      'setores',
      setor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> update(Setor setor) async {
    final db = await _dbProvider.database;
    return await db.update(
      'setores',
      setor.toMap(),
      where: 'id = ?',
      whereArgs: [setor.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbProvider.database;
    return await db.delete('setores', where: 'id = ?', whereArgs: [id]);
  }
}
