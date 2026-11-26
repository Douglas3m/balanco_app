import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Servidor HTTP embutido no Mobile para o Modo Câmera Remota
class RemoteCameraServer {
  HttpServer? _server;
  CameraController? _cameraController;
  bool _isRunning = false;
  int _port = 8080;
  String _pairingToken = '123456';

  bool get isRunning => _isRunning;
  int get port => _port;
  String get pairingToken => _pairingToken;

  void attachCameraController(CameraController controller) {
    _cameraController = controller;
  }

  Future<void> startServer({int port = 8080, String? token}) async {
    if (_isRunning) return;
    _port = port;
    if (token != null) _pairingToken = token;

    final router = Router();

    // 1. Endpoint de status e handshake
    router.get('/status', (Request request) {
      return Response.ok(
        jsonEncode({
          'status': 'online',
          'service': 'balanco_remote_camera',
          'camera_ready': _cameraController?.value.isInitialized ?? false,
          'token_required': true,
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    // 2. Endpoint de captura remota (POST /capture)
    router.post('/capture', (Request request) async {
      final authHeader = request.headers['x-pairing-token'];
      if (authHeader != _pairingToken) {
        return Response.forbidden(jsonEncode({'error': 'Token de pareamento incorreto'}));
      }

      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Câmera não inicializada no aparelho'}),
        );
      }

      try {
        final XFile photo = await _cameraController!.takePicture();
        final docDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final savedPath = p.join(docDir.path, 'foto_remota_$timestamp.jpg');
        await photo.saveTo(savedPath);

        final bytes = await File(savedPath).readAsBytes();
        final base64Image = base64Encode(bytes);

        return Response.ok(
          jsonEncode({
            'success': true,
            'file_name': p.basename(savedPath),
            'local_path': savedPath,
            'base64': base64Image,
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Falha na captura: $e'}),
        );
      }
    });

    // 3. Endpoint de snapshot simples para preview (GET /preview-frame)
    router.get('/preview-frame', (Request request) async {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return Response.internalServerError(body: 'Câmera indisponível');
      }

      try {
        final XFile snap = await _cameraController!.takePicture();
        final bytes = await snap.readAsBytes();
        return Response.ok(bytes, headers: {'content-type': 'image/jpeg'});
      } catch (e) {
        return Response.internalServerError(body: 'Erro no frame: $e');
      }
    });

    final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);
    _server = await io.serve(handler, InternetAddress.anyIPv4, _port);
    _isRunning = true;
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
  }

  /// Recupera o IP local do dispositivo Wi-Fi
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.') || addr.address.startsWith('10.') || addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }
}
