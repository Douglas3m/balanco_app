import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/entidade.dart';
import '../models/setor.dart';
import '../models/produto.dart';
import '../models/lancamento_item.dart';

class BalancoDatabase {
  static final BalancoDatabase instance = BalancoDatabase._init();
  static Database? _database;

  BalancoDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('balanco_core.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String fullPath;
    if (kIsWeb) {
      fullPath = fileName;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appDir = await getApplicationSupportDirectory();
      fullPath = p.join(appDir.path, fileName);
    } else {
      final dbPath = await getDatabasesPath();
      fullPath = p.join(dbPath, fileName);
    }

    // Garante que o diretório exista
    final file = File(fullPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    return await openDatabase(
      fullPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabela de Entidades / Instituições
    await db.execute('''
      CREATE TABLE entidades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        cnpj_codigo TEXT,
        regime TEXT,
        observacao TEXT,
        criado_em TEXT NOT NULL
      );
    ''');

    // 2. Tabela de Setores Operacionais
    await db.execute('''
      CREATE TABLE setores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entidade_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        andar_bloco TEXT,
        responsavel TEXT,
        criado_em TEXT NOT NULL,
        UNIQUE(entidade_id, nome),
        FOREIGN KEY (entidade_id) REFERENCES entidades(id) ON DELETE CASCADE
      );
    ''');

    // 3. Tabela de Produtos / Objetos / Ativos
    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        categoria TEXT,
        criado_em TEXT NOT NULL
      );
    ''');

    // 4. Tabela de Lançamentos de Catalogação
    await db.execute('''
      CREATE TABLE lancamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plaqueta_codigo TEXT UNIQUE,
        produto_id INTEGER NOT NULL,
        setor_id INTEGER NOT NULL,
        entidade_id INTEGER NOT NULL,
        quantidade INTEGER NOT NULL CHECK(quantidade > 0),
        estado_conservacao TEXT DEFAULT 'Ótimo',
        foto_path TEXT,
        observacao TEXT,
        data_lancamento TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        FOREIGN KEY (produto_id) REFERENCES produtos(id),
        FOREIGN KEY (setor_id) REFERENCES setores(id),
        FOREIGN KEY (entidade_id) REFERENCES entidades(id)
      );
    ''');

    // Índices de otimização de busca e relatórios
    await db.execute('CREATE INDEX idx_lanc_entidade ON lancamentos(entidade_id);');
    await db.execute('CREATE INDEX idx_lanc_setor ON lancamentos(setor_id);');
    await db.execute('CREATE INDEX idx_lanc_produto ON lancamentos(produto_id);');
    await db.execute('CREATE INDEX idx_lanc_plaqueta ON lancamentos(plaqueta_codigo);');

    // Carga inicial amigável (Seed)
    final now = DateTime.now().toIso8601String();

    final ent1Id = await db.insert('entidades', {
      'nome': 'Prefeitura Municipal - Gabinete Executivo',
      'cnpj_codigo': '14.283.910/0001-44',
      'regime': 'Administração Direta',
      'observacao': 'Sede Principal e Órgão Central',
      'criado_em': now,
    });

    final ent2Id = await db.insert('entidades', {
      'nome': 'Secretaria Municipal de Educação & Cultura',
      'cnpj_codigo': '14.283.910/0002-25',
      'regime': 'Autarquia Municipal',
      'observacao': 'Polo Educacional Central',
      'criado_em': now,
    });

    final set1Id = await db.insert('setores', {
      'entidade_id': ent1Id,
      'nome': 'Depto. de TI e Servidores',
      'andar_bloco': 'Subsolo - Sala 02',
      'responsavel': 'Lucas S. Ferreira',
      'criado_em': now,
    });

    final set2Id = await db.insert('setores', {
      'entidade_id': ent1Id,
      'nome': 'Gabinete do Prefeito',
      'andar_bloco': '3º Andar - Sala 301',
      'responsavel': 'Mariana R. Costa',
      'criado_em': now,
    });

    await db.insert('setores', {
      'entidade_id': ent2Id,
      'nome': 'Laboratório de Informática',
      'andar_bloco': 'Bloco B - Térreo',
      'responsavel': 'Prof. Carlos Mendes',
      'criado_em': now,
    });

    final prod1Id = await db.insert('produtos', {
      'nome': 'Notebook Lenovo ThinkPad L14 Gen 4',
      'categoria': 'Equipamento TI',
      'criado_em': now,
    });

    final prod2Id = await db.insert('produtos', {
      'nome': 'Cadeira Giratória Ergonômica NR-17',
      'categoria': 'Mobiliário',
      'criado_em': now,
    });

    final prod3Id = await db.insert('produtos', {
      'nome': 'Mesa em L 140x140 com Gaveteiro',
      'categoria': 'Mobiliário',
      'criado_em': now,
    });

    // Lançamentos iniciais de demonstração
    await db.insert('lancamentos', {
      'plaqueta_codigo': 'PAT-2025-0012',
      'produto_id': prod1Id,
      'setor_id': set1Id,
      'entidade_id': ent1Id,
      'quantidade': 3,
      'estado_conservacao': 'Ótimo',
      'foto_path': '',
      'observacao': 'Com fontes originais 65W USB-C e mochilas corporativas.',
      'data_lancamento': '24/10/2025 14:15',
      'criado_em': now,
    });

    await db.insert('lancamentos', {
      'plaqueta_codigo': 'PAT-2025-0045',
      'produto_id': prod2Id,
      'setor_id': set2Id,
      'entidade_id': ent1Id,
      'quantidade': 6,
      'estado_conservacao': 'Bom',
      'foto_path': '',
      'observacao': 'Estofamento cinza chumbo com ajuste lombar e de braço.',
      'data_lancamento': '24/10/2025 15:30',
      'criado_em': now,
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
