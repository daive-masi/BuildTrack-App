// features/qr_scanner/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/qr_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/project_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = false;
  bool _hasPermission = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code Chantier'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _buildScannerContent(),
    );
  }

  Widget _buildScannerContent() {
    if (!_hasPermission) {
      return _buildPermissionDenied();
    }
    return Stack(
      children: [
        MobileScanner(
          controller: cameraController,
          onDetect: _onQRCodeDetected,
        ),
        _buildScannerOverlay(),
        if (_isScanning) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: _ScannerOverlayShape(),
      ),
      child: Column(
        children: [
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Scannez le QR code du chantier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Placez le QR code dans le cadre',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Traitement du QR code...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Accès caméra refusé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'application a besoin d\'accéder à la caméra pour scanner les QR codes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('Autoriser la caméra'),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_isScanning) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final qrData = barcodes.first.rawValue;
    if (qrData == null) return;
    _processQRCode(qrData);
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() => _isScanning = true);
    try {
      final qrService = Provider.of<QrService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      final project = await qrService.scanQrCode(qrData);
      if (project == null) {
        throw Exception('QR code invalide ou chantier non trouvé');
      }
      await qrService.checkInToProject(
        projectId: project.id,
        projectName: project.name,
        employeeId: currentUser.uid,
        location: project.location,
      );
      _showSuccessDialog(project);
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _showSuccessDialog(Project project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Pointage Réussi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chantier: ${project.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Adresse: ${project.address}'),
            const SizedBox(height: 16),
            const Text(
              'Vous êtes maintenant pointé sur ce chantier.',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour au dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    // Exemple basique avec le package `permission_handler`
    // À adapter selon ton package de gestion des permissions
    // final status = await Permission.camera.request();
    // setState(() => _hasPermission = status.isGranted);
    setState(() => _hasPermission = true); // Simule l'octroi de la permission
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final backgroundPaint = Paint()..color = Colors.black54;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final width = rect.width;
    final height = rect.height;
    const cutoutSize = 250.0;
    final cutoutRect = Rect.fromCenter(
      center: rect.center,
      width: cutoutSize,
      height: cutoutSize,
    );
    canvas.drawRect(rect, backgroundPaint);
    final path = Path()
      ..addRect(rect)
      ..addRect(cutoutRect);
    canvas.drawPath(path, Paint()..blendMode = BlendMode.clear);
    canvas.drawRect(cutoutRect, borderPaint);

    const cornerSize = 20.0;
    const cornerWidth = 3.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth;

    // Coin supérieur gauche
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.top + cornerSize)
        ..lineTo(cutoutRect.left, cutoutRect.top)
        ..lineTo(cutoutRect.left + cornerSize, cutoutRect.top),
      cornerPaint,
    );

    // Coin supérieur droit
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - cornerSize, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top + cornerSize),
      cornerPaint,
    );

    // Coin inférieur gauche
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.bottom - cornerSize)
        ..lineTo(cutoutRect.left, cutoutRect.bottom)
        ..lineTo(cutoutRect.left + cornerSize, cutoutRect.bottom),
      cornerPaint,
    );

    // Coin inférieur droit
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - cornerSize, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom - cornerSize),
      cornerPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
