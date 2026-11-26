# SISTEMA BALANÇO (VERSÃO 2.0)
## Catalogação Patrimonial, Contagem e Emissão Pericial A4 com Câmera Remota

O **BALANÇO** é um sistema completo e multiplataforma desenvolvido para gestão, inventário e auditoria patrimonial em campo (Mobile Android/iOS) e escritório (Desktop Windows/macOS/Linux).

---

## 1. Arquitetura da Solução

```text
D:\app_balanco\
├── DESIGN.md                     # Especificações e Design Tokens oficiais do Google Stitch
├── README.md                     # Documentação de execução e integração
├── balanco_desktop.db            # Banco SQLite local populado e auditado
├── relatorio_balanco_a4.pdf      # Laudo pericial A4 oficial gerado pelo motor Python
│
├── balanco/                      # Monorepo Flutter Adaptativo (Mobile + Desktop)
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── core/ (app_colors.dart, app_theme.dart)
│       ├── database/ (balanco_database.dart com SQLite ACID)
│       ├── models/ (entidade, setor, produto, lancamento_item)
│       ├── repositories/ (CRUD com persistência relacional)
│       ├── services/
│       │   ├── sync_service.dart (Exportação .csv, .db e .zip completo com fotos)
│       │   ├── remote_camera_server.dart (Servidor HTTP Mobile da Câmera Remota)
│       │   ├── remote_camera_client.dart (Cliente Desktop de conexão à câmera)
│       │   ├── python_pdf_bridge.dart (Ponte Flutter Desktop -> Motor Python)
│       │   └── pdf_report_service.dart (Preview e renderizador PDF)
│       └── ui/
│           ├── adaptive_shell.dart (Detecção automática Mobile vs Desktop)
│           ├── mobile/ (Dashboard, Novo Lançamento, Lista, Cadastros, Câmera, Exportar)
│           └── desktop/ (Sidebar, Header, Catalogação, Importar, Exportar, Relatório A4)
│
├── mobile/                       # Projeto Mobile Flutter dedicado
│
└── PC/                           # Solução Desktop e Motor de Laudos
    ├── pdf_engine/               # Motor Pericial de Geração de PDF (Python + HTML)
    │   ├── templates/relatorio_a4.html  # Template Stitch A4 (210x297mm, 15mm margens)
    │   ├── generate_pdf.py              # CLI para geração do laudo A4 via Playwright
    │   ├── server.py                    # Microserviço HTTP FastAPI para prévias e download
    │   └── requirements.txt
    └── app/                      # Launcher Desktop Integrado
        ├── desktop_server.py            # Servidor da interface Desktop com SQLite
        └── run_desktop.py               # Launcher Desktop com WebView nativo no Windows
```

---

## 2. Como Executar

### 2.1. Motor de Geração de PDF (Python + HTML / Google Stitch)

O motor utiliza **Jinja2** e **Playwright Headless (Chromium/Edge)** para diagramar relatórios milimétricos A4 em alta fidelidade com fotografias 1:1, linhas zebradas e cabeçalho pericial.

1. **Instalação das dependências Python:**
   ```bash
   pip install -r PC/pdf_engine/requirements.txt
   ```

2. **Geração direta de relatório via Linha de Comando (CLI):**
   ```bash
   python -m PC.pdf_engine.generate_pdf --input dados.json --output relatorio_a4.pdf
   ```

3. **Execução do Microserviço HTTP de PDF (FastAPI):**
   ```bash
   python PC/pdf_engine/server.py
   # Acesso à documentação interativa: http://127.0.0.1:8000/docs
   ```

---

### 2.2. Executar o Programa Desktop no Windows

O sistema conta com um launcher nativo que conecta o SQLite local, a interface do Google Stitch e o motor de PDF:

```bash
python PC/app/run_desktop.py
```
> Isso abrirá a janela desktop em tela cheia com a base de catalogação, importador de `.zip` e gerador de relatórios A4 em `http://127.0.0.1:8050`.

---

### 2.3. Executar o Aplicativo Mobile (Flutter)

No diretório `mobile/` ou `balanco/`:
```bash
cd mobile
flutter pub get
flutter run -d android
# ou
flutter run -d ios
```

---

## 3. Modo Câmera Remota (Pareamento Celular <-> PC)

1. **No Celular:**
   - Acesse a aba **Câmera**.
   - Toque em **Iniciar Servidor Remoto**.
   - O aplicativo exibirá o IP do celular (ex: `192.168.1.100`), a porta `8080` e o token de segurança (`BALANCO-2025`).
2. **No Desktop:**
   - Acesse a tela **Câmera Remota**.
   - Digite o IP do celular e clique em **Conectar à Câmera**.
   - O preview da câmera do celular é exibido em tempo real e o botão **Disparar Captura Remota** grava a fotografia e a transfere automaticamente para o computador.

---

## 4. Banco de Dados SQLite Local (Offline-First)

- **`entidades`**: Registro institucional (órgãos, prefeituras, hospitais, CNPJ, regime).
- **`setores`**: Salas, andares e blocos com chave estrangeira vinculada à entidade (`ON DELETE CASCADE`).
- **`produtos`**: Catálogo padronizado de bens e equipamentos (auto-criação caso novo).
- **`lancamentos`**: Tombamentos auditados, plaqueta única (`#PAT`), quantidade com `CHECK(quantidade > 0)`, estado de conservação, fotografia e timestamps.

---

## 5. Design System: Google Stitch

Todas as telas e laudos seguem a paleta oficial:
- **Deep Navy (`#1E3A8A`)**: Identidade institucional, headers e CTAs.
- **Cobalt Blue (`#3B82F6`)**: Foco, badges ativos e seleções.
- **Emerald Green (`#10B981`)**: Validação de auditoria e status OK.
- **Slate Canvas (`#F8FAFC`)**: Fundo ergonômico anti-fadiga.
- **Tipografia**: `Outfit` para títulos e métricas / `Inter` para tabelas e formulários.
