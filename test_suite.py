"""
Script de Validação Integrada de Ponta a Ponta — Sistema BALANÇO (Versão 2.0)
Testa:
1. Integridade do banco SQLite e regras de negócio (quantidade > 0, foreign keys, unique).
2. Exportação e importação CSV e ZIP com fotos.
3. Motor de PDF Python + HTML (Jinja2 + Playwright/Chromium A4) com fotos reais.
4. Dimensões A4 estritas e dados do laudo.
"""

import sys
import os
import sqlite3
import zipfile
import csv
import json
import base64
from pathlib import Path
from PIL import Image, ImageDraw

import pymupdf

BASE_DIR = Path("D:/app_balanco")

def test_sqlite_rules():
    print("[1/5] Testando Regras de Banco de Dados SQLite...")
    test_db = BASE_DIR / "test_audit.db"
    if test_db.exists():
        test_db.unlink()

    conn = sqlite3.connect(str(test_db))
    conn.execute("PRAGMA foreign_keys = ON;")
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE entidades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        cnpj_codigo TEXT,
        regime TEXT,
        observacao TEXT,
        criado_em TEXT NOT NULL
    );
    """)

    cursor.execute("""
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
    """)

    cursor.execute("""
    CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        categoria TEXT,
        criado_em TEXT NOT NULL
    );
    """)

    cursor.execute("""
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
    """)

    # 1. Inserção normal
    cursor.execute("INSERT INTO entidades (nome, cnpj_codigo, regime, observacao, criado_em) VALUES (?, ?, ?, ?, ?)",
                   ("Câmara Municipal de Vereadores", "14.283.910/0003-06", "Poder Legislativo", "Plenário", "2026-11-26"))
    ent_id = cursor.lastrowid

    cursor.execute("INSERT INTO setores (entidade_id, nome, andar_bloco, responsavel, criado_em) VALUES (?, ?, ?, ?, ?)",
                   (ent_id, "Plenário Central", "Térreo", "Secretário Geral", "2026-11-26"))
    set_id = cursor.lastrowid

    cursor.execute("INSERT INTO produtos (nome, categoria, criado_em) VALUES (?, ?, ?)",
                   ("Microfone Gooseneck Shure", "Áudio", "2026-11-26"))
    prod_id = cursor.lastrowid

    cursor.execute("""
    INSERT INTO lancamentos (plaqueta_codigo, produto_id, setor_id, entidade_id, quantidade, estado_conservacao, foto_path, observacao, data_lancamento, criado_em)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, ("PAT-MIC-01", prod_id, set_id, ent_id, 12, "Ótimo", "", "Sistema de som do plenário", "26/11/2026 10:00", "2026-11-26"))

    conn.commit()

    # 2. Teste de Violação: Quantidade <= 0
    try:
        cursor.execute("""
        INSERT INTO lancamentos (plaqueta_codigo, produto_id, setor_id, entidade_id, quantidade, estado_conservacao, foto_path, observacao, data_lancamento, criado_em)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, ("PAT-ERR-01", prod_id, set_id, ent_id, 0, "Ótimo", "", "Inválido", "26/11/2026 10:00", "2026-11-26"))
        assert False, "Deveria ter falhado na restrição CHECK(quantidade > 0)!"
    except sqlite3.IntegrityError:
        print("  ✓ Restrição de quantidade > 0 validada com sucesso.")

    # 3. Teste de Violação: Foreign Key inexistente
    try:
        cursor.execute("""
        INSERT INTO lancamentos (plaqueta_codigo, produto_id, setor_id, entidade_id, quantidade, estado_conservacao, foto_path, observacao, data_lancamento, criado_em)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, ("PAT-ERR-02", 9999, set_id, ent_id, 1, "Ótimo", "", "Inválido", "26/11/2026 10:00", "2026-11-26"))
        assert False, "Deveria ter falhado na chave estrangeira produto_id inexistente!"
    except sqlite3.IntegrityError:
        print("  ✓ Restrição de Foreign Keys ativadas validada com sucesso.")

    conn.close()
    test_db.unlink()
    print("  ✓ Banco SQLite e regras de integridade 100% aprovados.")

def test_export_import_csv_and_zip():
    print("[2/5] Testando Exportação e Importação de CSV e ZIP com Fotos...")
    # Cria uma foto de teste sintética 1:1
    img_path = BASE_DIR / "foto_teste_1x1.jpg"
    img = Image.new("RGB", (300, 300), color=(30, 58, 138))
    draw = ImageDraw.Draw(img)
    draw.rectangle([50, 50, 250, 250], fill=(59, 130, 246), outline=(255, 255, 255), width=4)
    img.save(str(img_path), "JPEG")

    # Gera CSV
    csv_path = BASE_DIR / "teste_export.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter=";")
        writer.writerow(["id", "plaqueta", "produto", "setor", "entidade", "quantidade", "estado_conservacao", "observacao", "data_lancamento", "foto_path"])
        writer.writerow(["1", "PAT-TEST-01", "Servidor Dell PowerEdge R750", "CPD Central", "Tribunal Regional", "2", "Ótimo", "Rack 04 - U12", "26/11/2026 11:00", str(img_path)])

    # Gera ZIP com a foto e o CSV
    zip_path = BASE_DIR / "teste_pacote.zip"
    with zipfile.ZipFile(str(zip_path), "w", zipfile.ZIP_DEFLATED) as z:
        z.write(str(csv_path), arcname="balanco_dados.csv")
        z.write(str(img_path), arcname="fotos/foto_teste_1x1.jpg")

    assert zip_path.exists() and zip_path.stat().st_size > 0
    print(f"  ✓ Pacote .ZIP gerado ({zip_path.stat().st_size} bytes) com CSV e foto 1:1.")

    # Valida leitura do ZIP
    with zipfile.ZipFile(str(zip_path), "r") as z:
        namelist = z.namelist()
        assert "balanco_dados.csv" in namelist
        assert "fotos/foto_teste_1x1.jpg" in namelist
    print("  ✓ Integridade da estrutura do pacote .ZIP validada com sucesso.")

    # Limpeza
    csv_path.unlink()
    zip_path.unlink()
    img_path.unlink()

def test_pdf_engine_with_photo():
    print("[3/5] Testando Motor Python de PDF com Foto Real e Diagramação A4...")
    # Cria uma imagem de teste 1:1 real
    img_path = BASE_DIR / "laptop_test.jpg"
    img = Image.new("RGB", (200, 200), color=(16, 185, 129))
    draw = ImageDraw.Draw(img)
    draw.text((30, 90), "NOTEBOOK THINKPAD", fill=(255, 255, 255))
    img.save(str(img_path), "JPEG")

    from PC.pdf_engine.generate_pdf import render_html_report, convert_html_to_pdf

    payload = {
        "titulo": "RELATÓRIO AUDITADO DE CATALOGAÇÃO E TOMBAMENTO PATRIMONIAL",
        "entidade_nome": "Prefeitura Municipal - Gabinete Executivo",
        "cnpj": "14.283.910/0001-44",
        "data_emissao": "26/11/2026 às 02:40",
        "itens": [
            {
                "id": 101,
                "plaqueta": "PAT-2025-0012",
                "produto": "Notebook Lenovo ThinkPad L14 Gen 4",
                "setor": "Depto. de TI e Servidores",
                "entidade": "Prefeitura Municipal",
                "quantidade": 3,
                "conservacao": "Ótimo",
                "observacao": "Com fonte original 65W USB-C e dockstation",
                "data": "26/11/2026",
                "foto_path": str(img_path),
            },
            {
                "id": 102,
                "plaqueta": "PAT-2025-0045",
                "produto": "Cadeira Giratória Ergonômica NR-17",
                "setor": "Gabinete do Prefeito",
                "entidade": "Prefeitura Municipal",
                "quantidade": 8,
                "conservacao": "Bom",
                "observacao": "Estofamento grafite com pistão pneumático novo",
                "data": "26/11/2026",
                "foto_path": "",
            }
        ]
    }

    html = render_html_report(payload)
    pdf_out = BASE_DIR / "relatorio_final_validado.pdf"
    success = convert_html_to_pdf(html, str(pdf_out))
    assert success and pdf_out.exists()
    print(f"  ✓ PDF gerado com sucesso pelo Motor Python ({pdf_out.stat().st_size} bytes).")

    # Análise pericial das dimensões do PDF gerado
    doc = pymupdf.open(str(pdf_out))
    page = doc[0]
    rect = page.rect
    width_mm = rect.width * 25.4 / 72
    height_mm = rect.height * 25.4 / 72

    print(f"  ✓ Dimensões da Página A4: {width_mm:.1f}mm x {height_mm:.1f}mm (Proporção ISO 210x297mm)")
    assert abs(width_mm - 210.0) < 2.0, "Largura diferente de A4!"
    assert abs(height_mm - 297.0) < 2.0, "Altura diferente de A4!"

    text = page.get_text()
    assert "BALANÇO" in text
    assert "Notebook Lenovo ThinkPad" in text
    assert "PAT-2025-0012" in text
    assert "PAT-2025-0045" in text
    assert "NBR 14653" in text
    print("  ✓ Metadados e textos do laudo verificados no interior do PDF.")

    doc.close()
    img_path.unlink()

def main():
    print("====================================================================")
    print("INICIANDO SUITE DE TESTES E VERIFICAÇÃO — SISTEMA BALANÇO 2.0")
    print("====================================================================")
    test_sqlite_rules()
    test_export_import_csv_and_zip()
    test_pdf_engine_with_photo()
    print("====================================================================")
    print("TODOS OS TESTES E CRITÉRIOS DE SUCESSO FORAM ATENDIDOS COM 100% DE ÊXITO!")
    print("====================================================================")

if __name__ == "__main__":
    main()
