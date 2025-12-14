import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/qr_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../models/project_model.dart';
import '../../employee/screens/project_tasks_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Entrée/Sortie'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onQRCodeDetected),
          _buildScannerOverlay(context),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: ShapeDecoration(
            shape: _ScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 10, borderWidth: 10, borderLength: 30, cutOutSize: 300
            ),
          ),
        ),
        const Align(
          alignment: Alignment(0, -0.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 180),
              Text('Scannez le code du chantier', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
              SizedBox(height: 8),
              Text('Pour pointer votre ENTRÉE ou votre SORTIE', style: TextStyle(color: Colors.white70, fontSize: 14, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
            ],
          ),
        ),
        Positioned(
          bottom: 50, left: 20, right: 20,
          child: Center(
            child: TextButton.icon(
              onPressed: () => _showManualEntryDialog(context),
              icon: const Icon(Icons.keyboard, color: Colors.white),
              label: const Text("Saisir code manuel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline)),
              style: TextButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ),
        ),
      ],
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
            SizedBox(height: 20),
            Text('Traitement du pointage...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    cameraController.stop();
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Saisie manuelle"),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(labelText: "Code Chantier (ex: CHANTIER-PARIS)", border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); cameraController.start(); }, child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (codeController.text.isNotEmpty) _processQRCode(codeController.text.trim());
              else cameraController.start();
            },
            child: const Text("Valider"),
          )
        ],
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_isScanning || _isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    _processQRCode(barcodes.first.rawValue ?? '');
  }

  // 🔥 LOGIQUE MISE À JOUR : STRICTE SUR LES MULTI-CHANTIERS 🔥
  Future<void> _processQRCode(String qrData) async {
    if (qrData.isEmpty) return;
    setState(() { _isScanning = true; _isProcessing = true; });

    try {
      final qrService = Provider.of<QrService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);

      final currentUser = authService.currentUser;
      final employeeData = await authService.getEmployeeData(currentUser!.uid);

      // Cas 1 : Je suis déjà pointé quelque part
      if (employeeData?.currentProjectId != null) {

        // Sous-cas A : Je scanne le MÊME chantier -> JE SORS
        if (employeeData!.currentProjectId == qrData) {
          await attendanceService.checkOutFromProject(currentUser.uid);
          if (mounted) _showExitDialog(employeeData.currentProjectName ?? "Chantier");
        }
        // Sous-cas B : Je scanne un AUTRE chantier -> ERREUR BLOQUANTE
        else {
          if (mounted) {
            _showBlockingDialog(
                currentProjectName: employeeData.currentProjectName ?? "Inconnu",
                scannedCode: qrData
            );
          }
        }

      } else {
        // Cas 2 : Je suis libre -> J'ENTRE
        final project = await qrService.verifyAndCheckIn(
          qrData: qrData,
          employeeId: currentUser.uid,
        );
        if (mounted) _showEntryDialog(project);
      }

    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showBlockingDialog({required String currentProjectName, required String scannedCode}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.lock, color: Colors.red), SizedBox(width: 10), Text('Action Impossible')]),
        content: Text("Vous êtes actuellement pointé sur :\n👉 $currentProjectName\n\nVous devez scanner ce chantier pour en SORTIR avant de pouvoir entrer ailleurs."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = false);
              cameraController.start();
            },
            child: const Text('COMPRIS'),
          ),
        ],
      ),
    );
  }

  void _showEntryDialog(Project project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.login, color: Colors.green), SizedBox(width: 10), Text('Entrée Validée')]),
        content: Text("Bienvenue sur : ${project.name}\nVotre compteur d'heures démarre."),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProjectTasksScreen(project: project)));
            },
            child: const Text('ACCÉDER AUX TÂCHES'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(String projectName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.logout, color: Colors.orange), SizedBox(width: 10), Text('Sortie Validée')]),
        content: Text("Vous avez quitté : $projectName\nFin de session enregistrée."),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('RETOUR ACCUEIL'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: Text(error.replaceAll('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isScanning = false);
              cameraController.start();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.borderLength = 20.0,
    this.borderRadius = 10.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _cutOutSize = cutOutSize;
    final _cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          _cutOutRect,
          Radius.circular(borderRadius),
        ),
      );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawPath(
        cutOutPath,
        boxPaint,
      )
      ..restore();

    canvas.drawPath(
      _createCornersPath(_cutOutRect, borderLength, borderRadius),
      borderPaint,
    );
  }

  Path _createCornersPath(Rect rect, double length, double radius) {
    final path = Path();
    path.moveTo(rect.left, rect.top + length);
    path.lineTo(rect.left, rect.top + radius);
    path.arcToPoint(Offset(rect.left + radius, rect.top), radius: Radius.circular(radius));
    path.lineTo(rect.left + length, rect.top);
    path.moveTo(rect.right - length, rect.top);
    path.lineTo(rect.right - radius, rect.top);
    path.arcToPoint(Offset(rect.right, rect.top + radius), radius: Radius.circular(radius));
    path.lineTo(rect.right, rect.top + length);
    path.moveTo(rect.right, rect.bottom - length);
    path.lineTo(rect.right, rect.bottom - radius);
    path.arcToPoint(Offset(rect.right - radius, rect.bottom), radius: Radius.circular(radius));
    path.lineTo(rect.right - length, rect.bottom);
    path.moveTo(rect.left + length, rect.bottom);
    path.lineTo(rect.left + radius, rect.bottom);
    path.arcToPoint(Offset(rect.left, rect.bottom - radius), radius: Radius.circular(radius));
    path.lineTo(rect.left, rect.bottom - length);
    return path;
  }

  @override
  ShapeBorder scale(double t) => _ScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth * t,
    borderLength: borderLength * t,
    borderRadius: borderRadius * t,
    cutOutSize: cutOutSize * t,
  );
}