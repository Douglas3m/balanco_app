"""
Launcher do Programa Desktop BALANÇO
Inicia o servidor desktop integrado e abre a janela nativa no Windows (Edge WebView2)
"""

import sys
import threading
import time
import uvicorn
import webview

def start_server():
    from PC.app.desktop_server import app
    uvicorn.run(app, host="127.0.0.1", port=8050, log_level="warning")

def main():
    print("Iniciando Sistema BALANÇO — Versão 2.0 Desktop...")
    server_thread = threading.Thread(target=start_server, daemon=True)
    server_thread.start()
    time.sleep(1.2)

    # Abre a janela do aplicativo desktop nativo
    print("Abrindo interface moderna baseada no Google Stitch em http://127.0.0.1:8050 ...")
    try:
        webview.create_window(
            title="BALANÇO — Patrimônio & Auditoria A4",
            url="http://127.0.0.1:8050",
            width=1280,
            height=850,
            resizable=True,
        )
        webview.start()
    except Exception as e:
        print(f"Janela WebView não suportada nesta sessão: {e}. Acesse no navegador: http://127.0.0.1:8050")

if __name__ == "__main__":
    main()
