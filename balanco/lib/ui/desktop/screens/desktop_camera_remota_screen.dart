import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/remote_camera_client.dart';

class DesktopCameraRemotaScreen extends StatefulWidget {
  const DesktopCameraRemotaScreen({super.key});

  @override
  State<DesktopCameraRemotaScreen> createState() => _DesktopCameraRemotaScreenState();
}

class _DesktopCameraRemotaScreenState extends State<DesktopCameraRemotaScreen> {
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '8080');
  final _tokenController = TextEditingController(text: 'BALANCO-2025');

  RemoteCameraClient? _client;
  bool _conectado = false;
  bool _capturando = false;
  Uint8List? _previewBytes;
  Timer? _streamTimer;
  String? _statusMsg;

  Future<void> _conectar() async {
    final host = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    final token = _tokenController.text.trim();

    final client = RemoteCameraClient(host: host, port: port, pairingToken: token);
    setState(() => _statusMsg = 'Conectando ao celular em $host:$port...');

    final ok = await client.checkConnection();
    if (ok) {
      setState(() {
        _client = client;
        _conectado = true;
        _statusMsg = 'Câmera remota conectada com sucesso!';
      });
      _iniciarStream();
    } else {
      setState(() {
        _conectado = false;
        _statusMsg = 'Não foi possível conectar. Verifique se o app está aberto no celular e se o IP está correto.';
      });
    }
  }

  void _iniciarStream() {
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (_client != null && _conectado) {
        final frame = await _client!.fetchPreviewFrame();
        if (mounted && frame != null) {
          setState(() => _previewBytes = frame);
        }
      }
    });
  }

  Future<void> _dispararCaptura() async {
    if (_client == null || !_conectado) return;
    setState(() => _capturando = true);

    try {
      final file = await _client!.triggerRemoteCapture();
      if (mounted) {
        setState(() {
          _capturando = false;
          _statusMsg = file != null
              ? 'Foto capturada remotamente com sucesso!\nSalva em: ${file.path}'
              : 'Falha ao capturar foto remota.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _capturando = false;
          _statusMsg = 'Erro na captura remota: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BalancoColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acesso à Câmera Remota do Celular (Wi-Fi / USB)', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: BalancoColors.primary)),
            const Text('Utilize a câmera do celular pareado para visualizar o preview e capturar fotos de ativos diretamente pelo computador.', style: TextStyle(color: BalancoColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Painel de Configuração
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BalancoColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Configurações de Pareamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 14),
                      TextField(controller: _ipController, decoration: const InputDecoration(labelText: 'IP do Celular', hintText: 'Ex: 192.168.1.100')),
                      const SizedBox(height: 10),
                      TextField(controller: _portController, decoration: const InputDecoration(labelText: 'Porta HTTP', hintText: '8080')),
                      const SizedBox(height: 10),
                      TextField(controller: _tokenController, decoration: const InputDecoration(labelText: 'Token de Segurança')),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _conectado ? BalancoColors.danger : BalancoColors.primary,
                          ),
                          onPressed: _conectado
                              ? () {
                                  _streamTimer?.cancel();
                                  setState(() => _conectado = false);
                                }
                              : _conectar,
                          icon: Icon(_conectado ? Icons.link_off : Icons.link),
                          label: Text(_conectado ? 'Desconectar' : 'Conectar à Câmera'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Janela de Preview da Câmera
                Expanded(
                  child: Container(
                    height: 420,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BalancoColors.border, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_previewBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(_previewBytes!, fit: BoxFit.contain),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_outlined, size: 64, color: Colors.white.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text(
                                _conectado ? 'Aguardando frame de vídeo...' : 'Câmera não conectada',
                                style: const TextStyle(color: Colors.white70, fontSize: 15),
                              ),
                            ],
                          ),
                        if (_conectado)
                          Positioned(
                            bottom: 20,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BalancoColors.secondary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              onPressed: _capturando ? null : _dispararCaptura,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(_capturando ? 'Capturando...' : 'Disparar Captura Remota'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_statusMsg != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BalancoColors.containerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusMsg!, style: const TextStyle(fontWeight: FontWeight.bold, color: BalancoColors.primary)),
              ),
          ],
        ),
      ),
    );
  }
}
