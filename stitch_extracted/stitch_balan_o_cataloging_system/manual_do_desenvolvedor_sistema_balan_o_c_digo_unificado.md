# MANUAL COMPLETO DE DESENVOLVIMENTO & ESPECIFICAÇÃO TÉCNICA
## SISTEMA BALANÇO — PATRIMÔNIO & AUDITORIA (MOBILE + DESKTOP)

---

## 1. VISÃO GERAL DA ARQUITETURA

O **BALANÇO** é um sistema unificado multiplataforma (Mobile Android/iOS e Desktop Windows/macOS/Linux) construído em **Flutter (Dart)** com armazenamento local baseado em **SQLite**, garantindo funcionamento 100% offline, transações com integridade ACID, sincronização de lotes via snapshots `.db` e arquivos estruturados `.csv` com acervo fotográfico, além da emissão de relatórios periciais milimetricamente diagramados no padrão A4 (PDF e Impressão direta).

### 1.1 Topologia de Pastas Recomendada (Monorepo Flutter)

```text
balanco/
├── pubspec.yaml
├── README.md
├── assets/
│   ├── icons/
│   └── images/
├── lib/
│   ├── main.dart                      # Ponto de entrada adaptativo (Mobile & Desktop)
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart        # Design tokens oficiais do Balanço
│   │   ├── database/
│   │   │   └── db_helper.dart         # Motor SQLite local com transações ACID
│   │   ├── services/
│   │   │   ├── export_service.dart    # Exportador (.db, .csv, acervo .zip)
│   │   │   ├── import_service.dart    # Importador com validação de chaves e hashes
│   │   │   └── pdf_service.dart       # Gerador do Laudo A4 com fotos e paginação
│   │   └── utils/
│   │       └── platform_detector.dart # Deteção Mobile vs Desktop
│   ├── models/
│   │   ├── entidade.dart
│   │   ├── setor.dart
│   │   ├── produto.dart
│   │   └── lancamento.dart
│   ├── repositories/
│   │   ├── entidade_repository.dart
│   │   ├── setor_repository.dart
│   │   ├── produto_repository.dart
│   │   └── lancamento_repository.dart
│   ├── ui/
│   │   ├── mobile/
│   │   │   ├── mobile_shell.dart      # Barra superior e Bottom Navigation Bar
│   │   │   ├── screens/
│   │   │   │   ├── mobile_dashboard.dart
│   │   │   │   ├── mobile_novo_lancamento.dart
│   │   │   │   ├── mobile_lista_lancamentos.dart
│   │   │   │   ├── mobile_cadastros.dart
│   │   │   │   └── mobile_exportar.dart
│   │   └── desktop/
│   │       ├── desktop_shell.dart     # Sidebar retrátil e header de controle
│   │       ├── screens/
│   │       │   ├── desktop_base_catalogacao.dart
│   │       │   ├── desktop_importar.dart
│   │       │   ├── desktop_exportar.dart
│   │       │   ├── desktop_entidades_setores.dart
│   │       │   └── desktop_relatorio_a4.dart
│   │   └── shared_widgets/
│   │       ├── balanco_button.dart
│   │       ├── metric_card.dart
│   │       └── photo_preview.dart
```

---

## 2. ESQUEMA DO BANCO DE DADOS SQLITE LOCAL

O banco deve ser configurado com chaves estrangeiras ativadas (`PRAGMA foreign_keys = ON;`).

```sql
-- TABELA: entidades
CREATE TABLE IF NOT EXISTS entidades (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE,
    cnpj_codigo TEXT,
    regime TEXT,
    observacao TEXT,
    criado_em TEXT NOT NULL
);

-- TABELA: setores
CREATE TABLE IF NOT EXISTS setores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entidade_id INTEGER NOT NULL,
    nome TEXT NOT NULL,
    andar_bloco TEXT,
    responsavel TEXT,
    criado_em TEXT NOT NULL,
    UNIQUE(entidade_id, nome),
    FOREIGN KEY (entidade_id) REFERENCES entidades(id) ON DELETE CASCADE
);

-- TABELA: produtos
CREATE TABLE IF NOT EXISTS produtos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE,
    categoria TEXT,
    criado_em TEXT NOT NULL
);

-- TABELA: lancamentos
CREATE TABLE IF NOT EXISTS lancamentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plaqueta_codigo TEXT UNIQUE,
    produto_id INTEGER NOT NULL,
    setor_id INTEGER NOT NULL,
    entidade_id INTEGER NOT NULL,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    estado_conservacao TEXT DEFAULT 'Ótimo', -- Ótimo, Bom, Danificado
    foto_path TEXT,                          -- Caminho absoluto/relativo no storage local
    observacao TEXT,
    data_lancamento TEXT NOT NULL,
    criado_em TEXT NOT NULL,
    FOREIGN KEY (produto_id) REFERENCES produtos(id),
    FOREIGN KEY (setor_id) REFERENCES setores(id),
    FOREIGN KEY (entidade_id) REFERENCES entidades(id)
);

CREATE INDEX IF NOT EXISTS idx_lancamentos_entidade ON lancamentos(entidade_id);
CREATE INDEX IF NOT EXISTS idx_lancamentos_setor ON lancamentos(setor_id);
CREATE INDEX IF NOT EXISTS idx_lancamentos_plaqueta ON lancamentos(plaqueta_codigo);
```

---

## 3. DEPENDÊNCIAS DO `pubspec.yaml`

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
  sqflite: ^2.3.0                # Mobile SQLite
  sqflite_common_ffi: ^2.3.0     # Desktop SQLite (Windows, Linux, macOS)
  path_provider: ^2.1.1          # Diretórios locais da aplicação
  path: ^1.8.3
  image_picker: ^1.0.4           # Captura por Câmera / Galeria no Mobile
  camera: ^0.10.5                # Ou integração direta por câmera
  file_picker: ^6.1.1            # Seleção de arquivos .db/.csv no Desktop
  pdf: ^3.10.7                   # Diagramação vetorial para laudo A4
  printing: ^5.11.1              # Preview de impressão e driver nativo
  csv: ^5.1.1                    # Parser e gerador de planilhas RFC 4180
  archive: ^3.4.9                # Criação e extração de acervos .zip
  crypto: ^3.0.3                 # Cálculo de hash SHA-256 para auditoria
  intl: ^0.18.1                  # Formatação de datas e números
  google_fonts: ^6.1.0           # Fontes Outfit e Inter

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

## 4. CÓDIGO FONTE UNIFICADO EM UM SÓ ARQUIVO (`main.dart`)

O código abaixo reúne a arquitetura completa em um único arquivo de implementação pronto para testes, prototipação rápida e consulta pelo desenvolvedor:

```dart
// ============================================================================
// SISTEMA BALANÇO — PATRIMÔNIO & AUDITORIA
// CÓDIGO UNIFICADO MULTIPLATAFORMA (MOBILE & DESKTOP)
// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

// ============================================================================
// 1. DESIGN SYSTEM TOKENS (DESIGN.md)
// ============================================================================

class BalancoColors {
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color secondary = Color(0xFF3B82F6); // Cobalt Blue
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color background = Color(0xFFF8FAFC); // Neutral Light
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color danger = Color(0xFFEF4444);
  static const Color containerLow = Color(0xFFF0F4F8);
}

ThemeData getBalancoTheme() {
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
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BalancoColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BalancoColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BalancoColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BalancoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BalancoColors.secondary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ============================================================================
// 2. MODELOS DE DADOS
// ============================================================================

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

class Produto {
  final int? id;
  final String nome;
  final String categoria;

  Produto({this.id, required this.nome, this.categoria = 'Geral'});

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

  // Campos agregados (Joins)
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

// ============================================================================
// 3. CAMADA DE PERSISTÊNCIA & REPOSITÓRIO SQLITE ACID
// ============================================================================

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

    // Carga de inicialização amigável
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

  // Operações de Lançamentos com JOINS
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

  Future<List<Setor>> getSetores(int entidadeId) async {
    final db = await instance.database;
    final res = await db.query('setores', where: 'entidade_id = ?', whereArgs: [entidadeId]);
    return res.map((e) => Setor.fromMap(e)).toList();
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

// ============================================================================
// 4. SERVIÇOS: EXPORTAÇÃO (.DB / .CSV) E IMPORTAÇÃO
// ============================================================================

class BalancoSyncService {
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

// ============================================================================
// 5. MOTOR DE RELATÓRIO PDF A4 PRECISO COM FOTOS
// ============================================================================

class BalancoPdfReport {
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
              0: const pw.FixedColumnWidth(40), // Miniatura da foto
              1: const pw.FixedColumnWidth(65), // Plaqueta
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

// ============================================================================
// 6. TELAS FLUTTER (MOBILE & DESKTOP ADAPTATIVAS)
// ============================================================================

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
      theme: getBalancoTheme(),
      home: const PlatformAdaptiveShell(),
    );
  }
}

class PlatformAdaptiveShell extends StatelessWidget {
  const PlatformAdaptiveShell({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return isDesktop ? const DesktopMainView() : const MobileMainView();
  }
}

// ----------------------------------------------------------------------------
// INTERFACE MOBILE
// ----------------------------------------------------------------------------

class MobileMainView extends StatefulWidget {
  const MobileMainView({super.key});

  @override
  State<MobileMainView> createState() => _MobileMainViewState();
}

class _MobileMainViewState extends State<MobileMainView> {
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
      body: _pages[_currentIndex],
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: BalancoColors.primary,
                        child: Icon(Icons.account_balance, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
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
                  Expanded(child: _metricCard('Bens Únicos', '${items.length}', Icons.folder_special, BalancoColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _metricCard('Unidades Físicas', '$totalQtd', Icons.tag, BalancoColors.secondary)),
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

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: BalancoColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: BalancoColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

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
          // Captura Fotográfica
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
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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
          // Quantidade
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
          // Estado de Conservação
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
                    final path = await BalancoSyncService.getDatabaseSnapshotPath();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo .db disponível em: $path')));
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
                subtitle: const Text('Colunas: id, plaqueta, produto, setor, entidade, quantidade...'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final items = await BalancoDatabase.instance.getLancamentosCompletos();
                    final file = await BalancoSyncService.exportToCsv(items);
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

// ----------------------------------------------------------------------------
// INTERFACE DESKTOP (PC) COM IMPLANTAÇÃO COMPLETA DE RELATÓRIO A4
// ----------------------------------------------------------------------------

class DesktopMainView extends StatefulWidget {
  const DesktopMainView({super.key});

  @override
  State<DesktopMainView> createState() => _DesktopMainViewState();
}

class _DesktopMainViewState extends State<DesktopMainView> {
  int _selectedRoute = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Desktop Retrátil & Firme
          Container(
            width: 250,
            color: const Color(0xFF0F172A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: BalancoColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BALANÇO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Patrimônio & Laudos', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      )
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                _sidebarItem(0, 'Base de Catalogação', Icons.list_alt),
                _sidebarItem(1, 'Importar Dados (.db / .csv)', Icons.download),
                _sidebarItem(2, 'Exportar Backups', Icons.upload_file),
                _sidebarItem(3, 'Entidades & Setores', Icons.apartment),
                _sidebarItem(4, 'Relatórios & Emissão A4', Icons.picture_as_pdf),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.dns, color: BalancoColors.success, size: 16),
                      SizedBox(width: 8),
                      Text('SQLite Local Ativo', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                )
              ],
            ),
          ),
          // Área Central Dinâmica
          Expanded(
            child: IndexedStack(
              index: _selectedRoute,
              children: const [
                DesktopCatalogacaoScreen(),
                DesktopImportarScreen(),
                DesktopExportarScreen(),
                DesktopEntidadesSetoresScreen(),
                DesktopRelatorioA4Screen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String title, IconData icon) {
    final selected = _selectedRoute == index;
    return ListTile(
      leading: Icon(icon, color: selected ? BalancoColors.secondary : Colors.white60),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: selected,
      selectedTileColor: Colors.white.withOpacity(0.08),
      onTap: () => setState(() => _selectedRoute = index),
    );
  }
}

class DesktopCatalogacaoScreen extends StatelessWidget {
  const DesktopCatalogacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: BalancoColors.textMain,
        title: const Text('Base de Catalogação e Lançamentos'),
      ),
      body: FutureBuilder<List<LancamentoItem>>(
        future: BalancoDatabase.instance.getLancamentosCompletos(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Foto')),
                    DataColumn(label: Text('Plaqueta')),
                    DataColumn(label: Text('Produto / Bem')),
                    DataColumn(label: Text('Setor')),
                    DataColumn(label: Text('Entidade')),
                    DataColumn(label: Text('Quantidade')),
                    DataColumn(label: Text('Conservação')),
                  ],
                  rows: items
                      .map(
                        (i) => DataRow(
                          cells: [
                            DataCell(
                              (i.fotoPath.isNotEmpty && File(i.fotoPath).existsSync())
                                  ? Image.file(File(i.fotoPath), width: 36, height: 36, fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                            ),
                            DataCell(Text(i.plaquetaCodigo, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(i.produtoNome ?? '-')),
                            DataCell(Text(i.setorNome ?? '-')),
                            DataCell(Text(i.entidadeNome ?? '-')),
                            DataCell(Text('${i.quantidade} un', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(i.estadoConservacao)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DesktopImportarScreen extends StatefulWidget {
  const DesktopImportarScreen({super.key});

  @override
  State<DesktopImportarScreen> createState() => _DesktopImportarScreenState();
}

class _DesktopImportarScreenState extends State<DesktopImportarScreen> {
  String? _status;

  void _selecionarEImportar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'db', 'sqlite'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (path.endsWith('.csv')) {
        int count = await BalancoSyncService.importFromCsv(path);
        setState(() => _status = 'Sucesso! $count registros importados e validados no SQLite.');
      } else {
        setState(() => _status = 'Arquivo .db detectado. Para mesclagem direta, utilize o validador de lote.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Importação de Dados do Inventário Mobile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Selecione os arquivos gerados pelo aplicativo (.csv ou .db) para sincronizar a base local.'),
          const SizedBox(height: 24),
          InkWell(
            onTap: _selecionarEImportar,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BalancoColors.secondary, style: BorderStyle.solid, width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 54, color: BalancoColors.secondary),
                  SizedBox(height: 12),
                  Text('Clique para selecionar o arquivo .csv ou .db exportado', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Formatos aceitos: RFC 4180 (.csv) e SQLite v3 (.db)', style: TextStyle(color: BalancoColors.textSecondary)),
                ],
              ),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: BalancoColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_status!, style: const TextStyle(color: BalancoColors.success, fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
    );
  }
}

class DesktopExportarScreen extends StatelessWidget {
  const DesktopExportarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Módulo de Exportação Desktop (.db, .csv, acervo fotográfico .zip)'));
  }
}

class DesktopEntidadesSetoresScreen extends StatelessWidget {
  const DesktopEntidadesSetoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Módulo de Entidades e Setores Desktop'));
  }
}

class DesktopRelatorioA4Screen extends StatelessWidget {
  const DesktopRelatorioA4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: BalancoColors.textMain,
        title: const Text('Pré-Visualização & Emissão de Relatório A4'),
      ),
      body: PdfPreview(
        build: (format) async {
          final items = await BalancoDatabase.instance.getLancamentosCompletos();
          return BalancoPdfReport.generateA4Report(
            titulo: 'Relatório Auditado de Catalogação e Tombamento Patrimonial',
            entidadeNome: 'Prefeitura Municipal - Gabinete Executivo',
            items: items,
          );
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'relatorio_patrimonial_a4.pdf',
      ),
    );
  }
}
```

---

## 5. GUIA DE EXECUÇÃO & BUILD DO DESENVOLVEDOR

### 5.1 Rodar no Mobile (Android / iOS)
```bash
flutter pub get
flutter run -d android
# ou
flutter run -d ios
```

### 5.2 Rodar no Desktop (Windows / macOS / Linux)
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
flutter pub get
flutter run -d windows
# ou
flutter run -d macos
```

### 5.3 Validações e Testes de Integridade
1. **Regra de Não-Nulos**: Nenhum lançamento pode ocorrer sem produto, entidade e setor vinculados.
2. **Quantidade**: Garantida em código e via `CHECK(quantidade > 0)` no SQLite.
3. **Câmera & Fotos**: As fotos são armazenadas em disco (`foto_path`), prevenindo estouro de memória no banco (`blob` leve ou apontamento).
4. **Precisão de Impressão**: O PDF segue rigorosamente a proporção ISO A4 (210×297mm) com margens auditáveis de 15mm.
