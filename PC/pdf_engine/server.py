"""
Servidor HTTP Local (FastAPI) para Geração e Pré-Visualização de Relatórios PDF A4
Permite ao programa Desktop Balanço solicitar PDFs via requisições HTTP locais.
"""

from fastapi import FastAPI, HTTPException, Body
from fastapi.responses import Response, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
import tempfile
from pathlib import Path
from PC.pdf_engine.generate_pdf import render_html_report, convert_html_to_pdf

app = FastAPI(title="Balanço PDF Engine API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {
        "status": "online",
        "service": "balanco_pdf_engine",
        "version": "2.0.0",
        "format": "A4",
    }

@app.post("/preview-html", response_class=HTMLResponse)
def preview_html(payload: dict = Body(...)):
    try:
        html = render_html_report(payload)
        return HTMLResponse(content=html)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao renderizar HTML: {str(e)}")

@app.post("/generate-pdf")
def generate_pdf(payload: dict = Body(...)):
    try:
        html = render_html_report(payload)
        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
            tmp_path = tmp.name

        success = convert_html_to_pdf(html, tmp_path)
        if not success:
            raise HTTPException(status_code=500, detail="Falha na conversão para PDF.")

        with open(tmp_path, "rb") as f:
            pdf_bytes = f.read()

        Path(tmp_path).unlink(missing_ok=True)

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={"Content-Disposition": "inline; filename=relatorio_balanco_a4.pdf"},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar PDF: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("PC.pdf_engine.server:app", host="127.0.0.1", port=8000, reload=False)
