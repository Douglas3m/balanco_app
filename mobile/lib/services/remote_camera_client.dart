import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cliente Desktop para conexão com a Câmera Remota do Celular
class RemoteCameraClient {
  final String host;
  final int port;
  final String pairingToken;

  RemoteCameraClient({
    required this.host,
    this.port = 8080,
    required this.pairingToken,
  });

  String get baseUrl => 'http://$host:$port';

  Future<bool> checkConnection() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/status')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['service'] == 'balanco_remote_camera';
      }
    } catch (_) {}
    return false;
  }

  Future<Uint8List?> fetchPreviewFrame() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/preview-frame')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  Future<File?> triggerRemoteCapture() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/capture'),
        headers: {
          'x-pairing-token': pairingToken,
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final base64Img = data['base64'] as String?;
        if (base64Img != null) {
          final bytes = base64Decode(base64Img);
          final docDir = await getApplicationDocumentsDirectory();
          final target = File(p.join(docDir.path, 'remota_${DateTime.now().millisecondsSinceEpoch}.jpg'));
          return await target.writeAsBytes(bytes);
        }
      }
    } catch (_) {}
    return null;
  }
}
