import 'package:sqflite/sqflite.dart';
import '../database/balanco_database.dart';
import '../models/produto.dart';

class ProdutoRepository {
  final BalancoDatabase _dbProvider;

  ProdutoRepository({BalancoDatabase? dbProvider})
      : _dbProvider = dbProvider ?? BalancoDatabase.instance;

  Future<List<Produto>> getAll() async {
    final db = await _dbProvider.database;
    final res = await db.query('produtos', orderBy: 'nome ASC');
    return res.map((m) => Produto.fromMap(m)).toList();
  }

  Future<Produto?> getById(int id) async {
    final db = await _dbProvider.database;
    final res = await db.query('produtos', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return Produto.fromMap(res.first);
  }

  Future<int> getOrCreateByName(String nome, {String categoria = 'Geral'}) async {
    final db = await _dbProvider.database;
    final trimmed = nome.trim();
    final res = await db.query('produtos', where: 'nome = ?', whereArgs: [trimmed]);
    if (res.isNotEmpty) {
      return res.first['id'] as int;
    }
    return await db.insert('produtos', {
      'nome': trimmed,
      'categoria': categoria,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<int> insert(Produto produto) async {
    final db = await _dbProvider.database;
    return await db.insert(
      'produtos',
      produto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> update(Produto produto) async {
    final db = await _dbProvider.database;
    return await db.update(
      'produtos',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbProvider.database;
    return await db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }
}
