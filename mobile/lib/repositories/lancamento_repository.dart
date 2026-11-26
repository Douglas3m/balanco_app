import 'package:sqflite/sqflite.dart';
import '../database/balanco_database.dart';
import '../models/lancamento_item.dart';

class LancamentoRepository {
  final BalancoDatabase _dbProvider;

  LancamentoRepository({BalancoDatabase? dbProvider})
      : _dbProvider = dbProvider ?? BalancoDatabase.instance;

  Future<List<LancamentoItem>> getCompletos({
    int? entidadeId,
    int? setorId,
    String? query,
    String? orderBy,
  }) async {
    final db = await _dbProvider.database;

    String sql = '''
      SELECT 
        l.*,
        p.nome AS produto_nome,
        s.nome AS setor_nome,
        e.nome AS entidade_nome
      FROM lancamentos l
      JOIN produtos p ON l.produto_id = p.id
      JOIN setores s ON l.setor_id = s.id
      JOIN entidades e ON l.entidade_id = e.id
      WHERE 1=1
    ''';

    final List<dynamic> args = [];

    if (entidadeId != null) {
      sql += ' AND l.entidade_id = ?';
      args.add(entidadeId);
    }
    if (setorId != null) {
      sql += ' AND l.setor_id = ?';
      args.add(setorId);
    }
    if (query != null && query.trim().isNotEmpty) {
      sql += ' AND (p.nome LIKE ? OR l.plaqueta_codigo LIKE ? OR l.observacao LIKE ?)';
      final q = '%${query.trim()}%';
      args.addAll([q, q, q]);
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      sql += ' ORDER BY $orderBy';
    } else {
      sql += ' ORDER BY l.id DESC';
    }

    final res = await db.rawQuery(sql, args);
    return res.map((m) => LancamentoItem.fromMap(m)).toList();
  }

  Future<LancamentoItem?> getById(int id) async {
    final db = await _dbProvider.database;
    final res = await db.rawQuery('''
      SELECT 
        l.*,
        p.nome AS produto_nome,
        s.nome AS setor_nome,
        e.nome AS entidade_nome
      FROM lancamentos l
      JOIN produtos p ON l.produto_id = p.id
      JOIN setores s ON l.setor_id = s.id
      JOIN entidades e ON l.entidade_id = e.id
      WHERE l.id = ?
    ''', [id]);

    if (res.isEmpty) return null;
    return LancamentoItem.fromMap(res.first);
  }

  Future<int> insert(LancamentoItem item) async {
    if (item.quantidade <= 0) {
      throw ArgumentError('Quantidade deve ser estritamente maior que zero.');
    }
    final db = await _dbProvider.database;
    return await db.insert('lancamentos', item.toMap());
  }

  Future<int> update(LancamentoItem item) async {
    if (item.quantidade <= 0) {
      throw ArgumentError('Quantidade deve ser estritamente maior que zero.');
    }
    final db = await _dbProvider.database;
    return await db.update(
      'lancamentos',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbProvider.database;
    return await db.delete('lancamentos', where: 'id = ?', whereArgs: [id]);
  }
}
