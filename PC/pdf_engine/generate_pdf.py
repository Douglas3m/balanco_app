"""
Motor de Geração de PDF A4 — Sistema BALANÇO
Utiliza Jinja2 para renderização do template HTML/CSS baseado no Google Stitch
e Playwright (Edge/Chromium Headless) para conversão milimétrica em A4.
"""

import os
import sys
import json
import base64
import argparse
from pathlib import Path
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

ENGINE_DIR = Path(__file__).resolve().parent
TEMPLATES_DIR = ENGINE_DIR / "templates"

def load_image_as_base64(image_path: str) -> str | None:
    if not image_path:
        return None
    p = Path(image_path)
    if p.exists() and p.is_file():
        try:
            with open(p, "rb") as f:
                return base64.b64encode(f.read()).decode("utf-8")
        except Exception:
            return None
    return None

def render_html_report(data: dict) -> str:
    env = Environment(loader=FileSystemLoader(str(TEMPLATES_DIR)), autoescape=True)
    template = env.get_template("relatorio_a4.html")

    itens = data.get("itens", [])
    total_qtd = 0

    # Processa fotos locais para base64 integrado
    for item in itens:
        total_qtd += int(item.get("quantidade", 1))
        foto_path = item.get("foto_path", "")
        if foto_path and not item.get("foto_base64"):
            b64 = load_image_as_base64(foto_path)
            if b64:
                item["foto_base64"] = b64

    context = {
        "titulo": data.get("titulo", "RELATÓRIO DE CATALOGAÇÃO PATRIMONIAL"),
        "entidade_nome": data.get("entidade_nome", "Entidade Não Informada"),
        "cnpj": data.get("cnpj", ""),
        "data_emissao": data.get("data_emissao", datetime.now().strftime("%d/%m/%Y às %H:%M")),
        "itens": itens,
        "total_itens": len(itens),
        "total_qtd": total_qtd,
    }

    return template.render(**context)

def convert_html_to_pdf(html_content: str, output_pdf_path: str) -> bool:
    out_path = Path(output_pdf_path).resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # 1. Estratégia Principal: Playwright Headless (Chromium / Edge)
    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            # Tenta msedge primeiro (nativo no Windows) ou chromium padrão
            browser = None
            try:
                browser = p.chromium.launch(channel="msedge", headless=True)
            except Exception:
                browser = p.chromium.launch(headless=True)

            page = browser.new_page()
            page.set_content(html_content, wait_until="networkidle")
            page.pdf(
                path=str(out_path),
                format="A4",
                print_background=True,
                margin={"top": "15mm", "right": "15mm", "bottom": "15mm", "left": "15mm"},
            )
            browser.close()
            return True
    except Exception as e_playwright:
        print(f"[Aviso] Falha no Playwright: {e_playwright}. Tentando WeasyPrint...", file=sys.stderr)

    # 2. Estratégia Secundária: WeasyPrint (se bibliotecas C estiverem presentes)
    try:
        from weasyprint import HTML
        HTML(string=html_content).write_pdf(str(out_path))
        return True
    except Exception as e_weasy:
        print(f"[Aviso] Falha no WeasyPrint: {e_weasy}.", file=sys.stderr)

    return False

def generate_report_from_json(json_path: str, output_pdf_path: str) -> bool:
    with open(json_path, "r", encoding="utf-8-sig") as f:
        data = json.load(f)

    html = render_html_report(data)
    return convert_html_to_pdf(html, output_pdf_path)

def main():
    parser = argparse.ArgumentParser(description="Motor de Relatórios PDF A4 do Balanço")
    parser.add_argument("--input", "-i", required=True, help="Caminho do arquivo JSON de entrada")
    parser.add_argument("--output", "-o", required=True, help="Caminho do arquivo PDF de saída")

    args = parser.parse_args()

    success = generate_report_from_json(args.input, args.output)
    if success:
        print(f"Sucesso! Relatório gerado em: {args.output}")
        sys.exit(0)
    else:
        print("Erro: Não foi possível gerar o PDF.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
