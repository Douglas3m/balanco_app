import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/balanco_database.dart';
import '../models/lancamento_item.dart';

class SyncService {
  /// Exporta a lista de lançamentos para arquivo .csv estruturado
  static Future<File> exportToCsv(List<LancamentoItem> items, {String? targetDir}) async {
    final rows = <List<dynamic>>[
      [
        'id',
        'plaqueta',
        'produto',
        'setor',
        'entidade',
        'quantidade',
        'estado_conservacao',
        'observacao',
        'data_lancamento',
        'foto_path'
      ]
    ];

    for (var item in items) {
      rows.add([
        item.id ?? '',
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

    final csvString = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    final directory = targetDir != null
        ? Directory(targetDir)
        : await getApplicationDocumentsDirectory();

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(directory.path, 'balanco_export_$timestamp.csv'));
    return await file.writeAsString(csvString, encoding: utf8);
  }

  /// Retorna o caminho do banco de dados SQLite principal
  static Future<String> getDatabaseSnapshotPath() async {
    final db = await BalancoDatabase.instance.database;
    return db.path;
  }

  /// Exporta o banco .db para uma cópia de backup
  static Future<File> exportDatabaseCopy({String? targetDir}) async {
    final sourcePath = await getDatabaseSnapshotPath();
    final directory = targetDir != null
        ? Directory(targetDir)
        : await getApplicationDocumentsDirectory();

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final destPath = p.join(directory.path, 'balanco_backup_$timestamp.db');
    final sourceFile = File(sourcePath);
    return await sourceFile.copy(destPath);
  }

  /// Exporta um pacote .zip completo com .csv, snapshot .db e pasta de fotos
  static Future<File> exportFullZipPackage(List<LancamentoItem> items, {String? targetDir}) async {
    final directory = targetDir != null
        ? Directory(targetDir)
        : await getApplicationDocumentsDirectory();

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final zipFile = File(p.join(directory.path, 'balanco_pacote_$timestamp.zip'));

    final archive = Archive();

    // 1. Gera e inclui o CSV
    final csvFile = await exportToCsv(items, targetDir: directory.path);
    final csvBytes = await csvFile.readAsBytes();
    archive.addFile(ArchiveFile('balanco_dados.csv', csvBytes.length, csvBytes));

    // 2. Inclui o snapshot do DB
    final dbPath = await getDatabaseSnapshotPath();
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('balanco_core.db', dbBytes.length, dbBytes));
    }

    // 3. Inclui as fotos
    for (var item in items) {
      if (item.fotoPath.isNotEmpty) {
        final photoFile = File(item.fotoPath);
        if (photoFile.existsSync()) {
          final photoBytes = await photoFile.readAsBytes();
          final photoName = p.basename(item.fotoPath);
          archive.addFile(ArchiveFile('fotos/$photoName', photoBytes.length, photoBytes));
        }
      }
    }

    // Salva o ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      await zipFile.writeAsBytes(zipData);
    }

    return zipFile;
  }

  /// Importa dados a partir de um arquivo .csv
  static Future<int> importFromCsv(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return 0;

    final content = await file.readAsString(encoding: utf8);
    final lines = const CsvToListConverter(fieldDelimiter: ';').convert(content);
    if (lines.length <= 1) return 0;

    final db = await BalancoDatabase.instance.database;
    int imported = 0;

    await db.transaction((txn) async {
      for (int i = 1; i < lines.length; i++) {
        final row = lines[i];
        if (row.length < 6) continue;

        final plaqueta = row[1].toString().trim();
        final produtoNome = row[2].toString().trim();
        final setorNome = row[3].toString().trim();
        final entidadeNome = row[4].toString().trim();
        final qtd = int.tryParse(row[5].toString()) ?? 1;

        if (produtoNome.isEmpty || setorNome.isEmpty || entidadeNome.isEmpty) continue;

        // Auto-criação da Entidade
        var entRes = await txn.query('entidades', where: 'nome = ?', whereArgs: [entidadeNome]);
        int entId;
        if (entRes.isNotEmpty) {
          entId = entRes.first['id'] as int;
        } else {
          entId = await txn.insert('entidades', {
            'nome': entidadeNome,
            'cnpj_codigo': '',
            'regime': 'Administração Direta',
            'observacao': 'Importado via CSV',
            'criado_em': DateTime.now().toIso8601String(),
          });
        }

        // Auto-criação do Setor
        var setRes = await txn.query(
          'setores',
          where: 'nome = ? AND entidade_id = ?',
          whereArgs: [setorNome, entId],
        );
        int setId;
        if (setRes.isNotEmpty) {
          setId = setRes.first['id'] as int;
        } else {
          setId = await txn.insert('setores', {
            'entidade_id': entId,
            'nome': setorNome,
            'andar_bloco': '',
            'responsavel': '',
            'criado_em': DateTime.now().toIso8601String(),
          });
        }

        // Auto-criação do Produto
        var prodRes = await txn.query('produtos', where: 'nome = ?', whereArgs: [produtoNome]);
        int prodId;
        if (prodRes.isNotEmpty) {
          prodId = prodRes.first['id'] as int;
        } else {
          prodId = await txn.insert('produtos', {
            'nome': produtoNome,
            'categoria': 'Geral',
            'criado_em': DateTime.now().toIso8601String(),
          });
        }

        final plaquetaFinal = plaqueta.isNotEmpty
            ? plaqueta
            : 'PAT-${DateTime.now().millisecondsSinceEpoch}-$i';

        final estado = row.length > 6 ? row[6].toString().trim() : 'Ótimo';
        final obs = row.length > 7 ? row[7].toString().trim() : '';
        final data = row.length > 8 ? row[8].toString().trim() : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
        final fotoPath = row.length > 9 ? row[9].toString().trim() : '';

        await txn.insert(
          'lancamentos',
          {
            'plaqueta_codigo': plaquetaFinal,
            'produto_id': prodId,
            'setor_id': setId,
            'entidade_id': entId,
            'quantidade': qtd > 0 ? qtd : 1,
            'estado_conservacao': estado.isNotEmpty ? estado : 'Ótimo',
            'foto_path': fotoPath,
            'observacao': obs,
            'data_lancamento': data,
            'criado_em': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        imported++;
      }
    });

    return imported;
  }

  /// Importa um pacote .zip completo, extrai as fotos e processa os dados
  static Future<int> importFromZip(String zipFilePath) async {
    final zipFile = File(zipFilePath);
    if (!zipFile.existsSync()) return 0;

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final appDocDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDocDir.path, 'fotos_importadas'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    String? extractedCsvPath;

    for (final file in archive) {
      if (file.isFile) {
        if (file.name == 'balanco_dados.csv' || file.name.endsWith('.csv')) {
          final tempCsv = File(p.join(appDocDir.path, 'temp_import.csv'));
          await tempCsv.writeAsBytes(file.content as List<int>);
          extractedCsvPath = tempCsv.path;
        } else if (file.name.startsWith('fotos/')) {
          final filename = p.basename(file.name);
          final photoOut = File(p.join(photosDir.path, filename));
          await photoOut.writeAsBytes(file.content as List<int>);
        }
      }
    }

    if (extractedCsvPath != null) {
      return await importFromCsv(extractedCsvPath);
    }
    return 0;
  }
}
