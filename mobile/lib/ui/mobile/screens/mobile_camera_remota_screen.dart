import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/remote_camera_server.dart';

class MobileCameraRemotaScreen extends StatefulWidget {
  const MobileCameraRemotaScreen({super.key});

  @override
  State<MobileCameraRemotaScreen> createState() => _MobileCameraRemotaScreenState();
}

class _MobileCameraRemotaScreenState extends State<MobileCameraRemotaScreen> {
  final _server = RemoteCameraServer();
  String _ipAddress = 'Carregando...';
  bool _serverAtivo = false;
  final String _token = 'BALANCO-2025';

  @override
  void initState() {
    super.initState();
    _obterIp();
  }

  Future<void> _obterIp() async {
    final ip = await RemoteCameraServer.getLocalIpAddress();
    if (mounted) {
      setState(() => _ipAddress = ip ?? '127.0.0.1');
    }
  }

  Future<void> _alternarServidor() async {
    if (_serverAtivo) {
      await _server.stopServer();
      setState(() => _serverAtivo = false);
    } else {
      await _server.startServer(port: 8080, token: _token);
      setState(() => _serverAtivo = true);
    }
  }

  @override
  void dispose() {
    if (_serverAtivo) {
      _server.stopServer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Câmera Remota (Pareamento)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de Status da Conexão
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _serverAtivo
                          ? BalancoColors.success.withOpacity(0.12)
                          : BalancoColors.containerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _serverAtivo ? Icons.videocam : Icons.videocam_off_outlined,
                      size: 32,
                      color: _serverAtivo ? BalancoColors.success : BalancoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _serverAtivo ? 'Servidor de Câmera Ativo' : 'Câmera Remota Desconectada',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _serverAtivo
                        ? 'O programa desktop pode se conectar a este aparelho'
                        : 'Ative o servidor para transmitir fotos para o programa desktop',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BalancoColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _serverAtivo ? BalancoColors.danger : BalancoColors.primary,
                      ),
                      onPressed: _alternarServidor,
                      icon: Icon(_serverAtivo ? Icons.stop : Icons.play_arrow),
                      label: Text(_serverAtivo ? 'Parar Servidor Remoto' : 'Iniciar Servidor Remoto'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dados de Conexão para Informar no Desktop
          const Text('Dados para Pareamento no Desktop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Endereço IP do Celular', _ipAddress, Icons.wifi),
                  const Divider(height: 24),
                  _infoRow('Porta HTTP', '8080', Icons.settings_ethernet),
                  const Divider(height: 24),
                  _infoRow('Token de Segurança', _token, Icons.key),
                  const Divider(height: 24),
                  _infoRow('Endpoint Stream', 'http://$_ipAddress:8080/preview-frame', Icons.stream),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dica de Funcionamento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BalancoColors.containerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BalancoColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: BalancoColors.secondary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Certifique-se de que o computador e o celular estejam conectados na mesma rede Wi-Fi ou via cabo USB (adb reverse tcp:8080 tcp:8080).',
                    style: TextStyle(fontSize: 12, color: BalancoColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BalancoColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: BalancoColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          ],
        ),
      ],
    );
  }
}
