"""
Servidor Desktop Local BALANÇO (FastAPI + SQLite + Motor Python PDF)
Serve a interface desktop completa baseada no Google Stitch e conecta com o SQLite.
"""

import os
import sys
import sqlite3
import shutil
import zipfile
import tempfile
from pathlib import Path
from datetime import datetime
from fastapi import FastAPI, UploadFile, File, Form, Request, HTTPException
from fastapi.responses import HTMLResponse, FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from PC.pdf_engine.generate_pdf import render_html_report, convert_html_to_pdf

app = FastAPI(title="Balanço Desktop", version="2.0.0")

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DB_PATH = BASE_DIR / "balanco_desktop.db"

def get_db():
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS entidades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        cnpj_codigo TEXT,
        regime TEXT,
        observacao TEXT,
        criado_em TEXT NOT NULL
    );
    """)

    cursor.execute("""
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
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        categoria TEXT,
        criado_em TEXT NOT NULL
    );
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS lancamentos (
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

    # Seed se estiver vazio
    cursor.execute("SELECT COUNT(*) FROM entidades")
    if cursor.fetchone()[0] == 0:
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute("INSERT INTO entidades (nome, cnpj_codigo, regime, observacao, criado_em) VALUES (?, ?, ?, ?, ?)",
                       ("Prefeitura Municipal - Gabinete Executivo", "14.283.910/0001-44", "Administração Direta", "Sede Central", now))
        ent1_id = cursor.lastrowid

        cursor.execute("INSERT INTO entidades (nome, cnpj_codigo, regime, observacao, criado_em) VALUES (?, ?, ?, ?, ?)",
                       ("Fundo Municipal de Saúde", "14.283.910/0002-25", "Fundo Especial", "Polo Médico", now))

        cursor.execute("INSERT INTO setores (entidade_id, nome, andar_bloco, responsavel, criado_em) VALUES (?, ?, ?, ?, ?)",
                       (ent1_id, "Depto. de TI & Servidores", "Subsolo - Sala 02", "Lucas S. Ferreira", now))
        set1_id = cursor.lastrowid

        cursor.execute("INSERT INTO setores (entidade_id, nome, andar_bloco, responsavel, criado_em) VALUES (?, ?, ?, ?, ?)",
                       (ent1_id, "Gabinete do Prefeito", "3º Andar - Sala 301", "Mariana R. Costa", now))
        set2_id = cursor.lastrowid

        cursor.execute("INSERT INTO produtos (nome, categoria, criado_em) VALUES (?, ?, ?)",
                       ("Notebook Lenovo ThinkPad L14 Gen 4", "Equipamento TI", now))
        prod1_id = cursor.lastrowid

        cursor.execute("INSERT INTO produtos (nome, categoria, criado_em) VALUES (?, ?, ?)",
                       ("Cadeira Giratória Ergonômica NR-17", "Mobiliário", now))
        prod2_id = cursor.lastrowid

        cursor.execute("INSERT INTO produtos (nome, categoria, criado_em) VALUES (?, ?, ?)",
                       ("Projetor Multimídia Laser 4K", "Audiovisual", now))
        prod3_id = cursor.lastrowid

        cursor.execute("""
        INSERT INTO lancamentos (plaqueta_codigo, produto_id, setor_id, entidade_id, quantidade, estado_conservacao, foto_path, observacao, data_lancamento, criado_em)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, ("PAT-2025-0012", prod1_id, set1_id, ent1_id, 3, "Ótimo", "", "Com carregador original 65W USB-C", "24/10/2025 14:15", now))

        cursor.execute("""
        INSERT INTO lancamentos (plaqueta_codigo, produto_id, setor_id, entidade_id, quantidade, estado_conservacao, foto_path, observacao, data_lancamento, criado_em)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, ("PAT-2025-0045", prod2_id, set2_id, ent1_id, 6, "Bom", "", "Estofamento cinza chumbo com ajuste lombar", "24/10/2025 15:30", now))

        cursor.execute("""
        INSERT INTO lancamentos (plaqueta_codigo, produto_id, setor_id, entidade_id, quantidade, estado_conservacao, foto_path, observacao, data_lancamento, criado_em)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, ("PAT-2025-0089", prod3_id, set2_id, ent1_id, 1, "Ótimo", "", "Instalado no teto com suporte articulado", "25/10/2025 09:20", now))

    conn.commit()
    conn.close()

init_db()

@app.get("/", response_class=HTMLResponse)
def index_page():
    # Lê a tela de visualização do laudo do Google Stitch
    stitch_html_path = BASE_DIR / "stitch_extracted" / "stitch_balan_o_cataloging_system" / "relat_rios_e_emiss_o_a4_desktop" / "code.html"
    if stitch_html_path.exists():
        with open(stitch_html_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Substitui a ação do botão "Exportar em PDF" para acionar a rota do Motor Python
        content = content.replace(
            '<span>Exportar em PDF</span>',
            '<span onclick="window.location.href=\'/api/gerar-pdf-download\'" style="cursor:pointer;">Exportar em PDF (Python)</span>'
        )
        return HTMLResponse(content=content)
    return HTMLResponse("<h1>Balanço Desktop</h1><p><a href='/api/gerar-pdf-download'>Baixar PDF A4</a></p>")

@app.get("/api/itens")
def get_itens():
    conn = get_db()
    rows = conn.execute("""
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
    """).fetchall()
    conn.close()
    return [dict(r) for r in rows]

@app.get("/api/gerar-pdf-download")
def gerar_pdf_download():
    itens = get_itens()
    entidade_nome = itens[0]["entidade_nome"] if itens else "Prefeitura Municipal"

    payload = {
        "titulo": "RELATÓRIO AUDITADO DE CATALOGAÇÃO E TOMBAMENTO PATRIMONIAL",
        "entidade_nome": entidade_nome,
        "cnpj": "14.283.910/0001-44",
        "data_emissao": datetime.now().strftime("%d/%m/%Y às %H:%M"),
        "itens": [
            {
                "id": i["id"],
                "plaqueta": i["plaqueta_codigo"],
                "produto": i["produto_nome"],
                "setor": i["setor_nome"],
                "entidade": i["entidade_nome"],
                "quantidade": i["quantidade"],
                "conservacao": i["estado_conservacao"],
                "observacao": i["observacao"],
                "data": i["data_lancamento"],
                "foto_path": i["foto_path"],
            }
            for i in itens
        ],
    }

    html = render_html_report(payload)
    out_pdf = BASE_DIR / "relatorio_balanco_a4.pdf"
    success = convert_html_to_pdf(html, str(out_pdf))

    if success and out_pdf.exists():
        return FileResponse(
            path=str(out_pdf),
            filename="relatorio_balanco_a4.pdf",
            media_type="application/pdf"
        )
    raise HTTPException(status_code=500, detail="Erro ao gerar PDF")
