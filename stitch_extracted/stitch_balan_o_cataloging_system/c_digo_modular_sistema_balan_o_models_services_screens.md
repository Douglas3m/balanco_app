# GUIA DE ARQUITETURA MODULAR — SISTEMA BALANÇO (FLUTTER)

Este documento contém a separação arquitetural completa do sistema **BALANÇO** em arquivos modulares e independentes, organizados segundo os padrões recomendados de engenharia de software em Flutter (Clean/Feature-first com SQLite local, exportações e motor de laudo A4).

---

## ESTRUTURA COMPLETA DE PASTAS (MONOREPO)

```text
balanco/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── models/
│   │   ├── entidade.dart
│   │   ├── setor.dart
│   │   ├── produto.dart
│   │   └── lancamento_item.dart
│   ├── database/
│   │   └── balanco_database.dart
│   ├── services/
│   │   ├── sync_service.dart
│   │   └── pdf_report_service.dart
│   └── ui/
│       ├── adaptive_shell.dart
│       ├── mobile/
│       │   ├── mobile_shell.dart
│       │   ├── screens/
│       │   │   ├── mobile_dashboard_screen.dart
│       │   │   ├── mobile_novo_lancamento_screen.dart
│       │   │   ├── mobile_lista_lancamentos_screen.dart
│       │   │   ├── mobile_cadastros_screen.dart
│       │   │   └── mobile_exportar_screen.dart
│       │   └── widgets/
│       │       └── mobile_metric_card.dart
│       └── desktop/
│           ├── desktop_shell.dart
│           ├── screens/
│           │   ├── desktop_catalogacao_screen.dart
│           │   ├── desktop_importar_screen.dart
│           │   ├── desktop_exportar_screen.dart
│           │   ├── desktop_entidades_setores_screen.dart
│           │   └── desktop_relatorio_a4_screen.dart
│           └── widgets/
│               ├── desktop_sidebar.dart
│               └── desktop_header.dart
```

---

## 1. CONFIGURAÇÃO DE DEPENDÊNCIAS (`pubspec.yaml`)

```yaml
name: balanco
description: Sistema Balanço de Catalogação Patrimonial e Emissão A4.
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # Banco de Dados SQLite Local com ACID
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0
  path_provider: ^2.1.1
  path: ^1.8.3

  # Captura de Fotos e Manipulação de Arquivos
  image_picker: ^1.0.4
  file_picker: ^6.1.1

  # Motor Pericial de Laudo A4 e Impressão
  pdf: ^3.10.7
  printing: ^5.11.1

  # Planilhas e Sincronização Tabular
  csv: ^5.1.1

  # Utilitários e Formatação
  intl: ^0.18.1
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
```

---

## 2. CORE: CORES E TEMA

### `lib/core/constants/app_colors.dart`
```dart
import 'package:flutter/material.dart';

class BalancoColors {
  static const Color primary = Color(0xFF1E3A8A);       // Deep Navy
  static const Color secondary = Color(0xFF3B82F6);     // Cobalt Blue
  static const Color success = Color(0xFF10B981);       // Emerald Green
  static const Color danger = Color(0xFFEF4444);        // Crimson
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color background = Color(0xFFF8FAFC);    // Slate Neutral Light
  static const Color surface = Color(0xFFFFFFFF);       // White
  static const Color textMain = Color(0xFF0F172A);      // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFFE2E8F0);        // Slate 200
  static const Color containerLow = Color(0xFFF1F5F9);  // Slate 100
}
```

### `lib/core/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: BalancoColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BalancoColors.primary,
        primary: BalancoColors.primary,
        secondary: BalancoColors.secondary,
        surface: BalancoColors.surface,
        background: BalancoColors.background,
        error: BalancoColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BalancoColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BalancoColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BalancoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BalancoColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: BalancoColors.secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
```

---

## 3. MODELOS DE DADOS (`lib/models/`)

### `lib/models/entidade.dart`
```dart
class Entidade {
  final int? id;
  final String nome;
  final String cnpjCodigo;
  final String regime;
  final String observacao;

  Entidade({
    this.id,
    required this.nome,
    this.cnpjCodigo = '',
    this.regime = 'Administração Direta',
    this.observacao = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'cnpj_codigo': cnpjCodigo,
    'regime': regime,
    'observacao': observacao,
    'criado_em': DateTime.now().toIso8601String(),
  };

  factory Entidade.fromMap(Map<String, dynamic> map) => Entidade(
    id: map['id'],
    nome: map['nome'],
    cnpjCodigo: map['cnpj_codigo'] ?? '',
    regime: map['regime'] ?? 'Administração Direta',
    observacao: map['observacao'] ?? '',
  );
}
```

### `lib/models/setor.dart`
```dart
class Setor {
  final int? id;
  final int entidadeId;
  final String nome;
  final String andarBloco;
  final String responsavel;

  Setor({
    this.id,
    required this.entidadeId,
    required this.nome,
    this.andarBloco = '',
    this.responsavel = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'entidade_id': entidadeId,
    'nome': nome,
    'andar_bloco': andarBloco,
    'responsavel': responsavel,
    'criado_em': DateTime.now().toIso8601String(),
  };

  factory Setor.fromMap(Map<String, dynamic> map) => Setor(
    id: map['id'],
    entidadeId: map['entidade_id'],
    nome: map['nome'],
    andarBloco: map['andar_bloco'] ?? '',
    responsavel: map['responsavel'] ?? '',
  );
}
```

### `lib/models/produto.dart`
```dart
class Produto {
  final int? id;
  final String nome;
  final String categoria;

  Produto({
    this.id,
    required this.nome,
    this.categoria = 'Geral',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'categoria': categoria,
    'criado_em': DateTime.now().toIso8601String(),
  };

  factory Produto.fromMap(Map<String, dynamic> map) => Produto(
    id: map['id'],
    nome: map['nome'],
    categoria: map['categoria'] ?? 'Geral',
  );
}
```

### `lib/models/lancamento_item.dart`
```dart
class LancamentoItem {
  final int? id;
  final String plaquetaCodigo;
  final int produtoId;
  final int setorId;
  final int entidadeId;
  final int quantidade;
  final String estadoConservacao;
  final String fotoPath;
  final String observacao;
  final String dataLancamento;

  // Campos com JOIN para listagens e laudo
  final String? produtoNome;
  final String? setorNome;
  final String? entidadeNome;

  LancamentoItem({
    this.id,
    required this.plaquetaCodigo,
    required this.produtoId,
    required this.setorId,
    required this.entidadeId,
    required this.quantidade,
    this.estadoConservacao = 'Ótimo',
    this.fotoPath = '',
    this.observacao = '',
    required this.dataLancamento,
    this.produtoNome,
    this.setorNome,
    this.entidadeNome,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'plaqueta_codigo': plaquetaCodigo,
    'produto_id': produtoId,
    'setor_id': setorId,
    'entidade_id': entidadeId,
    'quantidade': quantidade,
    'estado_conservacao': estadoConservacao,
    'foto_path': fotoPath,
    'observacao': observacao,
    'data_lancamento': dataLancamento,
    'criado_em': DateTime.now().toIso8601String(),
  };

  factory LancamentoItem.fromMap(Map<String, dynamic> map) => LancamentoItem(
    id: map['id'],
    plaquetaCodigo: map['plaqueta_codigo'] ?? '',
    produtoId: map['produto_id'],
    setorId: map['setor_id'],
    entidadeId: map['entidade_id'],
    quantidade: map['quantidade'],
    estadoConservacao: map['estado_conservacao'] ?? 'Ótimo',
    fotoPath: map['foto_path'] ?? '',
    observacao: map['observacao'] ?? '',
    dataLancamento: map['data_lancamento'] ?? '',
    produtoNome: map['produto_nome'],
    setorNome: map['setor_nome'],
    entidadeNome: map['entidade_nome'],
  );
}
```

---

## 4. PERSISTÊNCIA & BANCO SQLITE (`lib/database/balanco_database.dart`)

```dart
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

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entidades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        cnpj_codigo TEXT,
        regime TEXT,
        observacao TEXT,
        criado_em TEXT NOT NULL
      )
    ''');

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
      )
    ''');

    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        categoria TEXT,
        criado_em TEXT NOT NULL
      )
    ''');

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
      )
    ''');

    // Carga inicial amigável para testes
    await db.insert('entidades', {
      'nome': 'Prefeitura Municipal - Gabinete Executivo',
      'cnpj_codigo': '14.283.910/0001-44',
      'regime': 'Administração Direta',
      'observacao': 'Sede Principal',
      'criado_em': DateTime.now().toIso8601String(),
    });

    await db.insert('setores', {
      'entidade_id': 1,
      'nome': 'Depto. de TI e Servidores',
      'andar_bloco': 'Subsolo - Sala 02',
      'responsavel': 'Lucas S. Ferreira',
      'criado_em': DateTime.now().toIso8601String(),
    });

    await db.insert('produtos', {
      'nome': 'Notebook Lenovo ThinkPad L14 Gen 4',
      'categoria': 'Equipamento TI',
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<List<LancamentoItem>> getLancamentosCompletos() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        l.*,
        p.nome AS produto_nome,
        s.nome AS setor_nome,
        e.nome AS entidade_nome
      FROM lancamentos l
      JOIN produtos p ON l.produto_id = p.id
      JOIN setores s ON l.setor_id = s.id
      JOIN entidades e ON l.entidade_id = e.id
      ORDER BY l.id DESC
    ''');
    return result.map((json) => LancamentoItem.fromMap(json)).toList();
  }

  Future<int> insertLancamento(LancamentoItem item) async {
    final db = await instance.database;
    return await db.insert('lancamentos', item.toMap());
  }

  Future<List<Entidade>> getEntidades() async {
    final db = await instance.database;
    final res = await db.query('entidades', orderBy: 'nome ASC');
    return res.map((e) => Entidade.fromMap(e)).toList();
  }

  Future<int> insertEntidade(Entidade e) async {
    final db = await instance.database;
    return await db.insert('entidades', e.toMap());
  }

  Future<List<Setor>> getSetores(int entidadeId) async {
    final db = await instance.database;
    final res = await db.query('setores', where: 'entidade_id = ?', whereArgs: [entidadeId]);
    return res.map((e) => Setor.fromMap(e)).toList();
  }

  Future<int> insertSetor(Setor s) async {
    final db = await instance.database;
    return await db.insert('setores', s.toMap());
  }

  Future<List<Produto>> getProdutos() async {
    final db = await instance.database;
    final res = await db.query('produtos', orderBy: 'nome ASC');
    return res.map((e) => Produto.fromMap(e)).toList();
  }

  Future<int> getOrCreateProduto(String nome) async {
    final db = await instance.database;
    final res = await db.query('produtos', where: 'nome = ?', whereArgs: [nome.trim()]);
    if (res.isNotEmpty) return res.first['id'] as int;
    return await db.insert('produtos', {
      'nome': nome.trim(),
      'categoria': 'Geral',
      'criado_em': DateTime.now().toIso8601String(),
    });
  }
}
```

---

## 5. CAMADA DE SERVIÇOS (`lib/services/`)

### `lib/services/sync_service.dart`
```dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/balanco_database.dart';
import '../models/lancamento_item.dart';

class SyncService {
  static Future<File> exportToCsv(List<LancamentoItem> lista) async {
    List<List<dynamic>> rows = [
      ['id', 'plaqueta', 'produto', 'setor', 'entidade', 'quantidade', 'estado', 'observacao', 'data_lancamento', 'foto_path']
    ];

    for (var item in lista) {
      rows.add([
        item.id,
        item.plaquetaCodigo,
        item.produtoNome ?? '',
        item.setorNome ?? '',
        item.entidadeNome ?? '',
        item.quantidade,
        item.estadoConservacao,
        item.observacao,
        item.dataLancamento,
        item.fotoPath,
      ]);
    }

    String csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/balanco_exportacao_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv');
    return await file.writeAsString(csvData);
  }

  static Future<String> getDatabaseSnapshotPath() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'balanco_core.db');
  }

  static Future<int> importFromCsv(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final fields = const CsvToListConverter(fieldDelimiter: ';').convert(content);
    if (fields.length <= 1) return 0;

    final db = await BalancoDatabase.instance.database;
    int imported = 0;

    await db.transaction((txn) async {
      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 6) continue;

        String plaqueta = row[1].toString();
        String produtoNome = row[2].toString();
        String setorNome = row[3].toString();
        String entidadeNome = row[4].toString();
        int qtd = int.tryParse(row[5].toString()) ?? 1;

        // Auto criação de Entidade
        var entRes = await txn.query('entidades', where: 'nome = ?', whereArgs: [entidadeNome]);
        int entId = entRes.isNotEmpty
            ? entRes.first['id'] as int
            : await txn.insert('entidades', {
                'nome': entidadeNome,
                'criado_em': DateTime.now().toIso8601String(),
              });

        // Auto criação de Setor
        var setRes = await txn.query('setores', where: 'nome = ? AND entidade_id = ?', whereArgs: [setorNome, entId]);
        int setId = setRes.isNotEmpty
            ? setRes.first['id'] as int
            : await txn.insert('setores', {
                'entidade_id': entId,
                'nome': setorNome,
                'criado_em': DateTime.now().toIso8601String(),
              });

        // Auto criação de Produto
        var prodRes = await txn.query('produtos', where: 'nome = ?', whereArgs: [produtoNome]);
        int prodId = prodRes.isNotEmpty
            ? prodRes.first['id'] as int
            : await txn.insert('produtos', {
                'nome': produtoNome,
                'criado_em': DateTime.now().toIso8601String(),
              });

        await txn.insert(
          'lancamentos',
          {
            'plaqueta_codigo': plaqueta.isNotEmpty ? plaqueta : 'PAT-${DateTime.now().millisecondsSinceEpoch}',
            'produto_id': prodId,
            'setor_id': setId,
            'entidade_id': entId,
            'quantidade': qtd,
            'estado_conservacao': row.length > 6 ? row[6] : 'Ótimo',
            'observacao': row.length > 7 ? row[7] : '',
            'data_lancamento': row.length > 8 ? row[8] : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            'foto_path': row.length > 9 ? row[9] : '',
            'criado_em': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        imported++;
      }
    });

    return imported;
  }
}
```

### `lib/services/pdf_report_service.dart`
```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/lancamento_item.dart';

class PdfReportService {
  static Future<Uint8List> generateA4Report({
    required String titulo,
    required String entidadeNome,
    required List<LancamentoItem> items,
  }) async {
    final pdf = pw.Document();
    final totalQtd = items.fold<int>(0, (sum, i) => sum + i.quantidade);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15 * PdfPageFormat.mm),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 28,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Center(
                        child: pw.Text('B', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('BALANÇO', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E3A8A))),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(entidadeNome, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Emissão: ${DateFormat('dd/MM/yyyy às HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 2, color: const PdfColor.fromInt(0xFF1E3A8A)),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(titulo.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total de Itens: ${items.length} | Volume Físico Somado: $totalQtd un', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(40), // Foto 1:1
              1: const pw.FixedColumnWidth(65), // Plaqueta #PAT
              2: const pw.FlexColumnWidth(3),   // Descrição
              3: const pw.FlexColumnWidth(2),   // Setor
              4: const pw.FixedColumnWidth(40), // Qtd
              5: const pw.FixedColumnWidth(55), // Data
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
                children: [
                  _headerCell('FOTO'),
                  _headerCell('PLAQUETA'),
                  _headerCell('PRODUTO / ESPECIFICAÇÃO'),
                  _headerCell('SETOR'),
                  _headerCell('QTD'),
                  _headerCell('DATA'),
                ],
              ),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isZebra = idx % 2 == 1;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isZebra ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.white,
                  ),
                  children: [
                    pw.Container(
                      height: 32,
                      padding: const pw.EdgeInsets.all(2),
                      alignment: pw.Alignment.center,
                      child: (item.fotoPath.isNotEmpty && File(item.fotoPath).existsSync())
                          ? pw.Image(pw.MemoryImage(File(item.fotoPath).readAsBytesSync()), fit: pw.BoxFit.cover)
                          : pw.Container(
                              width: 28,
                              height: 28,
                              color: PdfColors.grey200,
                              child: pw.Center(child: pw.Text('SEM FOTO', style: const pw.TextStyle(fontSize: 5))),
                            ),
                    ),
                    _bodyCell(item.plaquetaCodigo, bold: true),
                    _bodyCell(item.produtoNome ?? '-'),
                    _bodyCell(item.setorNome ?? '-'),
                    _bodyCell('${item.quantidade} un', align: pw.TextAlign.center, bold: true),
                    _bodyCell(item.dataLancamento.split(' ').first, align: pw.TextAlign.center),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _bodyCell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }
}
```

---

## 6. INTERFACES MOBILE (`lib/ui/mobile/`)

### `lib/ui/mobile/mobile_shell.dart`
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'screens/mobile_dashboard_screen.dart';
import 'screens/mobile_lista_lancamentos_screen.dart';
import 'screens/mobile_novo_lancamento_screen.dart';
import 'screens/mobile_cadastros_screen.dart';
import 'screens/mobile_exportar_screen.dart';

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MobileDashboardScreen(),
    MobileListaLancamentosScreen(),
    MobileNovoLancamentoScreen(),
    MobileCadastrosScreen(),
    MobileExportarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Itens'),
          NavigationDestination(icon: Icon(Icons.add_circle, color: BalancoColors.primary, size: 32), label: 'Novo'),
          NavigationDestination(icon: Icon(Icons.domain_outlined), selectedIcon: Icon(Icons.domain), label: 'Cadastros'),
          NavigationDestination(icon: Icon(Icons.share_outlined), selectedIcon: Icon(Icons.share), label: 'Exportar'),
        ],
      ),
    );
  }
}
```

### `lib/ui/mobile/widgets/mobile_metric_card.dart`
```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MobileMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const MobileMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: BalancoColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: BalancoColors.textMain)),
            Text(label, style: const TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
```

### `lib/ui/mobile/screens/mobile_dashboard_screen.dart`
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../database/balanco_database.dart';
import '../../../models/lancamento_item.dart';
import '../widgets/mobile_metric_card.dart';

class MobileDashboardScreen extends StatelessWidget {
  const MobileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balanço', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BalancoColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: BalancoColors.success),
                SizedBox(width: 4),
                Text('SQLite Offline', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: FutureBuilder<List<LancamentoItem>>(
        future: BalancoDatabase.instance.getLancamentosCompletos(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final totalQtd = items.fold<int>(0, (s, i) => s + i.quantidade);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: BalancoColors.primary,
                        child: Icon(Icons.account_balance, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prefeitura Municipal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('CNPJ 14.283.910/0001-44', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: MobileMetricCard(label: 'Bens Únicos', value: '${items.length}', icon: Icons.folder_special, color: BalancoColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: MobileMetricCard(label: 'Unidades Físicas', value: '$totalQtd', icon: Icons.tag, color: BalancoColors.secondary)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Últimos Lançamentos Auditados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhum item lançado ainda.')))
              else
                ...items.take(5).map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                            child: (item.fotoPath.isNotEmpty && File(item.fotoPath).existsSync())
                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item.fotoPath), fit: BoxFit.cover))
                                : const Icon(Icons.photo_camera, color: Colors.grey),
                          ),
                          title: Text(item.produtoNome ?? 'Item #${item.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.setorNome} • ${item.dataLancamento}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: BalancoColors.containerLow, borderRadius: BorderRadius.circular(12)),
                            child: Text('${item.quantidade} un', style: const TextStyle(fontWeight: FontWeight.bold, color: BalancoColors.primary)),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
```

### `lib/ui/mobile/screens/mobile_novo_lancamento_screen.dart`
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../database/balanco_database.dart';
import '../../../models/entidade.dart';
import '../../../models/setor.dart';
import '../../../models/lancamento_item.dart';

class MobileNovoLancamentoScreen extends StatefulWidget {
  const MobileNovoLancamentoScreen({super.key});

  @override
  State<MobileNovoLancamentoScreen> createState() => _MobileNovoLancamentoScreenState();
}

class _MobileNovoLancamentoScreenState extends State<MobileNovoLancamentoScreen> {
  final _produtoController = TextEditingController();
  final _plaquetaController = TextEditingController(text: 'PAT-2025-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
  final _obsController = TextEditingController();
  int _quantidade = 1;
  String _estado = 'Ótimo';
  String? _fotoPath;

  int? _selectedEntidadeId;
  int? _selectedSetorId;

  List<Entidade> _entidades = [];
  List<Setor> _setores = [];

  @override
  void initState() {
    super.initState();
    _loadDados();
  }

  void _loadDados() async {
    final ents = await BalancoDatabase.instance.getEntidades();
    setState(() {
      _entidades = ents;
      if (ents.isNotEmpty) {
        _selectedEntidadeId = ents.first.id;
        _loadSetores(ents.first.id!);
      }
    });
  }

  void _loadSetores(int entidadeId) async {
    final sets = await BalancoDatabase.instance.getSetores(entidadeId);
    setState(() {
      _setores = sets;
      if (sets.isNotEmpty) _selectedSetorId = sets.first.id;
    });
  }

  void _tirarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      setState(() => _fotoPath = picked.path);
    }
  }

  void _salvar() async {
    if (_produtoController.text.trim().isEmpty || _selectedEntidadeId == null || _selectedSetorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o produto, entidade e setor!')));
      return;
    }

    final prodId = await BalancoDatabase.instance.getOrCreateProduto(_produtoController.text.trim());

    final novo = LancamentoItem(
      plaquetaCodigo: _plaquetaController.text.trim(),
      produtoId: prodId,
      setorId: _selectedSetorId!,
      entidadeId: _selectedEntidadeId!,
      quantidade: _quantidade,
      estadoConservacao: _estado,
      fotoPath: _fotoPath ?? '',
      observacao: _obsController.text.trim(),
      dataLancamento: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    );

    await BalancoDatabase.instance.insertLancamento(novo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamento salvo com sucesso no SQLite!')));
      setState(() {
        _produtoController.clear();
        _obsController.clear();
        _fotoPath = null;
        _quantidade = 1;
        _plaquetaController.text = 'PAT-2025-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Lançamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _tirarFoto,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BalancoColors.border, width: 2),
              ),
              child: _fotoPath != null && File(_fotoPath!).existsSync()
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_fotoPath!), fit: BoxFit.cover))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: BalancoColors.primary),
                        SizedBox(height: 8),
                        Text('Fotografar Ativo (Câmera ou Galeria)', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Aspecto 1:1 preservado para laudo A4', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _plaquetaController,
            decoration: const InputDecoration(labelText: 'Plaqueta / Tombamento (#PAT)*'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _produtoController,
            decoration: const InputDecoration(labelText: 'Identificação do Bem / Produto*', hintText: 'Ex: Cadeira Giratória NR-17'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedEntidadeId,
            items: _entidades.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedEntidadeId = val);
                _loadSetores(val);
              }
            },
            decoration: const InputDecoration(labelText: 'Entidade / Instituição*'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedSetorId,
            items: _setores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome))).toList(),
            onChanged: (val) => setState(() => _selectedSetorId = val),
            decoration: const InputDecoration(labelText: 'Setor / Sala Destino*'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Quantidade Física:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_quantidade > 1) setState(() => _quantidade--);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_quantidade', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantidade++),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Ótimo', label: Text('Ótimo')),
              ButtonSegment(value: 'Bom', label: Text('Bom')),
              ButtonSegment(value: 'Danificado', label: Text('Danificado')),
            ],
            selected: {_estado},
            onSelectionChanged: (val) => setState(() => _estado = val.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _obsController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Observações de Campo'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Lançamento no SQLite', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class MobileListaLancamentosScreen extends StatelessWidget {
  const MobileListaLancamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamentos Catalogados')),
      body: FutureBuilder<List<LancamentoItem>>(
        future: BalancoDatabase.instance.getLancamentosCompletos(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Nenhum registro encontrado.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final item = items[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: (item.fotoPath.isNotEmpty && File(item.fotoPath).existsSync())
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item.fotoPath), fit: BoxFit.cover))
                        : const Icon(Icons.photo),
                  ),
                  title: Text(item.produtoNome ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.plaquetaCodigo} • ${item.setorNome}\n${item.entidadeNome}'),
                  isThreeLine: true,
                  trailing: Text('${item.quantidade} un', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BalancoColors.primary)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MobileCadastrosScreen extends StatelessWidget {
  const MobileCadastrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Cadastros')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuTile(context, 'Entidades & Instituições', Icons.domain, 'Prefeituras, Secretarias e Hospitais'),
          _menuTile(context, 'Setores & Departamentos', Icons.meeting_room, 'Salas, andares e blocos mapeados'),
          _menuTile(context, 'Catálogo de Produtos / Bens', Icons.category, 'Produtos padronizados no inventário'),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext ctx, String title, IconData icon, String sub) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: BalancoColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class MobileExportarScreen extends StatelessWidget {
  const MobileExportarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportação de Dados')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage, color: BalancoColors.primary, size: 36),
                title: const Text('Banco SQLite (.db)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Snapshot relacional íntegro com transação ACID.'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final path = await SyncService.getDatabaseSnapshotPath();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo .db em: $path')));
                  },
                  child: const Text('Exportar .db'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.table_chart, color: BalancoColors.secondary, size: 36),
                title: const Text('Planilha Tabular (.csv)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Colunas padronizadas com caminhos das fotos.'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final items = await BalancoDatabase.instance.getLancamentosCompletos();
                    final file = await SyncService.exportToCsv(items);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportado: ${file.path}')));
                  },
                  child: const Text('Exportar .csv'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 7. INTERFACES DESKTOP (`lib/ui/desktop/`)

### `lib/ui/desktop/widgets/desktop_sidebar.dart`
```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.account_balance, color: BalancoColors.primary, size: 28),
                SizedBox(width: 10),
                Text('BALANÇO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
              ],
            ),
          ),
          const Divider(height: 1, color: BalancoColors.border),
          const SizedBox(height: 12),
          _item(0, Icons.table_chart_outlined, 'Catalogação e Bens'),
          _item(1, Icons.upload_file_outlined, 'Importar Dados'),
          _item(2, Icons.download_outlined, 'Exportar Dados'),
          _item(3, Icons.domain_outlined, 'Entidades e Setores'),
          _item(4, Icons.print_outlined, 'Relatórios e Laudo A4'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BalancoColors.containerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.storage, size: 16, color: BalancoColors.primary),
                SizedBox(width: 8),
                Text('SQLite Local ACID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _item(int idx, IconData icon, String title) {
    final active = selectedIndex == idx;
    return ListTile(
      leading: Icon(icon, color: active ? BalancoColors.primary : BalancoColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: active ? BalancoColors.primary : BalancoColors.textMain,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: active,
      selectedTileColor: BalancoColors.containerLow,
      onTap: () => onSelect(idx),
    );
  }
}
```

### `lib/ui/desktop/desktop_shell.dart`
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/desktop_sidebar.dart';
import 'screens/desktop_catalogacao_screen.dart';
import 'screens/desktop_importar_screen.dart';
import 'screens/desktop_exportar_screen.dart';
import 'screens/desktop_entidades_setores_screen.dart';
import 'screens/desktop_relatorio_a4_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DesktopCatalogacaoScreen(),
    DesktopImportarScreen(),
    DesktopExportarScreen(),
    DesktopEntidadesSetoresScreen(),
    DesktopRelatorioA4Screen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DesktopSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (idx) => setState(() => _selectedIndex = idx),
          ),
          const VerticalDivider(width: 1, color: BalancoColors.border),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
```

### `lib/ui/desktop/screens/desktop_relatorio_a4_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../database/balanco_database.dart';
import '../../../models/lancamento_item.dart';
import '../../../services/pdf_report_service.dart';

class DesktopRelatorioA4Screen extends StatefulWidget {
  const DesktopRelatorioA4Screen({super.key});

  @override
  State<DesktopRelatorioA4Screen> createState() => _DesktopRelatorioA4ScreenState();
}

class _DesktopRelatorioA4ScreenState extends State<DesktopRelatorioA4Screen> {
  List<LancamentoItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() async {
    final res = await BalancoDatabase.instance.getLancamentosCompletos();
    setState(() {
      _items = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Emissão e Pré-visualização do Laudo A4')),
      body: PdfPreview(
        build: (format) => PdfReportService.generateA4Report(
          titulo: 'Relatório Auditado de Catalogação e Tombamento Patrimonial',
          entidadeNome: 'Prefeitura Municipal - Gabinete Executivo',
          items: _items,
        ),
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canChangeOrientation: false,
      ),
    );
  }
}

// Stubs operacionais para compilação integral das telas desktop restantes:
class DesktopCatalogacaoScreen extends StatelessWidget {
  const DesktopCatalogacaoScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Base de Catalogação Desktop'));
}

class DesktopImportarScreen extends StatelessWidget {
  const DesktopImportarScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Módulo de Importação .db e .csv'));
}

class DesktopExportarScreen extends StatelessWidget {
  const DesktopExportarScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Módulo de Exportação .db, .csv e fotos'));
}

class DesktopEntidadesSetoresScreen extends StatelessWidget {
  const DesktopEntidadesSetoresScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Gestão Hierárquica de Entidades e Setores'));
}
```

---

## 8. PONTO DE ENTRADA ADAPTATIVO (`lib/ui/adaptive_shell.dart` e `lib/main.dart`)

### `lib/ui/adaptive_shell.dart`
```dart
import 'package:flutter/material.dart';
import 'mobile/mobile_shell.dart';
import 'desktop/desktop_shell.dart';

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Breakpoint padrão: Telas >= 900px ativam a visualização desktop com sidebar
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return isDesktop ? const DesktopShell() : const MobileShell();
  }
}
```

### `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'ui/adaptive_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BalancoApp());
}

class BalancoApp extends StatelessWidget {
  const BalancoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balanço - Patrimônio & Auditoria',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AdaptiveShell(),
    );
  }
}
```
